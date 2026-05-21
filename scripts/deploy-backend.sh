#!/bin/bash
set -euo pipefail

AWS_REGION="af-south-1"
ECR_REPOSITORY="691416125683.dkr.ecr.af-south-1.amazonaws.com/starttech-backend"
ASG_NAME="starttech-asg"

echo "Deploying backend..."

echo "Logging in to ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPOSITORY

echo "Building and pushing Docker image..."
cd ../backend/MuchToDo
IMAGE_TAG=$(git rev-parse --short HEAD 2>/dev/null || echo "latest-$(date +%s)")
docker build -t $ECR_REPOSITORY:$IMAGE_TAG -t $ECR_REPOSITORY:latest .
docker push $ECR_REPOSITORY:$IMAGE_TAG
docker push $ECR_REPOSITORY:latest

echo "Triggering Auto Scaling Group Instance Refresh..."
aws autoscaling start-instance-refresh \
  --auto-scaling-group-name $ASG_NAME \
  --region $AWS_REGION \
  --preferences '{"MinHealthyPercentage": 50, "InstanceWarmup": 120}'

echo "Backend deployment triggered successfully! Check health using health-check.sh in a few minutes."
