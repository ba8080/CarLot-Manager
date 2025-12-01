from flask import Flask, render_template_string, request, redirect, url_for, jsonify
import json
import os

app = Flask(__name__)
DATA_FILE = os.environ.get('DATA_FILE', 'data/inventory.json')

# Initial dummy data
INITIAL_DATA = [
    {"id": 1, "make": "Toyota", "model": "Camry", "year": 2024, "price": 24090},
    {"id": 2, "make": "Honda", "model": "Civic", "year": 2005, "price": 22080},
    {"id": 3, "make": "Ford", "model": "Mustang", "year": 2028, "price": 35000}
]

def load_data():
    if not os.path.exists(DATA_FILE):
        # Ensure directory exists
        os.makedirs(os.path.dirname(DATA_FILE), exist_ok=True)
        save_data(INITIAL_DATA)
        return INITIAL_DATA
    try:
        with open(DATA_FILE, 'r') as f:
            return json.load(f)
    except (json.JSONDecodeError, IOError):
        return INITIAL_DATA

def save_data(data):
    os.makedirs(os.path.dirname(DATA_FILE), exist_ok=True)
    with open(DATA_FILE, 'w') as f:
        json.dump(data, f, indent=4)

@app.route('/')
def index():
    inventory = load_data()
    html = """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Car Lot Manager</title>
        <style>
            body { font-family: sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
            table { width: 100%; border-collapse: collapse; margin-top: 20px; }
            th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
            th { background-color: #f2f2f2; }
            .form-group { margin-bottom: 15px; }
            label { display: block; margin-bottom: 5px; }
            input { padding: 8px; width: 100%; box-sizing: border-box; }
            button { padding: 10px 15px; background-color: #4CAF50; color: white; border: none; cursor: pointer; }
            button:hover { background-color: #45a049; }
        </style>
    </head>
    <body>
        <h1>Car Lot Manager</h1>
        
        <h2>Add New Car</h2>
        <form action="/add" method="POST">
            <div class="form-group">
                <label>Make:</label>
                <input type="text" name="make" required>
            </div>
            <div class="form-group">
                <label>Model:</label>
                <input type="text" name="model" required>
            </div>
            <div class="form-group">
                <label>Year:</label>
                <input type="number" name="year" required>
            </div>
            <div class="form-group">
                <label>Price:</label>
                <input type="number" name="price" required>
            </div>
            <button type="submit">Add Car</button>
        </form>

        <h2>Inventory</h2>
        <table>
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Make</th>
                    <th>Model</th>
                    <th>Year</th>
                    <th>Price</th>
                </tr>
            </thead>
            <tbody>
                {% for car in inventory %}
                <tr>
                    <td>{{ car.id }}</td>
                    <td>{{ car.make }}</td>
                    <td>{{ car.model }}</td>
                    <td>{{ car.year }}</td>
                    <td>${{ car.price }}</td>
                </tr>
                {% endfor %}
            </tbody>
        </table>
        
        <p><small>Data stored in: {{ data_file }}</small></p>
    </body>
    </html>
    """
    return render_template_string(html, inventory=inventory, data_file=DATA_FILE)

@app.route('/add', methods=['POST'])
def add_car():
    inventory = load_data()
    new_id = max([c['id'] for c in inventory] or [0]) + 1
    new_car = {
        "id": new_id,
        "make": request.form['make'],
        "model": request.form['model'],
        "year": int(request.form['year']),
        "price": int(request.form['price'])
    }
    inventory.append(new_car)
    save_data(inventory)
    return redirect(url_for('index'))

@app.route('/api/inventory')
def api_inventory():
    return jsonify(load_data())

@app.route('/health')
def health():
    return jsonify({"status": "healthy"}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
