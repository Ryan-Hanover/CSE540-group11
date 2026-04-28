// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/// @title DID Registry Interface
/// @notice Interface for the Decentralized Identity (DID) Registry to ensure the voter has a valid decentralized identity.
interface IDIDRegistry {
    /// @notice Checks if a DID is active
    /// @param holderAddress The address of the DID holder
    /// @return bool True if the DID is active, false otherwise
    function isDIDActive(address holderAddress) external view returns (bool);
}

/// @title Age Verification Issuer
/// @notice Contract for issuing and verifying age verification credentials
/// @dev This contract represents the "Issuer" in the 3-entity design. 
///      The Issuer acts as the trusted authority (e.g., the government) 
///      that checks if the voter is 18+ and issues a digital credential.
contract Issuer {
    /// @notice Address of the contract owner. The trusted authority (government/election official admin) deploying the contract
    address public owner;

    /// @notice Reference to the DID Registry contract
    IDIDRegistry private didRegistry;

    /// @notice Struct representing a credential
    /// @dev Represents the digital credential proving the voter is over the legal age limit.
    ///      toring the full credential on-chain is expensive and compromises privacy. 
    ///      Instead, we only store a validity flag, the voter's address, and the IPFS CID (hash).
    /// @member valid Boolean indicating if the credential is valid
    /// @member ipfsCID CID (Content Identifier) for the credential data stored on IPFS
    /// @member walletAddress Address of the wallet associated with the credential
    struct Credential {
        bool valid; // True if active, False if revoked
        string ipfsCID; // The small hash returned from the IPFS layer pointing to the encrypted credential metadata
        address walletAddress; // The Decentralized IAM wallet address of the Voter
    }

    /// @notice Mapping of a unique credential hash to their corresponding credential data on the blockchain.
    mapping(bytes32 => Credential) private credentials;

    /// @notice Constructor for the Issuer contract
    /// @param didAddress Address of the DID Registry contract
    constructor(address didAddress) {
        owner = msg.sender;
        didRegistry = IDIDRegistry(didAddress);
    }

    /// @notice Modifier to restrict access to the contract owner. 
    ///      Ensures only the trusted Issuer (Government) can issue or revoke credentials
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    /// @notice Verifies a credential
    /// @dev Checks if a credential both exists and is not revoked.
    ///      Verifies the cryptographic signature against the voter's DID to prevent identity theft.
    ///      Only returns true/false to ensure the official learns nothing else about the voter's personal information.
    /// @param credentialHash Hash of the credential to verify
    /// @param cid CID of the credential data stored on IPFS
    /// @param signature Signature of the credential hash
    /// @return bool True if the credential is valid, false otherwise
    function verify(
        bytes32 credentialHash,
        string calldata cid,
        bytes calldata signature
    ) public view returns (bool) {
        Credential memory cred = credentials[credentialHash];
        
        // Recover the signer's address from the provided signature and hash
        bytes32 ethHash = MessageHashUtils.toEthSignedMessageHash(credentialHash);
        address signer = ECDSA.recover(ethHash, signature);

        // Returns true ONLY if the credential is valid, the IPFS hashes match,
        // the credential is signed by the trusted issuer and the holder's DID is active.
        return
            cred.valid &&
            keccak256(abi.encodePacked(cred.ipfsCID)) ==
                keccak256(abi.encodePacked(cid)) &&
            signer == owner && 
            didRegistry.isDIDActive(cred.walletAddress);
    }

    /// @notice Issues a new credential
    /// @dev Called by the Issuer App (Web) to issue a new digital credential to a Voter.
    ///      Emits the credential state to the Ethereum blockchain, storing only the IPFS content hash to save costs.
    /// @param credentialHash Hash of the credential to issue
    /// @param cid CID of the credential data stored on IPFS
    /// @param walletAddress Address of the wallet associated with the credential
    /// @return bool True if the credential was successfully issued, false otherwise
    function issueCredential(
        bytes32 credentialHash,
        string calldata cid,
        address walletAddress
    ) public onlyOwner returns (bool) {
        require (didRegistry.isDIDActive(walletAddress), "Not an active DID");

        // Only issue if this credential hash hasn't been mapped as valid already
        if (!credentials[credentialHash].valid) {
            credentials[credentialHash] = Credential(true, cid, walletAddress);
            return true;
        }
        return false;
    }

    /// @notice Revokes an existing credential
    /// @dev Allows the trusted authority to revoke credentials from voters when needed 
    ///      (e.g., if a credential was issued improperly or needs to be invalidated due to certain scenarios).
    /// @param credentialHash Hash of the credential to revoke
    /// @return bool True if the credential was successfully revoked, false otherwise
    function revokeCredential(
        bytes32 credentialHash
    ) public onlyOwner returns (bool) {
        if (credentials[credentialHash].valid) {
            // Marks the credential as invalid so the Verifier contract will reject it
            credentials[credentialHash].valid = false;
            return true;
        }
        return false;
    }
}
