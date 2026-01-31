#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# Script: 02_run_db_init.sh
# Purpose: Run the DB initialization ECS task to set up schema and app user
# Usage: ./02_run_db_init.sh
# ==============================================================================

echo "==> Step 2: Running DB initialization task"

# Get cluster and task definition info
CLUSTER_NAME="devsecops-security-ops-ecs-cluster"
TASK_DEF="devsecops-security-ops-db-init-task"

# Get subnets and security group from terraform output or AWS
echo "==> Fetching network configuration..."
SUBNETS=$(aws ec2 describe-subnets \
  --filters "Name=tag:Name,Values=devsecops-security-ops-private-app-*" \
  --query 'Subnets[*].SubnetId' \
  --output text | tr '\t' ',')

SECURITY_GROUP=$(aws ec2 describe-security-groups \
  --filters "Name=tag:Name,Values=devsecops-security-ops-ecs-tasks-sg" \
  --query 'SecurityGroups[0].GroupId' \
  --output text)

echo "Subnets: ${SUBNETS}"
echo "Security Group: ${SECURITY_GROUP}"
echo ""

# Run the task
echo "==> Starting DB init task..."
TASK_ARN=$(aws ecs run-task \
  --cluster "${CLUSTER_NAME}" \
  --task-definition "${TASK_DEF}" \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[${SUBNETS}],securityGroups=[${SECURITY_GROUP}],assignPublicIp=DISABLED}" \
  --query 'tasks[0].taskArn' \
  --output text)

echo "Task started: ${TASK_ARN}"
echo ""

# Wait for task to complete
echo "==> Waiting for task to complete..."
TASK_ID=$(echo "${TASK_ARN}" | awk -F'/' '{print $NF}')

MAX_ATTEMPTS=30
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
  TASK_STATUS=$(aws ecs describe-tasks \
    --cluster "${CLUSTER_NAME}" \
    --tasks "${TASK_ID}" \
    --query 'tasks[0].lastStatus' \
    --output text)

  if [ "${TASK_STATUS}" == "STOPPED" ] || [ "${TASK_STATUS}" == "DEPROVISIONING" ]; then
    break
  fi

  echo "Task status: ${TASK_STATUS} (attempt $((ATTEMPT + 1))/${MAX_ATTEMPTS})"
  sleep 5
  ATTEMPT=$((ATTEMPT + 1))
done

# Check exit code
EXIT_CODE=$(aws ecs describe-tasks \
  --cluster "${CLUSTER_NAME}" \
  --tasks "${TASK_ID}" \
  --query 'tasks[0].containers[0].exitCode' \
  --output text)

STOP_REASON=$(aws ecs describe-tasks \
  --cluster "${CLUSTER_NAME}" \
  --tasks "${TASK_ID}" \
  --query 'tasks[0].stoppedReason' \
  --output text)

echo ""
if [ "${EXIT_CODE}" == "0" ]; then
  echo "✅ DB initialization completed successfully!"
  echo "   Exit code: ${EXIT_CODE}"
  echo ""
  echo "Next step: Run ./03_scale_ecs_service.sh to start the API"
else
  echo "❌ DB initialization failed!"
  echo "   Exit code: ${EXIT_CODE}"
  echo "   Reason: ${STOP_REASON}"
  exit 1
fi
