#!/bin/bash
set -e

PROJECT_NAME="nt548-lab02"
REGION="us-east-1"
YOUR_IP=$(curl -4 -s ifconfig.me)

echo "Deploying pipeline infrastructure..."
aws cloudformation deploy \
  --template-file pipeline-infra.yaml \
  --stack-name "${PROJECT_NAME}-pipeline-infra" \
  --parameter-overrides \
    ProjectName=$PROJECT_NAME \
    AllowedSshCidr="${YOUR_IP}/32" \
    KeyName=nt548-keypair \
  --capabilities CAPABILITY_NAMED_IAM \
  --region $REGION

echo ""
echo "Pipeline has been created! Outputs:"
aws cloudformation describe-stacks \
  --stack-name "${PROJECT_NAME}-pipeline-infra" \
  --region $REGION \
  --query 'Stacks[0].Outputs' \
  --output table