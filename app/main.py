from functions import *

def main():
    inventory = []
    while True:
        print("\n--- Car Lot Manager ---")
        print("1. Add Car")
        print("2. Remove Car")
        print("3. Edit Car")
        print("4. Display Cars")
        print("5. Sort Cars")
        print("6. Sell Car")
        print("7. Show Stats")
        print("0. Exit")
        choice = input("Enter your choice: ")

        if choice == "1":
            add_car(inventory)
        elif choice == "2":
            remove_car(inventory)
        elif choice == "3":
            edit_car(inventory)
        elif choice == "4":
            display_cars(inventory)
        elif choice == "5":
            sort_cars(inventory)
        elif choice == "6":
            sell_car(inventory)
        elif choice == "7":
            show_stats(inventory)
        elif choice == "0":
            print("Goodbye!")
            break
        else:
            print("Invalid choice. Try again.")

if __name__ == "__main__":
    main()
