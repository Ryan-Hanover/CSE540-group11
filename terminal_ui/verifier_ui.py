"""Terminal UI for Verifier (Election Official) actions."""

from common import (
    VERIFIER_ABI,
    connect_chain_with_account,
    parse_bytes32,
    parse_signature,
    prompt_contract_address,
    prompt_non_empty,
)

def verify_presented_proof() -> None:
    """Verify presented credential proof and print ALLOW or DENY."""
    context = connect_chain_with_account()
    verifier_address = prompt_contract_address(context.web3, "Verifier")

    credential_hash = parse_bytes32(prompt_non_empty("credentialHash (0x...): "))
    cid = prompt_non_empty("ipfsCID: ")
    signature = parse_signature(prompt_non_empty("signature (0x...): "))

    contract = context.web3.eth.contract(address=verifier_address, abi=VERIFIER_ABI)

    is_valid = contract.functions.verify(credential_hash, cid, signature).call(
        {"from": context.account.address}
    )

    if is_valid:
        print("ALLOW")
    else:
        print("DENY")


def menu() -> str:
    print("\nVerifier UI")
    print("1. Verify presented proof")
    print("2. Exit")
    return input("Choose option: ").strip()


def main() -> None:
    while True:
        try:
            choice = menu()
            if choice == "1":
                verify_presented_proof()
            elif choice == "2":
                print("Exiting Verifier UI.")
                return
            else:
                print("Invalid choice.")
        except Exception as exc:
            print(f"DENY ({exc})")


if __name__ == "__main__":
    main()