# MediCore 🏥

A decentralized medical records management system built on Stacks blockchain that empowers patients to control access to their health data while enabling secure healthcare provider collaboration.

## Overview

MediCore revolutionizes healthcare data management by providing patients with complete ownership and control over their medical records. Healthcare providers can request access to specific records, and patients can grant time-limited permissions with different access levels.

## Key Features

- **Patient-Controlled Access**: Patients own and control all access to their medical records
- **Multi-signature Access**: Multiple healthcare providers can collaboratively access records for complex cases
- **Emergency Access Protocol**: Critical medical situations allow authorized providers emergency access with proper governance
- **Verified Healthcare Providers**: Only verified medical professionals can access records
- **Time-Limited Permissions**: Access grants expire automatically for enhanced security
- **Granular Access Levels**: Different permission levels (read, write, full) for various use cases
- **Emergency Access Logging**: Complete audit trail of all emergency access events
- **Multi-signature Audit Trail**: Comprehensive tracking of collaborative access requests and signatures
- **Cooldown Protection**: Prevents abuse of emergency access with mandatory waiting periods
- **Immutable Audit Trail**: All access grants and revocations are permanently recorded
- **Privacy-First Design**: Only encrypted hashes are stored on-chain, not actual medical data

## Smart Contract Functions

### For Patients
- `create-record`: Store a new medical record hash
- `grant-access`: Allow a healthcare provider to access a specific record
- `revoke-access`: Remove access permissions from a provider
- `update-record`: Update an existing medical record
- `deactivate-record`: Permanently deactivate a record
- `create-multisig-request`: Create a collaborative access request for complex cases
- `cancel-multisig-request`: Cancel an active multi-signature request

### For Healthcare Providers
- `register-provider`: Register as a healthcare provider
- `emergency-access`: Access patient records during critical medical emergencies
- `sign-multisig-request`: Sign collaborative access requests for complex cases
- `get-record`: Access medical records (if permissions granted)
- `check-access`: Verify access permissions to a record

### For Contract Owner
- `verify-provider`: Verify healthcare provider credentials
- `authorize-emergency-access`: Grant emergency access privileges to qualified providers

## Record Types Supported

- Diagnosis
- Prescription
- Laboratory Results
- Medical Imaging
- Treatment Plans
- Consultation Notes

## Multi-signature Access

For complex medical cases requiring collaborative care, MediCore supports multi-signature access requests:

### How It Works
1. **Patient Initiates**: Patient creates a multisig request specifying providers and required signatures
2. **Provider Selection**: Choose 2-5 verified healthcare providers for the collaboration
3. **Signature Collection**: Providers review the case and sign the request with justification
4. **Automatic Approval**: Once enough signatures are collected, all providers receive access
5. **Time-Limited Access**: Access expires at the specified time for security

### Multi-signature Requirements
- **Minimum Signatures**: At least 2 providers must sign
- **Maximum Providers**: Up to 5 providers can participate
- **Verified Providers Only**: All providers must be verified by the contract owner
- **Detailed Justification**: Each signature requires a detailed medical justification
- **Case Description**: Minimum 20 characters describing the complex case

### Use Cases
- **Complex Surgical Cases**: Multiple specialists collaborating on surgery
- **Rare Disease Diagnosis**: Multiple experts reviewing symptoms
- **Multi-disciplinary Treatment**: Coordinated care across specialties
- **Second Opinion Requests**: Multiple providers reviewing difficult cases
- **Research Collaboration**: Academic medical centers working together

## Emergency Access Types

- **Cardiac Arrest**: Immediate heart failure situations
- **Trauma**: Severe physical injuries requiring urgent care
- **Stroke**: Acute cerebrovascular accidents
- **Overdose**: Drug or substance overdose emergencies
- **Allergic Reaction**: Severe allergic responses
- **Unconscious**: Patient unconsciousness with unknown cause
- **Other Critical**: Other life-threatening emergencies

## Emergency Access Safeguards

- **24-Hour Cooldown**: Providers must wait 24 hours between emergency accesses
- **Authorization Required**: Only contract owner can authorize emergency access privileges
- **Automatic Expiry**: Emergency access automatically expires after 12 hours
- **Complete Audit Trail**: All emergency access events are permanently logged
- **Justification Required**: Providers must provide detailed justification for emergency access

## Access Levels

- **Read**: View record information only
- **Write**: Modify existing records
- **Full**: Complete access including deletion capabilities

## Getting Started

### Prerequisites
- Clarinet CLI installed
- Stacks wallet configured
- Basic understanding of Clarity smart contracts

### Installation

1. Clone the repository
2. Install dependencies with Clarinet
3. Deploy the contract to your preferred network

### Usage Example

```clarity
;; Register as a healthcare provider
(contract-call? .medicore register-provider "Dr. Jane Smith" "MD12345" "Cardiology")

;; Create a medical record (as patient)
(contract-call? .medicore create-record "abc123def456..." "diagnosis")

;; Grant access to a provider (as patient)
(contract-call? .medicore grant-access u1 'ST1PROVIDER... u1000 "read")

;; Create multisig request for complex case (as patient)
(contract-call? .medicore create-multisig-request u1 
  (list 'ST1CARDIO... 'ST1SURGEON... 'ST1ANESTHESIA...) 
  u2 
  "Complex cardiac surgery requiring multi-specialty collaboration" 
  "read" 
  u2000)

;; Sign multisig request (as healthcare provider)
(contract-call? .medicore sign-multisig-request u1 "Reviewed case, surgical intervention recommended")

;; Emergency access during critical situation (as authorized provider)
(contract-call? .medicore emergency-access u1 "cardiac-arrest" "Patient unconscious, requires immediate medical history")
```

## Security Features

- All inputs are validated to prevent malicious data
- Access permissions automatically expire
- Only verified healthcare providers can access records
- Multi-signature requests require verified providers and detailed justifications
- Emergency access requires authorization and has built-in safeguards
- 24-hour cooldown period prevents emergency access abuse
- Complete audit trail for all access events (individual, multisig, and emergency)
- Patients maintain full control over their data and collaboration requests
- Comprehensive error handling prevents unauthorized access

## Testing

Run the test suite with:
```bash
clarinet test
```

## Contributing

We welcome contributions! Please read our contributing guidelines and submit pull requests for any improvements.

*MediCore - Empowering patients, enabling healthcare providers, securing medical data.*