# Car Lot Manager

A simple command-line based inventory management system for a car dealership. This Python application allows users to add, edit, sell, remove, sort, and display cars, as well as view sales statistics.

## 📁 Project Folder Structure
```
car-lot-manager/
├── main.py # Entry point of the application, handles the user interface loop
├── functions.py # Contains all core business logic and utility functions
```

## 📌 Purpose and Role of Each File

### `main.py`

- Launches the car lot manager application.
- Presents a menu-driven interface for the user.
- Uses functions imported from `functions.py` to perform operations.
- Keeps track of the car inventory in memory during runtime.

### `functions.py`

- Implements the following key functions that operate on the `inventory` list:
  - `add_car()` - Adds a new car to inventory.
  - `remove_car()` - Removes a car based on its ID.
  - `edit_car()` - Edits an existing car’s details.
  - `display_cars()` - Displays all cars in the inventory.
  - `sort_cars()` - Sorts the inventory by a given field.
  - `sell_car()` - Marks a car as sold and records the sell price.
  - `show_stats()` - Displays summary statistics like total cars, profits, averages, etc.

## 🧠 Folder Structure for Python App

Since the project is small, all files reside in the root directory. As it scales, you could adopt a structure like:
```
car-lot-manager/
├── src/
│ ├── init.py
│ ├── main.py
│ └── functions.py
├── tests/
│ └── test_functions.py # (Optional) unit tests
├── README.md
```

## 🧾 Function Documentation

Each function in `functions.py` operates on the `inventory` list:

### `add_car(inventory)`
Prompts user for car details and appends a dictionary to `inventory`.

### `remove_car(inventory)`
Removes a car by matching its ID. Informs if the car was not found.

### `edit_car(inventory)`
Allows editing of a car’s details by ID. If sold, also allows updating the sell price.

### `display_cars(inventory)`
Prints a formatted list of all cars including status (Available/Sold).

### `sort_cars(inventory)`
Sorts the list of cars by user-specified key (e.g., `id`, `year`, `brand`, etc.).

### `sell_car(inventory)`
Marks a car as sold and calculates profit. Prevents re-selling already sold cars.

### `show_stats(inventory)`
Displays total cars, number sold/unsold, average buy price, total and average profit.

---

## 🧪 Example Use

After running `main.py`, you can interact via a menu:

--- Car Lot Manager ---

Add Car

Remove Car

Edit Car

Display Cars

Sort Cars

Sell Car

Show Stats

Exit


---

## ✅ Requirements

- Python 3.6 or above
- No third-party libraries required

---


## � How to Run the Project Locally

### 1. Run the Command-Line Application

1. Open a terminal and navigate to the project directory:
   ```sh
   cd path/to/car-lot-manager/app
   ```
2. Run the main Python script:
   ```sh
   python main.py
   ```
3. Follow the on-screen menu to add, edit, remove, sort, sell, and display cars.

### 2. Run the Web Application (Streamlit)

1. Make sure you have Streamlit installed. If not, install it with:
   ```sh
   pip install streamlit
   ```
2. Navigate to the `website` folder:
   ```sh
   cd path/to/car-lot-manager/website
   ```
3. Start the web app:
   ```sh
   streamlit run app.py
   ```
4. The app will open in your browser. Use the sidebar to navigate between features.

---


---

## 🛡️ Error Handling

Both the command-line and web applications are designed to handle invalid input and errors gracefully:

- If you enter non-numeric values where numbers are expected (e.g., car ID, year, prices), the app will display an error message and prompt you to try again.
- Attempting to sell or remove a car that does not exist will show a clear message.
- The web app disables actions or shows info messages when no cars are available for a given operation.
- All user actions are validated to prevent crashes and provide helpful feedback.

---

This app does not persist data between runs (in-memory only). For persistence, you could extend it with a CSV or SQLite backend.

