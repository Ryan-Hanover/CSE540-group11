"""Compile and deploy DIDRegistry, Issuer, Verifier to a local RPC.
"""
from __future__ import annotations
import argparse
import json
from pathlib import Path

import solcx
from web3 import Web3

REPO_ROOT = Path(__file__).resolve().parent.parent
CONTRACTS_DIR = REPO_ROOT / "contracts"
OZ_DIR = REPO_ROOT / "tools" / "node_modules" / "@openzeppelin" / "contracts"
SOLC_VERSION = "0.8.30"


def compile_all() -> dict:
    sources = {
        "DIDRegistry.sol": {"content": (CONTRACTS_DIR / "DIDRegistry.sol").read_text()},
        "AgeVerificationIssuer.sol": {"content": (CONTRACTS_DIR / "AgeVerificationIssuer.sol").read_text()},
        "AgeVerificationVerifier.sol": {"content": (CONTRACTS_DIR / "AgeVerificationVerifier.sol").read_text()},
    }
    std = {
        "language": "Solidity",
        "sources": sources,
        "settings": {
            "remappings": [f"@openzeppelin/contracts/={OZ_DIR}/"],
            "outputSelection": {"*": {"*": ["abi", "evm.bytecode.object"]}},
            "optimizer": {"enabled": True, "runs": 200},
            "evmVersion": "shanghai",
        },
    }
    return solcx.compile_standard(std, solc_version=SOLC_VERSION, allow_paths=str(REPO_ROOT))


def pick(compiled: dict, source: str, name: str) -> tuple[list, str]:
    c = compiled["contracts"][source][name]
    return c["abi"], c["evm"]["bytecode"]["object"]


def deploy(web3: Web3, deployer_key: str, abi: list, bytecode: str, *args) -> tuple[str, object]:
    acct = web3.eth.account.from_key(deployer_key)
    contract = web3.eth.contract(abi=abi, bytecode=bytecode)
    tx = contract.constructor(*args).build_transaction({
        "from": acct.address,
        "nonce": web3.eth.get_transaction_count(acct.address),
        "gas": 3_000_000,
        "gasPrice": web3.eth.gas_price,
        "chainId": web3.eth.chain_id,
    })
    signed = web3.eth.account.sign_transaction(tx, acct.key)
    tx_hash = web3.eth.send_raw_transaction(signed.raw_transaction)
    receipt = web3.eth.wait_for_transaction_receipt(tx_hash)
    if receipt.status != 1:
        raise RuntimeError(f"Deploy failed: {receipt}")
    return receipt.contractAddress, receipt


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--rpc", default="http://127.0.0.1:8545")
    parser.add_argument("--authority-key", required=True, help="0x-prefixed private key for the Issuer/Verifier owner")
    parser.add_argument("--voter-key", required=True, help="0x-prefixed private key for the voter")
    parser.add_argument("--out", default=str(REPO_ROOT / "tools" / "deployed.json"))
    args = parser.parse_args()

    web3 = Web3(Web3.HTTPProvider(args.rpc))
    if not web3.is_connected():
        raise SystemExit(f"Cannot reach RPC {args.rpc}")

    authority = web3.eth.account.from_key(args.authority_key)
    voter = web3.eth.account.from_key(args.voter_key)
    print(f"Authority: {authority.address}")
    print(f"Voter:     {voter.address}")

    print("Compiling...")
    compiled = compile_all()

    did_abi, did_bc = pick(compiled, "DIDRegistry.sol", "DIDRegistry")
    iss_abi, iss_bc = pick(compiled, "AgeVerificationIssuer.sol", "Issuer")
    ver_abi, ver_bc = pick(compiled, "AgeVerificationVerifier.sol", "Verifier")

    print("Deploying DIDRegistry...")
    did_addr, _ = deploy(web3, args.authority_key, did_abi, did_bc)
    print(f"  {did_addr}")

    print("Deploying Issuer...")
    iss_addr, _ = deploy(web3, args.authority_key, iss_abi, iss_bc, did_addr)
    print(f"  {iss_addr}")

    print("Deploying Verifier...")
    ver_addr, _ = deploy(web3, args.authority_key, ver_abi, ver_bc, iss_addr, did_addr)
    print(f"  {ver_addr}")

    out = {
        "rpc": args.rpc,
        "authority": {"address": authority.address, "private_key": args.authority_key},
        "voter": {"address": voter.address, "private_key": args.voter_key},
        "didRegistry": did_addr,
        "issuer": iss_addr,
        "verifier": ver_addr,
    }
    Path(args.out).write_text(json.dumps(out, indent=2))
    print(f"\nWrote {args.out}")


if __name__ == "__main__":
    main()
