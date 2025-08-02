import streamlit as st


# Session state for inventory and welcome screen
if 'inventory' not in st.session_state:
    st.session_state.inventory = []
if 'welcome_shown' not in st.session_state:
    st.session_state.welcome_shown = False

inventory = st.session_state.inventory

def display_inventory():
    """
    Display all cars in the inventory with their details and status.
    """
    st.subheader("📋 Inventory")
    if not inventory:
        st.info("No cars in inventory.")
        return

    for car in inventory:
        st.write(f"**ID {car['id']}** - {car['brand']} {car['model']} ({car['year']})")
        st.write(f"🛒 Buy Price: {car['buy_price']}")
        if car["is_sold"]:
            st.write(f"✅ Sold at: {car['sell_price']} | 💰 Profit: {car['sell_price'] - car['buy_price']:.2f}")
        else:
            st.write("❌ Not yet sold")
        st.markdown("---")

def add_car():
    """
    Add a new car to the inventory using a Streamlit form.
    """
    st.subheader("➕ Add Car")
    with st.form("add_car_form"):
        car_id = st.number_input("Car ID", step=1)
        brand = st.text_input("Brand")
        model = st.text_input("Model")
        year = st.number_input("Year", step=1)
        buy_price = st.number_input("Buy Price", step=100)
        submitted = st.form_submit_button("Add")
        if submitted:
            if not brand.isalpha():
                st.error("Brand must contain only letters.")
            elif buy_price < 0:
                st.error("Buy Price cannot be negative.")
            else:
                inventory.append({
                    "id": int(car_id),
                    "brand": brand,
                    "model": model,
                    "year": int(year),
                    "buy_price": float(buy_price),
                    "sell_price": None,
                    "is_sold": False
                })
                st.success("Car added successfully!")

def sell_car():
    """
    Mark a car as sold by selecting its ID and entering the sell price.
    """
    st.subheader("💵 Sell Car")
    available_ids = [car['id'] for car in inventory if not car["is_sold"]]
    if not available_ids:
        st.info("No available cars to sell.")
        return
    selected_id = st.selectbox("Choose Car ID to sell", available_ids)
    sell_price = st.number_input("Sell Price", step=100)
    if st.button("Sell"):
        for car in inventory:
            if car["id"] == selected_id:
                car["sell_price"] = float(sell_price)
                car["is_sold"] = True
                st.success(f"Car {selected_id} sold. Profit: {car['sell_price'] - car['buy_price']:.2f}")
                return

def show_stats():
    """
    Display statistics about the car inventory, including totals and profits.
    """
    st.subheader("📊 Stats")
    if not inventory:
        st.info("No data.")
        return
    sold = [car for car in inventory if car["is_sold"]]
    total = len(inventory)
    total_profit = sum(c["sell_price"] - c["buy_price"] for c in sold)
    avg_profit = total_profit / len(sold) if sold else 0
    avg_buy = sum(c["buy_price"] for c in inventory) / total

    st.metric("Total Cars", total)
    st.metric("Sold Cars", len(sold))
    st.metric("Avg Buy Price", f"{avg_buy:.2f}")
    st.metric("Total Profit", f"{total_profit:.2f}")
    st.metric("Avg Profit", f"{avg_profit:.2f}")



# Show welcome screen only on first visit
if not st.session_state.welcome_shown:
    st.title("🚗 Car Lot Manager")
    st.markdown("""
    <div style='text-align:center;'>
    <h2>Welcome to Car Lot Manager!</h2>
    <p>Manage your car inventory easily.</p>
    </div>
    """, unsafe_allow_html=True)
    st.session_state.welcome_shown = True
else:
    st.title("🚗 Car Lot Manager")

menu = st.sidebar.selectbox("Navigate", ["Display", "Add Car", "Sell Car", "Sort Cars", "Stats"])


def sort_cars():
    """
    Sort the inventory by a selected field and order, then display the sorted list.
    """
    st.subheader("🔀 Sort Cars")
    if not inventory:
        st.info("No cars to sort.")
        return
    sort_options = ["id", "brand", "model", "year", "buy_price", "sell_price", "is_sold"]
    key = st.selectbox("Sort by", sort_options)
    reverse = st.checkbox("Descending order", value=False)
    if st.button("Sort"):
        try:
            inventory.sort(key=lambda x: (x[key] if x[key] is not None else 0), reverse=reverse)
            st.success(f"Sorted by {key} ({'descending' if reverse else 'ascending'})!")
        except Exception as e:
            st.error(f"Error sorting: {e}")
    display_inventory()

if menu == "Display":
    display_inventory()
elif menu == "Add Car":
    add_car()
elif menu == "Sell Car":
    sell_car()
elif menu == "Sort Cars":
    sort_cars()
elif menu == "Stats":
    show_stats()
