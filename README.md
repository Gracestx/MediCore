# MediCore 🏥

A decentralized medical records management system built on Stacks blockchain that empowers patients to control access to their health data while enabling secure healthcare provider collaboration.

## Overview

MediCore revolutionizes healthcare data management by providing patients with complete ownership and control over their medical records. Healthcare providers can request access to specific records, and patients can grant time-limited permissions with different access levels.

## Key Features

- **Patient-Controlled Access**: Patients own and control all access to their medical records
- **Verified Healthcare Providers**: Only verified medical professionals can access records
- **Time-Limited Permissions**: Access grants expire automatically for enhanced security
- **Granular Access Levels**: Different permission levels (read, write, full) for various use cases
- **Immutable Audit Trail**: All access grants and revocations are permanently recorded
- **Privacy-First Design**: Only encrypted hashes are stored on-chain, not actual medical data

## Smart Contract Functions

### For Patients
- `create-record`: Store a new medical record hash
- `grant-access`: Allow a healthcare provider to access a specific record
- `revoke-access`: Remove access permissions from a provider
- `update-record`: Update an existing medical record
- `deactivate-record`: Permanently deactivate a record

### For Healthcare Providers
- `register-provider`: Register as a healthcare provider
- `get-record`: Access medical records (if permissions granted)
- `check-access`: Verify access permissions to a record

### For Contract Owner
- `verify-provider`: Verify healthcare provider credentials

## Record Types Supported

- Diagnosis
- Prescription
- Laboratory Results
- Medical Imaging
- Treatment Plans
- Consultation Notes

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
```

## Security Features

- All inputs are validated to prevent malicious data
- Access permissions automatically expire
- Only verified healthcare providers can access records
- Patients maintain full control over their data
- Comprehensive error handling prevents unauthorized access

## Testing

Run the test suite with:
```bash
clarinet test
```

## Contributing

We welcome contributions! Please read our contributing guidelines and submit pull requests for any improvements.

*MediCore - Empowering patients, enabling healthcare providers, securing medical data.*