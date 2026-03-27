# CSE540-group11
## 1. Overview
This project implements a privacy-preserving voter eligibility system on Ethereum. Voters prove they are 18 or older without revealing any personal information. The system achieves this using three technologies working together:

###### a. Verifiable Credentials (VCs)
 This acts as the digital certification no the persons' elgibility
###### b. IPFS
 Decentralized storage to reduce computational time and storage of credential data
###### c. Zero-Knowledge Proofs (ZKPs)

## 2. Features
 This project implements a two-contract architecture:
  ###### AgeVerificationIssuer
  Issues cryptographic age credentials to eligible voters
  ###### AgeVerificationVerifier — verifies ZKP-based age proofs and records votes on-chain
 Credential metadata is stored on IPFS to keep on-chain storage costs minimal. The system ensures voter privacy, prevents double-voting, and requires no trusted central authority.
