# Quick Deploy Guide

## GitHub Actions (5 minutes)

1. Add secrets to GitHub:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_SESSION_TOKEN`
   - `DOCKERHUB_USERNAME`
   - `DOCKERHUB_TOKEN`

2. Go to Actions → Complete CI/CD Pipeline → Run workflow

3. Wait 10-15 minutes

4. Get URL from workflow output

## Local Deploy (5 minutes)

```bash
# Configure AWS
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
export AWS_SESSION_TOKEN="..."

# Login to Docker
docker login

# Deploy everything
chmod +x deploy-local.sh
./deploy-local.sh
```

## Access Application

```
http://carlot-alb-XXXXXXXX.us-east-1.elb.amazonaws.com/
```

## Cleanup

```bash
cd terraform
terraform destroy -auto-approve
```
