def add_car(inventory):
    try:
        car_id = int(input("ID: "))
        brand = input("Brand: ")
        model = input("Model: ")
        year = int(input("Year: "))
        buy_price = float(input("Buy Price: "))
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
                return
            except ValueError:
                print("Invalid price.")
                return
    print("Car not found.")

def remove_car(inventory):
    car_id = input("Enter ID to remove: ")
    before = len(inventory)
    inventory[:] = [car for car in inventory if str(car['id']) != car_id]
    print("Removed." if len(inventory) < before else "Car not found.")

def edit_car(inventory):
    car_id = input("Enter ID to edit: ")
    for car in inventory:
        if str(car['id']) == car_id:
            car['brand'] = input("New Brand: ")
            car['model'] = input("New Model: ")
            car['year'] = int(input("New Year: "))
            car['buy_price'] = float(input("New Buy Price: "))
            if car['is_sold']:
                car['sell_price'] = float(input("New Sell Price: "))
            print("Car updated.")
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
