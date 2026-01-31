#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Script: 03_scale_ecs_service.sh
# Purpose: Scale the ECS API service to desired count using AWS CLI
# Usage: ./03_scale_ecs_service.sh <desired_count>
# Example: ./03_scale_ecs_service.sh 1
# ==============================================================================

DESIRED_COUNT="${1:-1}"

echo "==> Step 3: Scaling ECS API service to ${DESIRED_COUNT} tasks"

CLUSTER_NAME="devsecops-security-ops-ecs-cluster"
SERVICE_NAME="devsecops-security-ops-api-service"

# Update the service desired count
echo "==> Updating ECS service..."
aws ecs update-service \
  --cluster "${CLUSTER_NAME}" \
  --service "${SERVICE_NAME}" \
  --desired-count "${DESIRED_COUNT}" \
  --no-cli-pager \
  > /dev/null

echo "✅ Service update initiated"
echo ""

# Wait for tasks to stabilize
echo "==> Waiting for tasks to stabilize (30 seconds)..."
sleep 30

# Check service status
API_URL="https://api.zachmaestas-capstone.com"

echo "==> Current service status:"
aws ecs describe-services \
  --cluster "${CLUSTER_NAME}" \
  --services "${SERVICE_NAME}" \
  --query 'services[0].{Desired:desiredCount,Running:runningCount,Pending:pendingCount}' \
  --output table

if [ "${DESIRED_COUNT}" -gt 0 ]; then
  echo ""
  echo "==> Checking ALB target health..."
  TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups \
    --names devsecops-security-ops-tg \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text)

  aws elbv2 describe-target-health \
    --target-group-arn "${TARGET_GROUP_ARN}" \
    --query 'TargetHealthDescriptions[*].{Target:Target.Id,Port:Target.Port,Health:TargetHealth.State}' \
    --output table

  echo ""
  echo "✅ ECS service scaled to ${DESIRED_COUNT} task(s)"
  echo ""
  echo "Test the API:"
  echo "  curl ${API_URL}/health"
  echo "  curl ${API_URL}/ready"
  echo "  curl ${API_URL}/items"
else
  echo ""
  echo "✅ ECS service scaled down to 0 tasks"
fi
