// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title IIssuer Interface
/// @notice Interface for verifying issued credentials against a stored hash and signature
/// @dev Implement this interface in any contract that acts as a credential issuer
interface IIssuer {
    /// @notice Verifies the authenticity of a credential
    /// @dev Checks that the signature over the credential hash matches the issuer's key,
    ///      and that the CID corresponds to the stored credential document
    /// @param credentialHash The keccak256 hash of the credential data
    /// @param cid The IPFS Content Identifier pointing to the off-chain credential document
    /// @param signature The cryptographic signature produced by the issuer over the credential
    /// @return bool True if the credential is valid and the signature is authentic, false otherwise
    function verify(
        bytes32 credentialHash,
        string calldata cid,
        bytes calldata signature
    ) external view returns (bool);
}

/// @title IDIDRegistry Interface
/// @notice Interface for checking the active status of a Decentralized Identifier (DID)
/// @dev Implement this interface to integrate with any DID registry contract
interface IDIDRegistry {
    /// @notice Returns whether the DID associated with a given address is currently active
    /// @param holderAddress The Ethereum address whose DID status is being queried
    /// @return bool True if the DID is active, false if deactivated or non-existent
    function isDIDActive(address holderAddress) external view returns (bool);
}

/// @title Verifier
/// @notice A restricted gateway contract for verifying decentralised credentials
/// @dev This contract represents the "Verifier" (Election Official) in our 3-entity design.
///      Delegates credential verification to an IIssuer implementation.
///      Only the contract owner may call the verify function, providing an
///      access-control layer on top of the underlying issuer logic.
///      Future versions may integrate IDIDRegistry to gate verification on
///      holder DID status.
contract Verifier {
    /// @notice The address of the account that deployed and owns this contract
    address public owner;

    /// @dev Reference to the credential issuer contract
    IIssuer private issuer;

    /// @dev Reference to the DID registry contract
    IDIDRegistry private didRegistry;

    /// @notice Deploys the Verifier and binds it to an issuer and a DID registry
    /// @param issuerAddress The address of the deployed IIssuer contract
    /// @param didAddress The address of the deployed IDIDRegistry contract
    constructor(address issuerAddress, address didAddress) {
        owner = msg.sender;
        issuer = IIssuer(issuerAddress);
        didRegistry = IDIDRegistry(didAddress);
    }

    /// @dev Restricts access to the contract owner only
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    /// @notice Verifies a credential by delegating to the issuer contract
    /// @dev The verifier only sees a true/false result from the Issuer; it never
    ///      sees the voter's age, name, or any other field from the credential.
    ///      That is the whole point of routing the check through the Issuer
    ///      instead of letting the verifier read voter data directly.
    /// @param credentialHash The keccak256 hash of the credential data
    /// @param cid The IPFS Content Identifier pointing to the off-chain credential document
    /// @param signature The cryptographic signature produced by the issuer over the credential
    /// @return bool True if the credential passes issuer verification, false otherwise
    function verify(
        bytes32 credentialHash,
        string calldata cid,
        bytes calldata signature
    ) external view onlyOwner returns (bool) {
        return issuer.verify(credentialHash, cid, signature);
    }
}
