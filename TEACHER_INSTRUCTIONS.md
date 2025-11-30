# Teacher / Evaluator Instructions

## Quick Start
This project is designed to be fully automated. As the evaluator, you only need **GitHub Access** and **AWS Credentials**.

## Step-by-Step Evaluation Guide

### 1. Repository Setup
1.  **Clone or Fork** this repository to your own GitHub account.
    *   *Reason*: You need admin rights to set Secrets and run Actions.

### 2. Configure Secrets
Go to **Settings** -> **Secrets and variables** -> **Actions** -> **New repository secret**.
Add the following secrets (using your own AWS and Docker Hub accounts):

| Secret Name | Value Example |
|-------------|---------------|
| `AWS_ACCESS_KEY_ID` | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |
| `AWS_REGION` | `us-east-1` |
| `DOCKERHUB_USERNAME` | `azexkush` (Must have push access to `azexkush/car-lot-manager`) |
| `DOCKERHUB_TOKEN` | `dckr_pat_...` (Access Token) |

> **Note**: The pipeline is configured to push to `azexkush/car-lot-manager`. Ensure the provided Docker Hub credentials have permission to push to this repository.

### 3. Run the Pipeline
1.  Go to the **Actions** tab.
2.  Select **CI/CD Pipeline** on the left sidebar.
3.  Click the **Run workflow** button (blue button on the right).
4.  Select `main` branch and click **Run workflow**.

### 4. Monitor Deployment
*   The workflow will take approximately **10-15 minutes**.
*   It will:
    *   Test the code.
    *   Build/Push Docker image.
    *   Provision EC2 + ALB (Terraform).
    *   Configure K8s + NFS (Ansible).
    *   Deploy App (Helm).

### 5. Verify the Application
1.  Once the workflow finishes (Green Checkmark), click on the run.
2.  Click on the **deploy** job.
3.  Expand the **Final Output** step at the bottom.
4.  You will see a link:
    ```
    Application deployed successfully!
    Access it at: http://carlot-alb-xxxx.us-east-1.elb.amazonaws.com/
    ```
5.  **Click the link**. You should see the "Car Lot Manager" with initial data.

### 6. Verify Persistence (Optional)
1.  Add a new car using the form.
2.  In GitHub Actions, you can re-run the **deploy** job (or trigger a new run).
3.  The new car should still be there because data is stored on NFS.

### 7. Cleanup (Important!)
To avoid AWS charges, please destroy the infrastructure when finished.
*   **Option A (Local)**: Clone repo locally, go to `terraform/`, run `terraform destroy`.
*   **Option B (AWS Console)**: Manually terminate the 3 EC2 instances and delete the Load Balancer.
