#!/bin/bash
set -euo pipefail

ASG_NAME="starttech-asg"
AWS_REGION="af-south-1"

echo "Attempting to rollback deployment for $ASG_NAME in $AWS_REGION..."

# Check if there is an instance refresh currently running
STATUS=$(aws autoscaling describe-instance-refreshes \
  --auto-scaling-group-name $ASG_NAME \
  --region $AWS_REGION \
  --query 'InstanceRefreshes[0].Status' \
  --output text || echo "None")

if [ "$STATUS" = "InProgress" ] || [ "$STATUS" = "Pending" ]; then
  echo "Detected an active Instance Refresh ($STATUS). Cancelling it to stop new instances from rolling out..."
  aws autoscaling cancel-instance-refresh \
    --auto-scaling-group-name $ASG_NAME \
    --region $AWS_REGION
  
  echo "✅ Cancellation requested. AWS will stop replacing instances."
else
  echo "No active Instance Refresh found."
  echo "To perform a full historical rollback, we will attempt to rollback to the last successful configuration..."
  
  aws autoscaling rollback-instance-refresh \
    --auto-scaling-group-name $ASG_NAME \
    --region $AWS_REGION || {
      echo "❌ Rollback failed or no previous configuration exists to rollback to."
      exit 1
    }
    
  echo "✅ Rollback sequence initiated. Monitor AWS console to watch instances revert."
fi
