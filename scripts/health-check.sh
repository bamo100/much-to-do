#!/bin/bash
set -euo pipefail

AWS_REGION="af-south-1"

# Fetch the ALB DNS name automatically
ALB_DNS=$(aws elbv2 describe-load-balancers \
  --names starttech-alb \
  --region $AWS_REGION \
  --query 'LoadBalancers[0].DNSName' \
  --output text)

echo "Testing backend health endpoint at http://$ALB_DNS/health..."

for i in {1..10}; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$ALB_DNS/health || echo "Failed")
  
  if [ "$STATUS" = "200" ]; then
    echo "✅ Health check passed! The backend is up and running."
    exit 0
  fi
  
  echo "Attempt $i failed (Status: $STATUS). Retrying in 15 seconds..."
  sleep 15
done

echo "❌ Health check failed after 10 attempts. The backend is unreachable or unhealthy."
exit 1
