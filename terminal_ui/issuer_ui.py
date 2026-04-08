"""Terminal UI for Issuer (Government Body) actions."""

def issue_credential() -> None:
    pass


def revoke_credential() -> None:
    pass


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