import streamlit as st

if 'inventory' not in st.session_state:
    st.session_state.inventory = []

inventory = st.session_state.inventory

def display_inventory():
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
    st.subheader("➕ Add Car")
    with st.form("add_car_form"):
        car_id = st.number_input("Car ID", step=1)
        brand = st.text_input("Brand")
        model = st.text_input("Model")
        year = st.number_input("Year", step=1)
        buy_price = st.number_input("Buy Price", step=100)
        submitted = st.form_submit_button("Add")
        if submitted:
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

st.title("🚗 Car Lot Manager")
menu = st.sidebar.selectbox("Navigate", ["Display", "Add Car", "Sell Car", "Stats"])

if menu == "Display":
    display_inventory()
elif menu == "Add Car":
    add_car()
elif menu == "Sell Car":
    sell_car()
elif menu == "Stats":
    show_stats()
