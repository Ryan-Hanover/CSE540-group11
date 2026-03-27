// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.0/contracts/utils/cryptography/ECDSA.sol";

contract Identity {
    address public owner;

    struct Credential {
        bool valid;
        string ipfsCID;
        address walletAddress;
    }

    mapping(bytes32 => Credential) private credentials;

    constructor() {
        owner = msg.sender;
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
        address signer = ECDSA.recover(credentialHash, signature);
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
