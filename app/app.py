from flask import Flask, render_template_string, request, redirect, url_for, jsonify
import json
import os


app = Flask(__name__)
DATA_FILE = os.environ.get('DATA_FILE', 'data/inventory.json')

# Initial dummy data
INITIAL_DATA = [
    {"id": 1, "make": "Toyota", "model": "Camry", "year": 2020, "price": 24090, "status": "available"},
    {"id": 2, "make": "Honda", "model": "Civic", "year": 2021, "price": 22080, "status": "available"},
    {"id": 3, "make": "Ford", "model": "Mustang", "year": 2022, "price": 35000, "status": "available"},
    {"id": 4, "make": "Tesla", "model": "Model 3", "year": 2023, "price": 42000, "status": "available"},
    {"id": 5, "make": "BMW", "model": "X5", "year": 2022, "price": 58000, "status": "available"}
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
    available_cars = [car for car in inventory if car.get('status', 'available') == 'available']
    sold_cars = [car for car in inventory if car.get('status', 'available') == 'sold']
    total_value = sum(car['price'] for car in available_cars)
    
    html = """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Car Lot Manager</title>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            body { 
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                min-height: 100vh;
                padding: 20px;
            }
            .container {
                max-width: 1200px;
                margin: 0 auto;
                background: white;
                border-radius: 12px;
                box-shadow: 0 10px 40px rgba(0,0,0,0.2);
                overflow: hidden;
            }
            .header {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
                padding: 30px;
                text-align: center;
            }
            .header h1 {
                font-size: 2.5em;
                margin-bottom: 10px;
            }
            .stats {
                display: flex;
                justify-content: space-around;
                padding: 20px;
                background: #f8f9fa;
                border-bottom: 2px solid #e9ecef;
            }
            .stat-box {
                text-align: center;
                padding: 15px;
            }
            .stat-number {
                font-size: 2em;
                font-weight: bold;
                color: #667eea;
            }
            .stat-label {
                color: #6c757d;
                font-size: 0.9em;
                margin-top: 5px;
            }
            .content {
                padding: 30px;
            }
            .section {
                margin-bottom: 40px;
            }
            .section-title {
                font-size: 1.5em;
                color: #333;
                margin-bottom: 20px;
                padding-bottom: 10px;
                border-bottom: 3px solid #667eea;
            }
            .form-grid {
                display: grid;
                grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
                gap: 15px;
                margin-bottom: 20px;
            }
            .form-group {
                display: flex;
                flex-direction: column;
            }
            label {
                font-weight: 600;
                color: #495057;
                margin-bottom: 5px;
                font-size: 0.9em;
            }
            input {
                padding: 10px;
                border: 2px solid #e9ecef;
                border-radius: 6px;
                font-size: 1em;
                transition: border-color 0.3s;
            }
            input:focus {
                outline: none;
                border-color: #667eea;
            }
            .btn {
                padding: 12px 30px;
                border: none;
                border-radius: 6px;
                font-size: 1em;
                font-weight: 600;
                cursor: pointer;
                transition: all 0.3s;
                text-decoration: none;
                display: inline-block;
            }
            .btn-primary {
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                color: white;
            }
            .btn-primary:hover {
                transform: translateY(-2px);
                box-shadow: 0 5px 15px rgba(102, 126, 234, 0.4);
            }
            .btn-danger {
                background: #dc3545;
                color: white;
                padding: 8px 15px;
                font-size: 0.85em;
            }
            .btn-danger:hover {
                background: #c82333;
            }
            .btn-success {
                background: #28a745;
                color: white;
                padding: 8px 15px;
                font-size: 0.85em;
            }
            .btn-success:hover {
                background: #218838;
            }
            table {
                width: 100%;
                border-collapse: collapse;
                margin-top: 20px;
                background: white;
            }
            th {
                background: #f8f9fa;
                color: #495057;
                font-weight: 600;
                padding: 15px;
                text-align: left;
                border-bottom: 2px solid #dee2e6;
            }
            td {
                padding: 15px;
                border-bottom: 1px solid #e9ecef;
            }
            tr:hover {
                background: #f8f9fa;
            }
            .status-badge {
                padding: 5px 12px;
                border-radius: 20px;
                font-size: 0.85em;
                font-weight: 600;
            }
            .status-available {
                background: #d4edda;
                color: #155724;
            }
            .status-sold {
                background: #f8d7da;
                color: #721c24;
            }
            .action-buttons {
                display: flex;
                gap: 10px;
            }
            .empty-state {
                text-align: center;
                padding: 40px;
                color: #6c757d;
            }
            .footer {
                text-align: center;
                padding: 20px;
                background: #f8f9fa;
                color: #6c757d;
                font-size: 0.9em;
            }
            @media (max-width: 768px) {
                .header h1 { font-size: 1.8em; }
                .stats { flex-direction: column; }
                .form-grid { grid-template-columns: 1fr; }
                table { font-size: 0.9em; }
                .action-buttons { flex-direction: column; }
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🚗 Car Lot Manager</h1>
                <p>Manage your inventory with ease</p>
            </div>
            
            <div class="stats">
                <div class="stat-box">
                    <div class="stat-number">{{ available_cars|length }}</div>
                    <div class="stat-label">Available Cars</div>
                </div>
                <div class="stat-box">
                    <div class="stat-number">{{ sold_cars|length }}</div>
                    <div class="stat-label">Sold Cars</div>
                </div>
                <div class="stat-box">
                    <div class="stat-number">${{ "{:,}".format(total_value) }}</div>
                    <div class="stat-label">Total Inventory Value</div>
                </div>
            </div>
            
            <div class="content">
                <div class="section">
                    <h2 class="section-title">➕ Add New Car</h2>
                    <form action="/add" method="POST">
                        <div class="form-grid">
                            <div class="form-group">
                                <label>Make</label>
                                <input type="text" name="make" placeholder="e.g., Toyota" required>
                            </div>
                            <div class="form-group">
                                <label>Model</label>
                                <input type="text" name="model" placeholder="e.g., Camry" required>
                            </div>
                            <div class="form-group">
                                <label>Year</label>
                                <input type="number" name="year" placeholder="e.g., 2023" min="1900" max="2030" required>
                            </div>
                            <div class="form-group">
                                <label>Price ($)</label>
                                <input type="number" name="price" placeholder="e.g., 25000" min="0" required>
                            </div>
                        </div>
                        <button type="submit" class="btn btn-primary">Add Car to Inventory</button>
                    </form>
                </div>
                
                <div class="section">
                    <h2 class="section-title">📋 Available Inventory</h2>
                    {% if available_cars %}
                    <table>
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Make</th>
                                <th>Model</th>
                                <th>Year</th>
                                <th>Price</th>
                                <th>Status</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                            {% for car in available_cars %}
                            <tr>
                                <td><strong>#{{ car.id }}</strong></td>
                                <td>{{ car.make }}</td>
                                <td>{{ car.model }}</td>
                                <td>{{ car.year }}</td>
                                <td><strong>${{ "{:,}".format(car.price) }}</strong></td>
                                <td><span class="status-badge status-available">Available</span></td>
                                <td>
                                    <div class="action-buttons">
                                        <form action="/sell/{{ car.id }}" method="POST" style="display:inline;">
                                            <button type="submit" class="btn btn-success">Sell</button>
                                        </form>
                                        <form action="/remove/{{ car.id }}" method="POST" style="display:inline;" onsubmit="return confirm('Are you sure you want to remove this car?');">
                                            <button type="submit" class="btn btn-danger">Remove</button>
                                        </form>
                                    </div>
                                </td>
                            </tr>
                            {% endfor %}
                        </tbody>
                    </table>
                    {% else %}
                    <div class="empty-state">
                        <p>No cars available in inventory. Add some cars to get started!</p>
                    </div>
                    {% endif %}
                </div>
                
                {% if sold_cars %}
                <div class="section">
                    <h2 class="section-title">✅ Sold Cars</h2>
                    <table>
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Make</th>
                                <th>Model</th>
                                <th>Year</th>
                                <th>Price</th>
                                <th>Status</th>
                            </tr>
                        </thead>
                        <tbody>
                            {% for car in sold_cars %}
                            <tr>
                                <td><strong>#{{ car.id }}</strong></td>
                                <td>{{ car.make }}</td>
                                <td>{{ car.model }}</td>
                                <td>{{ car.year }}</td>
                                <td><strong>${{ "{:,}".format(car.price) }}</strong></td>
                                <td><span class="status-badge status-sold">Sold</span></td>
                            </tr>
                            {% endfor %}
                        </tbody>
                    </table>
                </div>
                {% endif %}
            </div>
            
            <div class="footer">
                <p>Car Lot Manager v1.0 | Data stored in: {{ data_file }}</p>
            </div>
        </div>
    </body>
    </html>
    """
    return render_template_string(html, inventory=inventory, available_cars=available_cars, 
                                 sold_cars=sold_cars, total_value=total_value, data_file=DATA_FILE)

@app.route('/add', methods=['POST'])
def add_car():
    inventory = load_data()
    new_id = max([c['id'] for c in inventory] or [0]) + 1
    new_car = {
        "id": new_id,
        "make": request.form['make'],
        "model": request.form['model'],
        "year": int(request.form['year']),
        "price": int(request.form['price']),
        "status": "available"
    }
    inventory.append(new_car)
    save_data(inventory)
    return redirect(url_for('index'))

@app.route('/sell/<int:car_id>', methods=['POST'])
def sell_car(car_id):
    inventory = load_data()
    for car in inventory:
        if car['id'] == car_id:
            car['status'] = 'sold'
            break
    save_data(inventory)
    return redirect(url_for('index'))

@app.route('/remove/<int:car_id>', methods=['POST'])
def remove_car(car_id):
    inventory = load_data()
    inventory = [car for car in inventory if car['id'] != car_id]
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
