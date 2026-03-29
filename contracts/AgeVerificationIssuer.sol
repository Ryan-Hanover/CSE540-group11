// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

interface IDIDRegistry {function isDIDActive(address holderAddress) external view returns (bool);}

contract Issuer {
    address public owner;
    IDIDRegistry private didRegistry;

    struct Credential {
        bool valid;
        string ipfsCID;
        address walletAddress;
    }

    mapping(bytes32 => Credential) private credentials;

    constructor(address didAddress) {
        owner = msg.sender;
        didRegistry = IDIDRegistry(didAddress);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

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