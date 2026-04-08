"""Terminal UI for Voter (Citizen) actions."""

from web3 import Web3

def register_did() -> None:
    pass


def request_credential_package() -> None:
    pass


def sign_for_presentation() -> None:
    pass


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