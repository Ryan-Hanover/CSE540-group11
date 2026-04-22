"""Terminal UI for Issuer (Government Body) actions."""

from common import (
    ISSUER_ABI,
    connect_chain_with_account,
    parse_bytes32,
    prompt_contract_address,
    prompt_non_empty,
    send_contract_transaction,
)

def issue_credential() -> None:
    """Issue an age credential to a voter wallet."""
    context = connect_chain_with_account()
    issuer_address = prompt_contract_address(context.web3, "Issuer")

    credential_hash = parse_bytes32(prompt_non_empty("credentialHash (0x...): "))
    cid = prompt_non_empty("ipfsCID: ")
    voter_wallet = context.web3.to_checksum_address(prompt_non_empty("Voter wallet address: "))

    contract = context.web3.eth.contract(address=issuer_address, abi=ISSUER_ABI)
    receipt = send_contract_transaction(
        context.web3,
        context.account,
        contract.functions.issueCredential(credential_hash, cid, voter_wallet),
    )

    print("\nIssue transaction complete.")
    print(f"txHash: {receipt.transactionHash.hex()}")
    print(f"status: {'SUCCESS' if receipt.status == 1 else 'FAILED'}")


def revoke_credential() -> None:
    """Revoke an existing age credential."""
    context = connect_chain_with_account()
    issuer_address = prompt_contract_address(context.web3, "Issuer")

    credential_hash = parse_bytes32(prompt_non_empty("credentialHash (0x...): "))

    contract = context.web3.eth.contract(address=issuer_address, abi=ISSUER_ABI)
    receipt = send_contract_transaction(
        context.web3,
        context.account,
        contract.functions.revokeCredential(credential_hash),
    )

    print("\nRevoke transaction complete.")
    print(f"txHash: {receipt.transactionHash.hex()}")
    print(f"status: {'SUCCESS' if receipt.status == 1 else 'FAILED'}")


def menu() -> str:
    print("\nIssuer UI")
    print("1. Issue credential")
    print("2. Revoke credential")
    print("3. Exit")
    return input("Choose option: ").strip()


def main() -> None:
    while True:
        try:
            choice = menu()
            if choice == "1":
                issue_credential()
            elif choice == "2":
                revoke_credential()
            elif choice == "3":
                print("Exiting Issuer UI.")
                return
            else:
                print("Invalid choice.")
        except Exception as exc:
            print(f"Error: {exc}")


if __name__ == "__main__":
    main()