# CarLot-Manager
Car Lot Manager is an application used for managing car lots with a complete deployment pipeline.

## 3. Version Control
The project is stored in a GitHub repository with organized subfolders for each project component:
- Python code
- Website
- Docker file
- AWS Beanstalk
- AWS CloudFormation

## Project Structure
```
CarLot-Manager/
├── python/                 # Core Python application logic
│   ├── models/            # Data models and database schemas
│   ├── services/          # Business logic and services
│   ├── utils/             # Utility functions and helpers
│   └── main.py            # Main application entry point
├── website/               # Web interface (Streamlit)
│   ├── app.py             # Main Streamlit application
│   ├── pages/             # Multi-page application components
│   └── static/            # Static assets (CSS, images)
├── docker/                # Docker containerization
│   └── Dockerfile         # Container build instructions
├── aws-beanstalk/         # AWS Elastic Beanstalk deployment
│   ├── .ebextensions/     # Beanstalk configuration files
│   └── application.py     # Beanstalk application wrapper
├── aws-cloudformation/    # Infrastructure as Code
│   ├── template.yaml      # CloudFormation template
│   └── parameters.json    # Template parameters
└── README.md              # Project documentation
```

## File Descriptions

### Python Application (`/python/`)
- **main.py**: Entry point for the Python application, initializes the car lot management system
- **models/**: Contains data models for cars, lots, customers, and transactions
- **services/**: Business logic for inventory management, sales processing, and reporting
- **utils/**: Helper functions for data validation, formatting, and common operations

### Website (`/website/`)
- **app.py**: Streamlit web application providing user interface for car lot management
- **pages/**: Individual page components for different features (inventory, sales, reports)
- **static/**: CSS stylesheets and image assets for the web interface

### Docker (`/docker/`)
- **Dockerfile**: Container definition using Python 3.10-slim base image, installs Streamlit and exposes port 8501

### AWS Beanstalk (`/aws-beanstalk/`)
- **.ebextensions/**: Configuration files for Beanstalk environment setup
- **application.py**: Application wrapper optimized for Beanstalk deployment

### AWS CloudFormation (`/aws-cloudformation/`)
- **template.yaml**: Infrastructure template defining AWS resources (EC2, RDS, S3, etc.)
- **parameters.json**: Environment-specific parameters for template deployment

## Python App Structure
The Python application follows a modular architecture:
- **Models**: Define data structures and database interactions
- **Services**: Implement business logic and core functionality
- **Utils**: Provide reusable utility functions
- **Main**: Orchestrates application startup and configuration

## Code Documentation
All functions include docstrings describing:
- Purpose and functionality
- Input parameters and types
- Return values and types
- Usage examples where applicable

## Docker Deployment
To deploy the application using Docker:

1. Build the Docker image:
```bash
docker build -f docker/Dockerfile -t carlot-streamlit .
```

2. Run the container:
```bash
docker run -d -p 8501:8501 --name carlot_app carlot-streamlit
``` 