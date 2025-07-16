;; MediCore - Decentralized Medical Records Management
;; A secure system for patients to control access to their medical data

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-unauthorized (err u100))
(define-constant err-not-found (err u101))
(define-constant err-invalid-input (err u102))
(define-constant err-access-denied (err u103))
(define-constant err-record-exists (err u104))
(define-constant err-invalid-expiry (err u105))
(define-constant err-emergency-cooldown (err u106))
(define-constant err-invalid-emergency-type (err u107))
(define-constant err-multisig-exists (err u108))
(define-constant err-insufficient-signatures (err u109))
(define-constant err-already-signed (err u110))
(define-constant err-multisig-expired (err u111))
(define-constant emergency-cooldown-period u144) ;; 24 hours in blocks (assuming 10 min blocks)
(define-constant min-multisig-signatures u2)
(define-constant max-multisig-signatures u5)

;; Data Variables
(define-data-var next-record-id uint u1)
(define-data-var total-records uint u0)
(define-data-var total-access-grants uint u0)
(define-data-var total-emergency-accesses uint u0)
(define-data-var next-multisig-id uint u1)
(define-data-var total-multisig-requests uint u0)

;; Data Maps
(define-map medical-records 
  uint 
  {
    patient: principal,
    record-hash: (string-ascii 64),
    record-type: (string-ascii 50),
    created-at: uint,
    updated-at: uint,
    is-active: bool
  }
)

(define-map patient-records 
  principal 
  (list 100 uint)
)

(define-map access-permissions 
  {record-id: uint, provider: principal}
  {
    granted-by: principal,
    granted-at: uint,
    expires-at: uint,
    access-level: (string-ascii 20),
    is-active: bool
  }
)

(define-map healthcare-providers 
  principal 
  {
    name: (string-ascii 100),
    license-number: (string-ascii 50),
    specialty: (string-ascii 50),
    verified: bool,
    registered-at: uint,
    emergency-authorized: bool,
    last-emergency-access: uint
  }
)

(define-map emergency-access-log 
  uint 
  {
    record-id: uint,
    provider: principal,
    emergency-type: (string-ascii 30),
    justification: (string-ascii 200),
    accessed-at: uint,
    patient: principal,
    auto-expires-at: uint
  }
)

(define-map multisig-access-requests 
  uint 
  {
    record-id: uint,
    initiator: principal,
    required-signatures: uint,
    current-signatures: uint,
    expires-at: uint,
    case-description: (string-ascii 200),
    access-level: (string-ascii 20),
    is-active: bool,
    is-approved: bool,
    created-at: uint
  }
)

(define-map multisig-signatures 
  {request-id: uint, provider: principal}
  {
    signed-at: uint,
    provider-specialty: (string-ascii 50),
    signature-justification: (string-ascii 150)
  }
)

(define-map multisig-providers 
  uint 
  (list 5 principal)
)

;; Private Functions
(define-private (is-valid-record-type (record-type (string-ascii 50)))
  (or 
    (is-eq record-type "diagnosis")
    (is-eq record-type "prescription")
    (is-eq record-type "lab-result")
    (is-eq record-type "imaging")
    (is-eq record-type "treatment")
    (is-eq record-type "consultation")
  )
)

(define-private (is-valid-access-level (access-level (string-ascii 20)))
  (or 
    (is-eq access-level "read")
    (is-eq access-level "write")
    (is-eq access-level "full")
  )
)

(define-private (is-valid-emergency-type (emergency-type (string-ascii 30)))
  (or 
    (is-eq emergency-type "cardiac-arrest")
    (is-eq emergency-type "trauma")
    (is-eq emergency-type "stroke")
    (is-eq emergency-type "overdose")
    (is-eq emergency-type "allergic-reaction")
    (is-eq emergency-type "unconscious")
    (is-eq emergency-type "other-critical")
  )
)

(define-private (check-emergency-cooldown (provider principal))
  (let ((provider-info (unwrap-panic (map-get? healthcare-providers provider))))
    (> (+ (get last-emergency-access provider-info) emergency-cooldown-period) stacks-block-height)
  )
)

(define-private (is-provider-in-list (provider principal) (provider-list (list 5 principal)))
  (is-some (index-of provider-list provider))
)

(define-private (validate-multisig-providers (providers (list 5 principal)))
  (let ((provider-count (len providers)))
    (and 
      (>= provider-count min-multisig-signatures)
      (<= provider-count max-multisig-signatures)
      (is-eq (len providers) (len (filter is-verified-provider providers)))
    )
  )
)

(define-private (is-verified-provider (provider principal))
  (match (map-get? healthcare-providers provider)
    provider-info (get verified provider-info)
    false
  )
)

(define-private (is-future-timestamp (timestamp uint))
  (> timestamp stacks-block-height)
)

;; Register a healthcare provider
(define-public (register-provider (name (string-ascii 100)) (license-number (string-ascii 50)) (specialty (string-ascii 50)))
  (let ((provider tx-sender))
    (asserts! (> (len name) u0) err-invalid-input)
    (asserts! (> (len license-number) u0) err-invalid-input)
    (asserts! (> (len specialty) u0) err-invalid-input)
    
    (map-set healthcare-providers 
      provider
      {
        name: name,
        license-number: license-number,
        specialty: specialty,
        verified: false,
        registered-at: stacks-block-height,
        emergency-authorized: false,
        last-emergency-access: u0
      }
    )
    (ok provider)
  )
)

;; Verify a healthcare provider (only contract owner)
(define-public (verify-provider (provider principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
    (asserts! (is-some (map-get? healthcare-providers provider)) err-not-found)
    
    (map-set healthcare-providers 
      provider
      (merge 
        (unwrap-panic (map-get? healthcare-providers provider))
        {verified: true}
      )
    )
    (ok true)
  )
)

;; Create a new medical record
(define-public (create-record (record-hash (string-ascii 64)) (record-type (string-ascii 50)))
  (let ((record-id (var-get next-record-id))
        (patient tx-sender)
        (current-records (default-to (list) (map-get? patient-records patient))))
    
    (asserts! (> (len record-hash) u0) err-invalid-input)
    (asserts! (is-valid-record-type record-type) err-invalid-input)
    (asserts! (< (len current-records) u100) err-invalid-input)
    
    (map-set medical-records 
      record-id
      {
        patient: patient,
        record-hash: record-hash,
        record-type: record-type,
        created-at: stacks-block-height,
        updated-at: stacks-block-height,
        is-active: true
      }
    )
    
    (map-set patient-records 
      patient
      (unwrap-panic (as-max-len? (append current-records record-id) u100))
    )
    
    (var-set next-record-id (+ record-id u1))
    (var-set total-records (+ (var-get total-records) u1))
    
    (ok record-id)
  )
)

;; Authorize provider for emergency access (only contract owner)
(define-public (authorize-emergency-access (provider principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-unauthorized)
    (asserts! (is-some (map-get? healthcare-providers provider)) err-not-found)
    
    (map-set healthcare-providers 
      provider
      (merge 
        (unwrap-panic (map-get? healthcare-providers provider))
        {emergency-authorized: true}
      )
    )
    (ok true)
  )
)

;; Emergency access to patient records (for critical situations)
(define-public (emergency-access (record-id uint) (emergency-type (string-ascii 30)) (justification (string-ascii 200)))
  (let ((record (unwrap! (map-get? medical-records record-id) err-not-found))
        (provider tx-sender)
        (provider-info (unwrap! (map-get? healthcare-providers provider) err-not-found))
        (access-log-id (var-get total-emergency-accesses)))
    
    (asserts! (get verified provider-info) err-access-denied)
    (asserts! (get emergency-authorized provider-info) err-access-denied)
    (asserts! (get is-active record) err-not-found)
    (asserts! (is-valid-emergency-type emergency-type) err-invalid-emergency-type)
    (asserts! (> (len justification) u10) err-invalid-input)
    (asserts! (not (check-emergency-cooldown provider)) err-emergency-cooldown)
    
    ;; Log emergency access
    (map-set emergency-access-log 
      access-log-id
      {
        record-id: record-id,
        provider: provider,
        emergency-type: emergency-type,
        justification: justification,
        accessed-at: stacks-block-height,
        patient: (get patient record),
        auto-expires-at: (+ stacks-block-height u72) ;; 12 hours auto-expiry
      }
    )
    
    ;; Update provider's last emergency access
    (map-set healthcare-providers 
      provider
      (merge provider-info {last-emergency-access: stacks-block-height})
    )
    
    ;; Grant temporary access
    (map-set access-permissions 
      {record-id: record-id, provider: provider}
      {
        granted-by: contract-owner, ;; System granted
        granted-at: stacks-block-height,
        expires-at: (+ stacks-block-height u72),
        access-level: "read",
        is-active: true
      }
    )
    
    (var-set total-emergency-accesses (+ access-log-id u1))
    (var-set total-access-grants (+ (var-get total-access-grants) u1))
    
    (ok access-log-id)
  )
)
(define-public (grant-access (record-id uint) (provider principal) (expires-at uint) (access-level (string-ascii 20)))
  (let ((record (unwrap! (map-get? medical-records record-id) err-not-found))
        (provider-info (unwrap! (map-get? healthcare-providers provider) err-not-found)))
    
    (asserts! (is-eq tx-sender (get patient record)) err-unauthorized)
    (asserts! (get verified provider-info) err-access-denied)
    (asserts! (is-future-timestamp expires-at) err-invalid-expiry)
    (asserts! (is-valid-access-level access-level) err-invalid-input)
    
    (map-set access-permissions 
      {record-id: record-id, provider: provider}
      {
        granted-by: tx-sender,
        granted-at: stacks-block-height,
        expires-at: expires-at,
        access-level: access-level,
        is-active: true
      }
    )
    
    (var-set total-access-grants (+ (var-get total-access-grants) u1))
    (ok true)
  )
)

;; Revoke access from a healthcare provider
(define-public (revoke-access (record-id uint) (provider principal))
  (let ((record (unwrap! (map-get? medical-records record-id) err-not-found))
        (permission-key {record-id: record-id, provider: provider})
        (permission (unwrap! (map-get? access-permissions permission-key) err-not-found)))
    
    (asserts! (is-eq tx-sender (get patient record)) err-unauthorized)
    (asserts! (get is-active permission) err-not-found)
    
    (map-set access-permissions 
      permission-key
      (merge permission {is-active: false})
    )
    
    (ok true)
  )
)

;; Update medical record (only by patient)
(define-public (update-record (record-id uint) (new-record-hash (string-ascii 64)))
  (let ((record (unwrap! (map-get? medical-records record-id) err-not-found)))
    
    (asserts! (is-eq tx-sender (get patient record)) err-unauthorized)
    (asserts! (get is-active record) err-not-found)
    (asserts! (> (len new-record-hash) u0) err-invalid-input)
    
    (map-set medical-records 
      record-id
      (merge record {
        record-hash: new-record-hash,
        updated-at: stacks-block-height
      })
    )
    
    (ok true)
  )
)

;; Deactivate medical record (only by patient)
(define-public (deactivate-record (record-id uint))
  (let ((record (unwrap! (map-get? medical-records record-id) err-not-found)))
    
    (asserts! (is-eq tx-sender (get patient record)) err-unauthorized)
    (asserts! (get is-active record) err-not-found)
    
    (map-set medical-records 
      record-id
      (merge record {is-active: false})
    )
    
    (ok true)
  )
)

;; Read-only Functions

;; Get medical record details
(define-read-only (get-record (record-id uint))
  (map-get? medical-records record-id)
)

;; Get patient's records
(define-read-only (get-patient-records (patient principal))
  (map-get? patient-records patient)
)

;; Get healthcare provider info
(define-read-only (get-provider-info (provider principal))
  (map-get? healthcare-providers provider)
)

;; Check if provider has access to record
(define-read-only (check-access (record-id uint) (provider principal))
  (let ((permission (map-get? access-permissions {record-id: record-id, provider: provider})))
    (match permission
      perm (and 
        (get is-active perm)
        (> (get expires-at perm) stacks-block-height)
      )
      false
    )
  )
)

;; Get access permission details
(define-read-only (get-access-permission (record-id uint) (provider principal))
  (map-get? access-permissions {record-id: record-id, provider: provider})
)

;; Get multisig access request details
(define-read-only (get-multisig-request (request-id uint))
  (map-get? multisig-access-requests request-id)
)

;; Get multisig providers for a request
(define-read-only (get-multisig-providers (request-id uint))
  (map-get? multisig-providers request-id)
)

;; Get multisig signature details
(define-read-only (get-multisig-signature (request-id uint) (provider principal))
  (map-get? multisig-signatures {request-id: request-id, provider: provider})
)

;; Check if provider has signed multisig request
(define-read-only (has-provider-signed (request-id uint) (provider principal))
  (is-some (map-get? multisig-signatures {request-id: request-id, provider: provider}))
)

;; Get emergency access log
(define-read-only (get-emergency-access-log (log-id uint))
  (map-get? emergency-access-log log-id)
)

;; Get patient's emergency access history
(define-read-only (get-patient-emergency-history (patient principal))
  (filter check-patient-emergency-record (map list-emergency-logs (list u0 u1 u2 u3 u4 u5 u6 u7 u8 u9)))
)

(define-private (check-patient-emergency-record (log-entry (optional {record-id: uint, provider: principal, emergency-type: (string-ascii 30), justification: (string-ascii 200), accessed-at: uint, patient: principal, auto-expires-at: uint})))
  (match log-entry
    entry (is-eq (get patient entry) tx-sender)
    false
  )
)

(define-private (list-emergency-logs (log-id uint))
  (map-get? emergency-access-log log-id)
)

;; Get contract statistics
(define-read-only (get-contract-stats)
  {
    total-records: (var-get total-records),
    total-access-grants: (var-get total-access-grants),
    total-emergency-accesses: (var-get total-emergency-accesses),
    total-multisig-requests: (var-get total-multisig-requests),
    next-record-id: (var-get next-record-id),
    next-multisig-id: (var-get next-multisig-id)
  }
)

;; Check if user is contract owner
(define-read-only (is-contract-owner (user principal))
  (is-eq user contract-owner)
)