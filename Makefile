.PHONY: help deploy destroy build db-init scale-up scale-down status terraform-init terraform-apply terraform-destroy clean

# Default target - show help
.DEFAULT_GOAL := help

# Color output
GREEN  := \033[0;32m
YELLOW := \033[0;33m
RED    := \033[0;31m
NC     := \033[0m # No Color

# Project variables
TERRAFORM_DIR := infrastructure/terraform
SCRIPTS_DIR   := infrastructure/scripts/deploy

##@ General

help: ## Display this help message
	@echo "$(GREEN)DevSecOps Security Operations - Deployment Automation$(NC)"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"; printf "Usage:\n  make $(YELLOW)<target>$(NC)\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2 } /^##@/ { printf "\n$(GREEN)%s$(NC)\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Full Deployment

deploy: terraform-apply build db-init scale-up status ## Full deployment: terraform → build images → init DB → start service
	@echo "$(GREEN)✅ Deployment complete!$(NC)"
	@echo ""
	@echo "Test the API:"
	@echo "  curl https://api.zachmaestas-capstone.com/health"
	@echo "  curl https://api.zachmaestas-capstone.com/ready"
	@echo "  curl https://api.zachmaestas-capstone.com/items"

destroy: scale-down terraform-destroy ## Full teardown: stop service → destroy infrastructure
	@echo "$(GREEN)✅ Infrastructure destroyed$(NC)"

##@ Individual Steps

terraform-init: ## Initialize Terraform
	@echo "$(YELLOW)→ Initializing Terraform...$(NC)"
	cd $(TERRAFORM_DIR) && terraform init

terraform-apply: terraform-init ## Apply Terraform configuration (creates infrastructure with 0 tasks)
	@echo "$(YELLOW)→ Applying Terraform configuration...$(NC)"
	cd $(TERRAFORM_DIR) && terraform apply -auto-approve
	@echo "$(GREEN)✅ Infrastructure provisioned$(NC)"

terraform-destroy: ## Destroy Terraform infrastructure
	@echo "$(RED)→ Destroying infrastructure...$(NC)"
	cd $(TERRAFORM_DIR) && terraform destroy -auto-approve

build: ## Build and push Docker images to ECR
	@echo "$(YELLOW)→ Building and pushing Docker images...$(NC)"
	@bash $(SCRIPTS_DIR)/01_build_and_push_images.sh
	@echo "$(GREEN)✅ Images pushed to ECR$(NC)"

db-init: ## Run database initialization task
	@echo "$(YELLOW)→ Initializing database...$(NC)"
	@bash $(SCRIPTS_DIR)/02_run_db_init.sh
	@echo "$(GREEN)✅ Database initialized$(NC)"

scale-up: ## Scale ECS service to 1 task
	@echo "$(YELLOW)→ Starting ECS service (1 task)...$(NC)"
	@bash $(SCRIPTS_DIR)/03_scale_ecs_service.sh 1
	@echo "$(GREEN)✅ Service running$(NC)"

scale-down: ## Scale ECS service to 0 tasks
	@echo "$(YELLOW)→ Stopping ECS service (0 tasks)...$(NC)"
	@bash $(SCRIPTS_DIR)/03_scale_ecs_service.sh 0
	@echo "$(GREEN)✅ Service stopped$(NC)"

##@ Utilities

status: ## Show current deployment status
	@echo "$(YELLOW)→ Checking deployment status...$(NC)"
	@echo ""
	@echo "ECS Service:"
	@aws ecs describe-services \
		--cluster devsecops-security-ops-ecs-cluster \
		--services devsecops-security-ops-api-service \
		--query 'services[0].{Desired:desiredCount,Running:runningCount,Pending:pendingCount}' \
		--output table || echo "$(RED)✗ Service not found$(NC)"
	@echo ""
	@echo "RDS Instance:"
	@aws rds describe-db-instances \
		--db-instance-identifier devsecops-security-ops-rds \
		--query 'DBInstances[0].{Status:DBInstanceStatus,Endpoint:Endpoint.Address}' \
		--output table || echo "$(RED)✗ RDS not found$(NC)"

validate: ## Validate Terraform configuration
	@echo "$(YELLOW)→ Validating Terraform...$(NC)"
	cd $(TERRAFORM_DIR) && terraform fmt -check -recursive && terraform validate
	@echo "$(GREEN)✅ Validation passed$(NC)"

clean: ## Clean temporary files
	@echo "$(YELLOW)→ Cleaning temporary files...$(NC)"
	find $(TERRAFORM_DIR) -name "*.tfstate.backup" -delete
	find $(TERRAFORM_DIR) -name ".terraform.lock.hcl" -delete
	rm -f $(TERRAFORM_DIR)/tfplan
	@echo "$(GREEN)✅ Cleanup complete$(NC)"

##@ Development

restart: scale-down scale-up ## Restart the ECS service (scale down then up)

redeploy: build scale-down scale-up ## Rebuild images and restart service (for code changes)
	@echo "$(GREEN)✅ Service redeployed with new images$(NC)"

logs: ## Show recent ECS task logs (requires CloudWatch Logs configuration)
	@echo "$(YELLOW)→ Fetching recent logs...$(NC)"
	@aws logs tail /ecs/devsecops-security-ops-api-task --since 10m --follow
