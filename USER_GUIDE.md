# Car Lot Manager - User Guide

## Overview
Car Lot Manager is a simple web application to manage a car inventory. It allows you to view, add, and manage cars. Data is persisted to a file system, ensuring it survives application restarts.

## Features
- **View Inventory**: See a list of all cars in the lot.
- **Add Car**: Add a new car with details (Make, Model, Year, Price).
- **Persistence**: Data is saved to a shared NFS storage.

## How to Use

### Accessing the App
Open the Load Balancer URL provided in the deployment logs (e.g., `http://carlot-alb-....elb.amazonaws.com/`).

### Viewing Inventory
The home page displays the current inventory table with columns: ID, Make, Model, Year, Price.
You will see some initial dummy data (Toyota Camry, Honda Civic, etc.).

### Adding a Car
1. On the home page, find the "Add New Car" form.
2. Enter the details:
   - **Make**: e.g., Tesla
   - **Model**: e.g., Model 3
   - **Year**: e.g., 2023
   - **Price**: e.g., 45000
3. Click **Add Car**.
4. The new car will appear in the Inventory table.

### API Access
You can also access the raw JSON data via the API:
- Endpoint: `/api/inventory`
- Method: `GET`
- Response: JSON array of cars.

## Data Persistence
The application uses a JSON file stored on a Persistent Volume (NFS) to save data. This means if the application pods are restarted or redeployed, your data remains intact.
