#!/bin/bash

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Jenkins deployment automation...${NC}"

# Check for required tools
echo -e "${YELLOW}Checking for required tools...${NC}"

# Check for Terraform
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Terraform not found. Please install Terraform.${NC}"
    exit 1
fi

# Check for Ansible
if ! command -v ansible &> /dev/null; then
    echo -e "${RED}Ansible not found. Please install Ansible.${NC}"
    exit 1
fi

# Check for AWS CLI
if ! command -v aws &> /dev/null; then
    echo -e "${RED}AWS CLI not found. Please install AWS CLI.${NC}"
    exit 1
fi

echo -e "${GREEN}All required tools found.${NC}"

# Check for AWS credentials
echo -e "${YELLOW}Checking AWS credentials...${NC}"
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}AWS credentials not found or invalid. Please configure AWS CLI.${NC}"
    exit 1
fi
echo -e "${GREEN}AWS credentials validated.${NC}"

# Check if the specified key exists in AWS
echo -e "${YELLOW}Checking if key pair exists in AWS...${NC}"
KEY_NAME=$(grep key_name terraform/terraform.tfvars | cut -d'"' -f2 || echo "blog-app-key")
if ! aws ec2 describe-key-pairs --key-names "$KEY_NAME" &> /dev/null; then
    echo -e "${RED}Key pair '$KEY_NAME' not found in AWS. Please create it or update the key_name in terraform.tfvars.${NC}"
    exit 1
fi
echo -e "${GREEN}Key pair found in AWS.${NC}"

# Deploy infrastructure with Terraform
echo -e "${YELLOW}Deploying infrastructure with Terraform...${NC}"
cd terraform
terraform init
terraform apply -auto-approve

# Get outputs
JENKINS_IP=$(terraform output -raw jenkins_public_ip)
JENKINS_URL=$(terraform output -raw jenkins_url)

echo -e "${GREEN}Terraform deployment completed.${NC}"
echo -e "${GREEN}Jenkins is being installed and configured...${NC}"
echo -e "${YELLOW}This may take several minutes. Please be patient.${NC}"

# Wait for Jenkins to be ready
echo -e "${YELLOW}Waiting for Jenkins to be fully configured...${NC}"
sleep 120  # Give Ansible some time to complete

# Check if Jenkins is up
echo -e "${YELLOW}Checking if Jenkins is up...${NC}"
MAX_RETRIES=30
RETRY_INTERVAL=10
for ((i=1; i<=MAX_RETRIES; i++)); do
    if curl -s -m 5 "${JENKINS_URL}" &> /dev/null; then
        echo -e "${GREEN}Jenkins is up and running!${NC}"
        break
    fi
    
    if [ $i -eq $MAX_RETRIES ]; then
        echo -e "${RED}Timed out waiting for Jenkins to start. Please check the server manually.${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}Waiting for Jenkins to start... Attempt $i of $MAX_RETRIES${NC}"
    sleep $RETRY_INTERVAL
done

echo -e "${GREEN}====================== DEPLOYMENT COMPLETE =======================${NC}"
echo -e "${GREEN}Jenkins has been successfully deployed at: ${JENKINS_URL}${NC}"
echo -e "${GREEN}You can find the admin credentials in the Ansible output.${NC}"
echo -e "${GREEN}=================================================================${NC}"