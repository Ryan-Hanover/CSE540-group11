// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/// @title DID Registry Interface
/// @notice Interface for checking if a DID (Decentralized Identifier) is active
interface IDIDRegistry {
    /// @notice Checks if a DID is active
    /// @param holderAddress The address of the DID holder
    /// @return bool True if the DID is active, false otherwise
    function isDIDActive(address holderAddress) external view returns (bool);
}

/// @title Age Verification Issuer
/// @notice Contract for issuing and verifying age verification credentials
contract Issuer {
    /// @notice Address of the contract owner
    address public owner;

    /// @notice Reference to the DID Registry contract
    IDIDRegistry private didRegistry;

    /// @notice Struct representing a credential
    /// @member valid Boolean indicating if the credential is valid
    /// @member ipfsCID CID (Content Identifier) for the credential data stored on IPFS
    /// @member walletAddress Address of the wallet associated with the credential
    struct Credential {
        bool valid;
        string ipfsCID;
        address walletAddress;
    }

    /// @notice Mapping of credential hashes to their corresponding credential data
    mapping(bytes32 => Credential) private credentials;

    /// @notice Constructor for the Issuer contract
    /// @param didAddress Address of the DID Registry contract
    constructor(address didAddress) {
        owner = msg.sender;
        didRegistry = IDIDRegistry(didAddress);
    }

    /// @notice Modifier to restrict access to the contract owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    /// @notice Verifies a credential
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
        bytes32 ethHash = MessageHashUtils.toEthSignedMessageHash(credentialHash);
        address signer = ECDSA.recover(ethHash, signature);
        require(didRegistry.isDIDActive(signer), "Not an active DID");
        return
            cred.valid &&
            keccak256(abi.encodePacked(cred.ipfsCID)) ==
                keccak256(abi.encodePacked(cid)) &&
            signer == cred.walletAddress;
    }

    /// @notice Issues a new credential
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
        if (!credentials[credentialHash].valid) {
            credentials[credentialHash] = Credential(true, cid, walletAddress);
            return true;
        }
        return false;
    }

    /// @notice Revokes an existing credential
    /// @param credentialHash Hash of the credential to revoke
    /// @return bool True if the credential was successfully revoked, false otherwise
    function revokeCredential(
        bytes32 credentialHash
    ) public onlyOwner returns (bool) {
        if (credentials[credentialHash].valid) {
            credentials[credentialHash].valid = false;
            return true;
        }
        return false;
    }
}
