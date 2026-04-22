"""Shared helpers for terminal-based IAM age-verification demo CLIs."""

from __future__ import annotations
from dataclasses import dataclass
from web3 import Web3
# TODO: import additional necessary packages

IPFS_API = "http://127.0.0.1:5001/api/v0"

DID_REGISTRY_ABI = [
    {
        "inputs": [{"internalType": "bytes32", "name": "documentHash", "type": "bytes32"}],
        "name": "registerDID",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function",
    },
    {
        "inputs": [{"internalType": "address", "name": "holderAddress", "type": "address"}],
        "name": "isDIDActive",
        "outputs": [{"internalType": "bool", "name": "", "type": "bool"}],
        "stateMutability": "view",
        "type": "function",
    },
]

ISSUER_ABI = [
    {
        "inputs": [
            {"internalType": "bytes32", "name": "credentialHash", "type": "bytes32"},
            {"internalType": "string", "name": "cid", "type": "string"},
            {"internalType": "address", "name": "walletAddress", "type": "address"},
        ],
        "name": "issueCredential",
        "outputs": [{"internalType": "bool", "name": "", "type": "bool"}],
        "stateMutability": "nonpayable",
        "type": "function",
    },
    {
        "inputs": [{"internalType": "bytes32", "name": "credentialHash", "type": "bytes32"}],
        "name": "revokeCredential",
        "outputs": [{"internalType": "bool", "name": "", "type": "bool"}],
        "stateMutability": "nonpayable",
        "type": "function",
    },
]

@dataclass
class ChainContext:
    web3: Web3
    account: str

# TODO: add common data structures


def prompt_non_empty(label: str, secret: bool = False) -> str:
    while True:
        value = getpass(label) if secret else input(label)
        value = value.strip()
        if value:
            return value
        print("Input cannot be empty.")


def prompt_optional(label: str, default: str) -> str:
    value = input(f"{label} [{default}]: ").strip()
    return value or default


def connect_chain_with_account() -> ChainContext:
    rpc_url = prompt_optional("RPC URL", "http://127.0.0.1:8545")
    private_key = prompt_non_empty("Private key (0x...): ", secret=True)

    web3 = Web3(Web3.HTTPProvider(rpc_url))
    if not web3.is_connected():
        raise RuntimeError(f"Could not connect to RPC at {rpc_url}")

    account = web3.eth.account.from_key(private_key)
    return ChainContext(web3=web3, account=account)


def prompt_contract_address(web3: Web3, label: str) -> str:
    address = prompt_non_empty(f"{label} address: ")
    return web3.to_checksum_address(address)

def parse_bytes32(value: str) -> bytes:
    """Parse a 0x-prefixed 32-byte hex value into bytes."""
    clean = value.strip()
    if not clean.startswith("0x"):
        raise ValueError("bytes32 must start with 0x")
    raw = bytes.fromhex(clean[2:])
    if len(raw) != 32:
        raise ValueError("bytes32 must be exactly 32 bytes")
    return raw

def send_contract_transaction(web3: Web3, account: object, fn_call) -> object:
    tx = fn_call.build_transaction(
        {
            "from": account.address,
            "nonce": web3.eth.get_transaction_count(account.address),
            "gas": 300000,
            "gasPrice": web3.eth.gas_price,
            "chainId": web3.eth.chain_id,
        }
    )
    signed = web3.eth.account.sign_transaction(tx, account.key)
    tx_hash = web3.eth.send_raw_transaction(signed.raw_transaction)
    return web3.eth.wait_for_transaction_receipt(tx_hash)


def compute_credential_hash(first_name: str, last_name: str, dob: str) -> bytes:
    """Match Solidity keccak256(abi.encode(string,string,string))."""
    encoded = encode(["string", "string", "string"], [first_name, last_name, dob])
    return Web3.keccak(encoded)


def upload_identity_to_ipfs(first_name: str, last_name: str, dob: str, ipfs_api: str = IPFS_API_DEFAULT) -> str:
    """Upload identity JSON to IPFS and return CID."""
    payload = json.dumps(
        {
            "firstName": first_name,
            "lastName": last_name,
            "dob": dob,
        }
    )

    response = requests.post(
        f"{ipfs_api}/add",
        files={"file": payload.encode()},
        timeout=20,
    )
    response.raise_for_status()
    data = response.json()
    if "Hash" not in data:
        raise RuntimeError("Unexpected IPFS response: missing Hash")
    return data["Hash"]


def sign_credential_hash(web3: Web3, private_key: str, credential_hash_hex: str) -> str:
    """Create an Ethereum personal_sign style signature for credential hash."""
    _ = parse_bytes32(credential_hash_hex)
    message = encode_defunct(hexstr=credential_hash_hex)
    signed = web3.eth.account.sign_message(message, private_key=private_key)
    signature = signed.signature.hex()
    if signature.startswith("0x"):
        return signature
    return f"0x{signature}"

# TODO: add common functions for