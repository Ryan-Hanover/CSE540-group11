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


## Run and Test

### Dependencies (Debian/Ubuntu Linux)

**Kubo IPFS:**
1. `wget https://dist.ipfs.tech/kubo/v0.40.1/kubo_v0.40.1_linux-amd64.tar.gz`
2. `tar -xvzf kubo_v0.40.1_linux-amd64.tar.gz`
3. `cd kubo && sudo bash install.sh`
4. `ipfs init` (first time only)
5. `ipfs daemon`

**Python dependencies:**
```bash
pip install requests web3 eth-abi
```

## Instructions to Test

1. In Remix, deploy `AgeVerificationIssuer.sol` first and copy the contract address shown in the deployed contracts panel.

2. Deploy `AgeVerificationVerifier.sol` second, pasting the `AgeVerificationIssuer.sol` address into the constructor field before deploying.

3. With the IPFS daemon running and both contracts deployed, run `info_2_ipfs.py` with the required arguments (May have to make executable first):
```bash
    info_2_ipfs.py --firstName John --lastName Doe --dob 1990-01-01
```

4. In Remix, navigate to the deployed `AgeVerificationIssuer` contract. Call `issueCredential` with the `credentialHash`, `ipfsCID`, and `walletAddress` printed by the script.

5. Navigate to the deployed `AgeVerificationVerifier` contract. Call `verify` with the same `credentialHash` and `ipfsCID`.

6. To generate a signature, navigate to the top of the Deploy panel in Remix. Click the pencil icon next to the account dropdown, paste the `credentialHash` from the script into the message field, and click Sign. Copy the **Signature** value (not the Hash).

7. Paste the signature into the `verify` call alongside the `credentialHash` and `ipfsCID`. Click transact and confirm the result is `true`.
