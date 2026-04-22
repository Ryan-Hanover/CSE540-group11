"""Terminal UI for Voter (Citizen) actions."""

from web3 import Web3
from common import (
    DID_REGISTRY_ABI,
    connect_chain_with_account,
    prompt_contract_address,
    send_contract_transaction,
    prompt_did_document_hash, 
    prompt_non_empty,
    upload_identity_to_ipfs,
    compute_credential_hash,
    sign_credential_hash,
)

def register_did() -> None:
    # connect to Web3 and get the account that's signing the transaction (connect_chain_with_account)
    context = connect_chain_with_account()

    # prompt for the DIDRegistry contract address and create a contract instance (prompt_contract_address)
    did_address = prompt_contract_address(context.web3, "DIDRegistry")

    # prompt for the DID document hash (or raw text to hash) and compute bytes32 (prompt_did_document_hash)
    document_hash, source_info = prompt_did_document_hash()

    # use web3.py to call the eth.contract() method to get the contract instance
    contract = context.web3.eth.contract(address=did_address, abi=DID_REGISTRY_ABI)

    # send the registerDID transaction using send_contract_transaction
    receipt = send_contract_transaction(
        context.web3,
        context.account,
        contract.functions.registerDID(document_hash),
    )
    
    # print the transaction hash and status after completion
    print("\nDID registration transaction complete.")
    print(f"txHash: {receipt.transactionHash.hex()}")
    print(f"status: {'SUCCESS' if receipt.status == 1 else 'FAILED'}")


def request_credential_package() -> None:
    """Collect identity info, upload to IPFS, and compute credential hash."""
    first_name = prompt_non_empty("First name: ")
    last_name = prompt_non_empty("Last name: ")
    dob = prompt_non_empty("DOB (YYYY-MM-DD): ")

    cid = upload_identity_to_ipfs(first_name, last_name, dob)
    credential_hash = compute_credential_hash(first_name, last_name, dob)

    print("\nShare this package with the Issuer:")
    print(f"credentialHash: 0x{credential_hash.hex()}")
    print(f"ipfsCID:        {cid}")


def sign_for_presentation() -> None:
    """Sign credential hash so verifier can check eligibility proof."""
    rpc_url = prompt_non_empty("RPC URL (for signer context): ")
    private_key = prompt_non_empty("Voter private key (0x...): ", secret=True)
    credential_hash_hex = prompt_non_empty("credentialHash (0x...): ")

    web3 = Web3(Web3.HTTPProvider(rpc_url))
    if not web3.is_connected():
        raise RuntimeError("Could not connect to RPC URL")

    signature_hex = sign_credential_hash(web3, private_key, credential_hash_hex)
    print("\nShare this with the Verifier:")
    print(f"signature: {signature_hex}")


def menu() -> str:
    print("\nVoter UI")
    print("1. Register DID")
    print("2. Request credential package")
    print("3. Sign credential hash for verifier")
    print("4. Exit")
    return input("Choose option: ").strip()


def main() -> None:
    while True:
        try:
            choice = menu()
            if choice == "1":
                register_did()
            elif choice == "2":
                request_credential_package()
            elif choice == "3":
                sign_for_presentation()
            elif choice == "4":
                print("Exiting Voter UI.")
                return
            else:
                print("Invalid choice.")
        except Exception as exc:
            print(f"Error: {exc}")

if __name__ == "__main__":
    main()