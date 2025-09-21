# JusticeChain

JusticeChain is a legal technology platform for jury assembly and verdict transparency in court systems. Built on the Stacks blockchain using Clarity smart contracts, it provides a transparent and immutable system for managing jury selection, case assignments, and verdict recording.

## Features

- **Juror Registration**: Citizens can register as potential jurors with unique identification
- **Case Management**: Court officials can create cases with customizable jury sizes (1-12 jurors)
- **Jury Assignment**: Transparent assignment of available jurors to pending cases
- **Verdict Recording**: Secure recording of case verdicts with jury vote counts
- **Status Tracking**: Real-time tracking of juror and case statuses
- **Transparency**: All actions are recorded on the blockchain for public verification
- **Access Control**: Role-based permissions for different system participants

## Technical Specifications

- **Blockchain**: Stacks
- **Smart Contract Language**: Clarity v2
- **Epoch**: 2.5
- **Test Framework**: Vitest with Clarinet SDK
- **Dependencies**: Stacks transactions library, Clarinet SDK

## Installation

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) - Stacks smart contract development tool
- [Node.js](https://nodejs.org/) (v16 or higher)
- [npm](https://www.npmjs.com/) or [yarn](https://yarnpkg.com/)

### Setup

1. Clone the repository:
```bash
git clone <repository-url>
cd JusticeChain
```

2. Navigate to the contract directory:
```bash
cd JusticeChain_contract
```

3. Install dependencies:
```bash
npm install
```

4. Run tests:
```bash
npm test
```

## Usage Examples

### Registering as a Juror

```clarity
;; Register as a juror (returns juror ID)
(contract-call? .JusticeChain register-juror)
```

### Creating a Case

```clarity
;; Create a new case (contract owner only)
(contract-call? .JusticeChain create-case
  "Criminal Case #2024-001"
  "Theft charges involving stolen property valued at $5000"
  'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
  u12)
```

### Assigning Jurors

```clarity
;; Assign a juror to a case (contract owner only)
(contract-call? .JusticeChain assign-juror-to-case u1 u1)
```

### Recording Verdicts

```clarity
;; Record case verdict (judge only)
(contract-call? .JusticeChain record-verdict
  u1
  "Guilty on all charges"
  u10)
```

## Contract Functions Documentation

### Public Functions

#### `register-juror`
- **Purpose**: Register a citizen as a potential juror
- **Parameters**: None
- **Returns**: `(response uint uint)` - Juror ID on success
- **Access**: Any principal (one registration per principal)

#### `create-case`
- **Purpose**: Create a new legal case requiring jury assembly
- **Parameters**:
  - `title`: Case title (max 100 characters)
  - `description`: Case description (max 500 characters)
  - `judge`: Principal address of the assigned judge
  - `jury-size`: Number of jurors needed (1-12)
- **Returns**: `(response uint uint)` - Case ID on success
- **Access**: Contract owner only

#### `assign-juror-to-case`
- **Purpose**: Assign an available juror to a pending case
- **Parameters**:
  - `case-id`: ID of the case
  - `juror-id`: ID of the juror to assign
- **Returns**: `(response bool uint)` - Success confirmation
- **Access**: Contract owner only

#### `record-verdict`
- **Purpose**: Record the final verdict for an active case
- **Parameters**:
  - `case-id`: ID of the case
  - `verdict`: Verdict text (max 200 characters)
  - `jury-votes`: Number of jury votes supporting the verdict
- **Returns**: `(response bool uint)` - Success confirmation
- **Access**: Case judge only

#### `dismiss-juror`
- **Purpose**: Remove a juror from active duty
- **Parameters**:
  - `juror-id`: ID of the juror to dismiss
- **Returns**: `(response bool uint)` - Success confirmation
- **Access**: Contract owner only

### Read-Only Functions

#### `get-juror`
- **Purpose**: Retrieve juror information
- **Parameters**: `juror-id`
- **Returns**: Juror data including status and assignment

#### `get-juror-id`
- **Purpose**: Get juror ID by principal address
- **Parameters**: `principal`
- **Returns**: Juror ID if registered

#### `get-case`
- **Purpose**: Retrieve case information
- **Parameters**: `case-id`
- **Returns**: Case data including status and jury size

#### `get-verdict`
- **Purpose**: Retrieve case verdict
- **Parameters**: `case-id`
- **Returns**: Verdict data including votes and recording details

#### `is-juror-assigned-to-case`
- **Purpose**: Check if a juror is assigned to a specific case
- **Parameters**: `case-id`, `juror-id`
- **Returns**: Boolean indicating assignment status

## Status Codes

### Juror Status
- `0`: Available for assignment
- `1`: Assigned to a case
- `2`: Dismissed from service

### Case Status
- `0`: Pending (waiting for jury assembly)
- `1`: Active (jury assembled, case in progress)
- `2`: Closed (verdict recorded)

### Error Codes
- `u100`: Owner-only operation
- `u101`: Resource not found
- `u102`: Unauthorized access
- `u103`: Resource already exists
- `u104`: Invalid status
- `u105`: Jury already full
- `u106`: Case already closed

## Deployment Guide

### Local Development

1. Start Clarinet console:
```bash
clarinet console
```

2. Deploy contract:
```clarity
::deploy_contracts
```

3. Test functions in the REPL environment

### Testnet Deployment

1. Configure testnet settings in `settings/Testnet.toml`
2. Deploy using Clarinet:
```bash
clarinet deploy --testnet
```

### Mainnet Deployment

1. Configure mainnet settings in `settings/Mainnet.toml`
2. Deploy using Clarinet:
```bash
clarinet deploy --mainnet
```

## Security Notes

### Access Controls
- **Contract Owner**: Can create cases, assign jurors, and dismiss jurors
- **Judges**: Can only record verdicts for their assigned cases
- **Jurors**: Can only register themselves, cannot modify case data
- **Public**: Can read all data for transparency

### Security Considerations
- All sensitive operations require appropriate role verification
- Juror assignments are permanent until case completion or dismissal
- Verdicts are immutable once recorded
- Block height tracking provides temporal ordering of events
- Principal-based authentication prevents impersonation

### Limitations
- Maximum jury size is limited to 12 jurors
- String fields have character limits to prevent bloat
- No mechanism for case appeals or verdict modifications
- Contract owner has significant privileges (consider multi-sig for production)

## Testing

Run the test suite:
```bash
# Run all tests
npm test

# Run tests with coverage report
npm run test:report

# Watch mode for development
npm run test:watch
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make changes and add tests
4. Run the test suite
5. Submit a pull request

## License

This project is licensed under the ISC License.

## Support

For issues and questions, please open an issue in the project repository.