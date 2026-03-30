// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title DIDRegistry
/// @notice On-chain registry for managing Decentralized Identifiers (DIDs)
/// @dev Each Ethereum address may register at most one DID, represented by a
///      hash of an off-chain DID document. DIDs can be deactivated by their
///      holder but cannot be deleted or re-registered once created.
///      All sensitive DID document data should be stored off-chain; only the
///      document hash is persisted here for integrity verification.
contract DIDRegistry {

    /// @notice Represents a registered DID entry
    /// @param holder The Ethereum address that owns and controls this DID
    /// @param documentHash The keccak256 hash of the off-chain DID document
    /// @param isActive Whether the DID is currently active and usable
    struct DIDEntry {
        address holder;
        bytes32 documentHash;
        bool isActive;
    }

    /// @dev Maps each holder address to their corresponding DID entry.
    ///      An entry with holder == address(0) indicates no DID is registered.
    mapping(address => DIDEntry) private didEntries;

    /// @notice Emitted when a new DID is successfully registered
    /// @param holder The address that registered the DID
    /// @param documentHash The hash of the associated DID document
    event DIDRegistered(address indexed holder, bytes32 indexed documentHash);

    /// @notice Emitted when a DID is deactivated by its holder
    /// @param holder The address whose DID was deactivated
    event DIDDeactivated(address indexed holder);

    /// @dev Reverts if the caller is not the holder of the specified DID
    /// @param holderAddress The address of the expected DID holder
    modifier onlyHolder(address holderAddress) {
        require(didEntries[holderAddress].holder == msg.sender, "Not authorized");
        _;
    }

    /// @dev Reverts if no DID has been registered for the given address
    /// @param holderAddress The address to check for an existing DID entry
    modifier didExists(address holderAddress) {
        require(didEntries[holderAddress].holder != address(0), "DID does not exist");
        _;
    }

    /// @notice Registers a new DID for the calling address
    /// @dev Each address may only register one DID. The documentHash must be
    ///      non-zero and should correspond to an off-chain DID document
    ///      (e.g. stored on IPFS). Emits {DIDRegistered} on success.
    /// @param documentHash The keccak256 hash of the caller's DID document
    function registerDID(bytes32 documentHash) external {
        require(didEntries[msg.sender].holder == address(0), "DID already exists");
        require(documentHash != bytes32(0), "Invalid document hash");

        didEntries[msg.sender] = DIDEntry({
            holder: msg.sender,
            documentHash: documentHash,
            isActive: true
        });

        emit DIDRegistered(msg.sender, documentHash);
    }

    /// @notice Permanently deactivates the caller's registered DID
    /// @dev Sets isActive to false. This action is irreversible — the DID
    ///      cannot be reactivated or re-registered under the same address.
    ///      Reverts if the caller has no registered DID. Emits {DIDDeactivated}.
    function deactivateDID() external didExists(msg.sender) {
        didEntries[msg.sender].isActive = false;
        emit DIDDeactivated(msg.sender);
    }

    /// @notice Checks whether the DID for a given address is currently active
    /// @dev Returns false for both deactivated DIDs and addresses with no
    ///      registered DID, since the default value of isActive is false.
    /// @param holderAddress The address whose DID status is being queried
    /// @return bool True if the DID exists and is active, false otherwise
    function isDIDActive(address holderAddress) external view returns (bool) {
        DIDEntry memory entry = didEntries[holderAddress];
        return entry.isActive;
    }

    /// @notice Retrieves the full DID entry for a given holder address
    /// @dev Reverts if no DID is registered for holderAddress.
    ///      Use {isDIDActive} first when only the active status is needed.
    /// @param holderAddress The address whose DID entry is being retrieved
    /// @return holder The address that owns the DID
    /// @return documentHash The keccak256 hash of the associated DID document
    /// @return active Whether the DID is currently active
    function getDID(address holderAddress)
        external
        view
        didExists(holderAddress)
        returns (address holder, bytes32 documentHash, bool active)
    {
        DIDEntry memory entry = didEntries[holderAddress];
        return (entry.holder, entry.documentHash, entry.isActive);
    }
}
