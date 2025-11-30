import storage


def add_car(inventory):
    try:
        car_id = int(input("ID: "))
        if any(car['id'] == car_id for car in inventory):
            print("Car ID already exists. Choose a different ID.")
            return
        brand = input("Brand: ")
        if not brand.isalpha():
            print("Brand must contain only letters.")
            return
        model = input("Model: ")
        year = int(input("Year: "))
        buy_price = float(input("Buy Price: "))
        if buy_price < 0:
            print("Buy Price cannot be negative.")
            return
        inventory.append({
            "id": car_id,
            "brand": brand,
            "model": model,
            "year": year,
            "buy_price": buy_price,
            "sell_price": None,
            "is_sold": False
        })
        print("Car added.")
        storage.save_inventory(inventory)
    except ValueError:
        print("Invalid input.")

def sell_car(inventory):
    car_id = input("Enter ID to mark as sold: ")
    for car in inventory:
        if str(car["id"]) == car_id:
            if car["is_sold"]:
                print("This car is already sold.")
                return
            try:
                sell_price = float(input("Sell Price: "))
                car["sell_price"] = sell_price
                car["is_sold"] = True
                profit = sell_price - car["buy_price"]
                print(f"Car sold. Profit: {profit:.2f}")
                storage.save_inventory(inventory)
                return
            except ValueError:
                print("Invalid price.")
                return
    print("Car not found.")

def remove_car(inventory):
    car_id = input("Enter ID to remove: ")
    before = len(inventory)
    inventory[:] = [car for car in inventory if str(car['id']) != car_id]
    if len(inventory) < before:
        storage.save_inventory(inventory)
        print("Removed.")
    else:
        print("Car not found.")

def edit_car(inventory):
    car_id = input("Enter ID to edit: ")
    for car in inventory:
        if str(car['id']) == car_id:
            brand = input("New Brand: ")
            if not brand.isalpha():
                print("Brand must contain only letters.")
                return
            car['brand'] = brand
            car['model'] = input("New Model: ")
            try:
                year = int(input("New Year: "))
                buy_price = float(input("New Buy Price: "))
                if buy_price < 0:
                    print("Buy Price cannot be negative.")
                    return
                car['year'] = year
                car['buy_price'] = buy_price
                if car['is_sold']:
                    car['sell_price'] = float(input("New Sell Price: "))
                storage.save_inventory(inventory)
                print("Car updated.")
            except ValueError:
                print("Invalid input.")
            return
    print("Car not found.")

def display_cars(inventory):
    if not inventory:
        print("No cars.")
        return
    for car in inventory:
        status = "Sold" if car["is_sold"] else "Available"
        print(f"{car['id']} | {car['brand']} {car['model']} | {car['year']} | Buy: {car['buy_price']} | Status: {status} | Sell: {car['sell_price']}")

def sort_cars(inventory):
    if not inventory:
        print("No cars to sort.")
        return
    key = input("Sort by (id, brand, year, buy_price, sell_price): ")
    if key not in inventory[0]:
        print("Invalid key.")
        return
    inventory.sort(key=lambda x: x[key] if x[key] is not None else 0)
    storage.save_inventory(inventory)
    print("Sorted.")

def show_stats(inventory):
    if not inventory:
        print("No data.")
        return
    sold = [car for car in inventory if car["is_sold"]]
    total = len(inventory)
    total_profit = sum(c["sell_price"] - c["buy_price"] for c in sold)
    avg_profit = total_profit / len(sold) if sold else 0
    avg_buy = sum(c["buy_price"] for c in inventory) / total

    print(f"Total Cars: {total}")
    print(f"Sold Cars: {len(sold)}")
    print(f"Unsold Cars: {total - len(sold)}")
    print(f"Average Buy Price: {avg_buy:.2f}")
    print(f"Total Profit: {total_profit:.2f}")
    print(f"Average Profit per Sold Car: {avg_profit:.2f}")
