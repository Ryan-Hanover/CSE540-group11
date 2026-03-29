// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface IIssuer {
     function verify(bytes32 credentialHash, string calldata cid, bytes calldata signature) external view returns (bool);
}

interface IDIDRegistry {function isDIDActive(address holderAddress) external view returns (bool);}

contract Verifier {
    address public owner;
    IIssuer private issuer;
    IDIDRegistry private didRegistry;

    constructor(address issuerAddress, address didAddress) {
        owner = msg.sender;
        issuer = IIssuer(issuerAddress);
        didRegistry = IDIDRegistry(didAddress);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }


    function verify(bytes32 credentialHash, string calldata cid, bytes calldata signature) external view onlyOwner returns (bool) {
        return issuer.verify(credentialHash, cid, signature);
    }
}