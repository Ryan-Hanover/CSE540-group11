"""Terminal UI for Verifier (Election Official) actions."""

def verify_presented_proof() -> None:
    pass


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