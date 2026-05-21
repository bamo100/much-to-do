#!/bin/bash
set -euo pipefail

echo "Deploying frontend..."
cd ../frontend
npm ci

# Build the Vite project with the public ALB URL baked in
VITE_API_BASE_URL="http://starttech-alb-1092607413.af-south-1.elb.amazonaws.com" npm run build

# Sync static files to S3 bucket
S3_BUCKET="starttech-frontend-dev-20260521142941701900000001"
echo "Syncing build files to S3 bucket: $S3_BUCKET"

aws s3 sync dist/ s3://$S3_BUCKET --delete --cache-control "public, max-age=31536000, immutable" --exclude "index.html"
aws s3 cp dist/index.html s3://$S3_BUCKET/index.html --cache-control "no-cache, no-store, must-revalidate"

echo "Frontend deployed successfully!"
