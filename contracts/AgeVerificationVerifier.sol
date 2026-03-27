// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface IIdentity {
     function verify(bytes32 credentialHash, string calldata cid, bytes calldata signature) external view returns (bool);
}

contract Verifier {
    address public owner;
    IIdentity private identity;

    constructor(address identityAddress) {
        owner = msg.sender;
        identity = IIdentity(identityAddress);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    function verify(bytes32 credentialHash, string calldata cid, bytes calldata signature) public view onlyOwner returns (bool) {
        return identity.verify(credentialHash, cid, signature);
    }
}

