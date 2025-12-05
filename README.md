# DevOps Final Project - Car Lot Manager


**Student Name:** Ori Bramy + Liel Levi 

## Project Description
This project is a fully automated DevOps solution for deploying a Python web application (Car Lot Manager) to a Kubernetes cluster on AWS. It demonstrates Infrastructure as Code (Terraform), Configuration Management (Ansible), Container Orchestration (Kubernetes/Helm), and CI/CD (GitHub Actions).

## Repository URL
[LINK TO GITHUB REPOSITORY]

## Instructions for Evaluator

### 1. Prerequisites
You do not need to install any tools locally if you use the GitHub Actions pipeline. The pipeline handles everything.
If you wish to run locally, you will need:
- Terraform v1.5+
- Ansible v2.10+
- Docker
- kubectl
- Helm

### 2. AWS Credentials & Secrets
To deploy this project, you must configure the following **GitHub Secrets** in the repository settings:

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `AWS_ACCESS_KEY_ID` | AWS Access Key | `AKIA...` |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Key | `wJalr...` |
| `AWS_SESSION_TOKEN` | AWS Token Key | `wJalr...` |

| `DOCKERHUB_USERNAME` | Docker Hub Username | `azexkush` |
| `DOCKERHUB_TOKEN` | Docker Hub Access Token | `dckr_pat_...` |
docker on readme
> **Note**: The pipeline pushes to `azexkush/car-lot-manager`. Ensure you have push access.

### 3. Triggering Deployment
1. Go to the **Actions** tab in the GitHub repository.
2. Select the **CI/CD Pipeline** workflow on the left.
3. Click **Run workflow** (select `main` branch).
4. Wait for the pipeline to complete (approx. 10-15 minutes).

### 4. Accessing the Application
Once the pipeline completes successfully, check the logs of the **Final Output** step in the `deploy` job.
It will display the Load Balancer URL:
```
Application deployed successfully!
Access it at: http://carlot-alb-123456789.us-east-1.elb.amazonaws.com/
```
Click the link to access the Car Lot Manager application.

## Technical Documentation

### Architecture
- **Infrastructure**: 3 EC2 instances (1 Master, 2 Workers) + Application Load Balancer (ALB).
- **Configuration**: Ansible installs Docker, Kubeadm, and configures the K8s cluster and NFS.
- **Application**: Flask-based Python web app with JSON file persistence (stored on NFS).
- **Deployment**: Helm chart deploys the app as a Deployment + Service (NodePort) exposed via ALB.

### Pipeline Stages
1. **Test**: Runs unit tests for the Python app.
2. **Terraform Apply**: Provisions AWS infrastructure.
3. **Ansible Configure**: Configures K8s cluster and NFS.
4. **Helm Deploy**: Deploys the application to K8s.

### Troubleshooting
- **Pipeline Fails at Terraform**: Check AWS credentials and permissions.
- **Pipeline Fails at Ansible**: Check SSH connectivity to EC2 instances (Security Groups).
- **App not accessible**: Wait a few minutes for the ALB to register targets. Check K8s pods status.

### Cleanup
To destroy the infrastructure and avoid costs:
1. Locally, navigate to `terraform/`.
2. Run `terraform destroy -auto-approve`.
(Alternatively, create a `destroy` workflow in GitHub Actions).

## User Guide
Please refer to [USER_GUIDE.md](USER_GUIDE.md) for instructions on using the application.
