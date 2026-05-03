# CSE540-group11

## 1. Overview

This project implements a privacy-preserving voter eligibility system on Ethereum. The system enables the voter to prove that they are 18 or older without revealing unneccessary personal information. This system enables age verification, where the trusted issuer only provides a digital credential and a verifier checks only the age condition. Overall, this decentralized system aims to mitigate the risks associated with centralized systems, such as single points of failure and data breaches.

## 2. Features

This project implements a three-contract architecture:

###### DIDRegistry.sol

Stores holder-controlled DID entries, anchors minimal on-chain data, and logs key events when holder registers or deactivates their DID.

###### AgeVerificationIssuer

Issues and revokes cryptographic age credentials to eligible voters

###### AgeVerificationVerifier — verifies age and records votes on-chain

Verifies if the holder has an active DID and if the issuer can confirm the credential for that DID.

## Run and Test

### Quick start (Debian/Ubuntu Linux)

The repo ships with a one-shot bootstrap script that installs every dependency,
starts the IPFS daemon and a local dev chain, and deploys all three contracts.

Prerequisites (must already be installed system-wide):

- Python 3.10+ (`python3`, `python3-venv`)
- Node.js 18+ and `npm`
- Kubo IPFS (`ipfs` on PATH) — see https://dist.ipfs.tech/ or the legacy
  instructions at the bottom of this file.
- `curl`

Then, from the repo root:

```bash
./setup.sh
```

That will:

- create a Python virtualenv at the repo root (if missing) and install
  `web3`, `eth_abi`, `requests`, `py-solc-x`;
- install Solidity compiler 0.8.30 via `py-solc-x`;
- install `ganache` and `@openzeppelin/contracts@5.0.2` into `tools/`;
- start `ipfs daemon` (if not already running) and a deterministic
  `ganache` dev chain on `127.0.0.1:8545`;
- compile and deploy `DIDRegistry`, `Issuer`, and `Verifier`, writing the
  addresses to `tools/deployed.json`.

At the end `setup.sh` prints the RPC URL, the three contract addresses, and
two funded private keys (authority and voter). Paste those into the terminal
UI prompts described below.

### Instructions to Test (via the terminal UIs)

After `./setup.sh` completes, run the three UIs in order. The authority key
is for the Issuer/Verifier owner; the voter key is for the credential
holder.

1. **Voter registers a DID** — `bin/python terminal_ui/voter_ui.py`, option
   `1`. Paste the RPC URL, voter private key, `DIDRegistry` address, then
   choose `2` and enter any text for the document (it gets keccak-hashed).
2. **Voter builds a credential package** — same UI, option `2`. Enter first
   name / last name / DOB. Copy the printed `credentialHash` and `ipfsCID`.
3. **Authority issues and signs the credential** — `bin/python terminal_ui/issuer_ui.py`,
   option `1`. Paste the authority key, Issuer address, the credentialHash
   and ipfsCID from step 2, the voter's wallet address, and the DOB from the
   credential package. If the DOB is 18 or older, the credential is issued and
   the UI prints an `Issuer Signature` to be shared with the verifier.
4. **Verifier checks the proof** — `bin/python terminal_ui/verifier_ui.py`,
   option `1`. Paste the authority key (only the Verifier owner may call
   `verify`), the Verifier address, and the credentialHash / ipfsCID /
   Issuer Signature. Expect `ALLOW`.

NEGATIVE TEST CASES:

1. Re-run step 1 with the same voter wallet after it has already registered a DID
   → registration fails because the DID already exists.
2. Enter a DOB younger than 18 in `issuer_ui.py` option `1` → issuance shows `DENY`.
3. Re-run step 4 with a tampered CID → `DENY`.
4. Use `issuer_ui.py` option `2` to revoke, then re-run step 4 → `DENY`.
5. Re-run step 4 with the voter key instead of the authority key →
   `DENY (... revert Not authorized)` from the `onlyOwner` check.

### Legacy Remix instructions

The contracts can still be deployed via Remix against the same local chain
(Environment → External Http Provider → `http://127.0.0.1:8545`). Deploy
`DIDRegistry` first, then `Issuer(didAddress)`, then
`Verifier(issuerAddress, didAddress)`. The terminal UIs work against those
addresses identically.
