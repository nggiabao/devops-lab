#!/bin/bash
set -e

PROJECT_NAME="nt548-lab02"
REGION="us-east-1"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Infrastructure stacks in REVERSE deploy order (dependencies last)
INFRA_STACKS=(
  "${PROJECT_NAME}-ec2"
  "${PROJECT_NAME}-sg"
  "${PROJECT_NAME}-routes"
  "${PROJECT_NAME}-nat"
  "${PROJECT_NAME}-vpc"
)

PIPELINE_STACK="${PROJECT_NAME}-pipeline-infra"

delete_stack() {
  local stack_name=$1
  echo -e "${YELLOW}Checking stack: ${stack_name}...${NC}"

  # Check if stack exists
  if ! aws cloudformation describe-stacks \
    --stack-name "$stack_name" \
    --region "$REGION" &>/dev/null; then
    echo -e "${GREEN}  Stack ${stack_name} does not exist, skipping.${NC}"
    return 0
  fi

  echo -e "${RED}  Deleting stack: ${stack_name}...${NC}"
  aws cloudformation delete-stack \
    --stack-name "$stack_name" \
    --region "$REGION"

  echo "  Waiting for stack deletion to complete..."
  aws cloudformation wait stack-delete-complete \
    --stack-name "$stack_name" \
    --region "$REGION"

  echo -e "${GREEN}  Stack ${stack_name} deleted successfully.${NC}"
}

empty_s3_bucket() {
  local bucket_name=$1
  echo -e "${YELLOW}Emptying S3 bucket: ${bucket_name}...${NC}"

  # Check if bucket exists
  if ! aws s3api head-bucket --bucket "$bucket_name" 2>/dev/null; then
    echo -e "${GREEN}  Bucket ${bucket_name} does not exist, skipping.${NC}"
    return 0
  fi

  # Delete all object versions (required for versioned buckets)
  echo "  Deleting all object versions..."
  aws s3api list-object-versions \
    --bucket "$bucket_name" \
    --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' \
    --output json 2>/dev/null | \
  aws s3api delete-objects \
    --bucket "$bucket_name" \
    --delete file:///dev/stdin 2>/dev/null || true

  # Delete all delete markers
  echo "  Deleting all delete markers..."
  aws s3api list-object-versions \
    --bucket "$bucket_name" \
    --query '{Objects: DeleteMarkers[].{Key:Key,VersionId:VersionId}}' \
    --output json 2>/dev/null | \
  aws s3api delete-objects \
    --bucket "$bucket_name" \
    --delete file:///dev/stdin 2>/dev/null || true

  echo -e "${GREEN}  Bucket ${bucket_name} emptied.${NC}"
}

echo "============================================"
echo "  NT548-Lab02 - DESTROY ALL RESOURCES"
echo "  Region: ${REGION}"
echo "============================================"
echo ""
echo -e "${RED}WARNING: This will permanently delete ALL resources!${NC}"
echo ""
read -p "Are you sure? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
  echo "Aborted."
  exit 0
fi
echo ""

# -----------------------------------------------
# Step 1: Delete infrastructure stacks (reverse order)
# -----------------------------------------------
echo "=========================================="
echo "Step 1: Deleting infrastructure stacks..."
echo "=========================================="
for stack in "${INFRA_STACKS[@]}"; do
  delete_stack "$stack"
done
echo ""

# -----------------------------------------------
# Step 2: Delete any leftover taskcat test stacks
# -----------------------------------------------
echo "=========================================="
echo "Step 2: Cleaning up taskcat test stacks..."
echo "=========================================="
TASKCAT_STACKS=$(aws cloudformation list-stacks \
  --region "$REGION" \
  --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE ROLLBACK_COMPLETE \
  --query "StackSummaries[?starts_with(StackName, 'tCaT-')].StackName" \
  --output text 2>/dev/null || true)

if [ -n "$TASKCAT_STACKS" ] && [ "$TASKCAT_STACKS" != "None" ]; then
  for stack in $TASKCAT_STACKS; do
    delete_stack "$stack"
  done
else
  echo -e "${GREEN}  No taskcat stacks found.${NC}"
fi
echo ""

# -----------------------------------------------
# Step 3: Empty S3 artifact bucket, then delete pipeline stack
# -----------------------------------------------
echo "=========================================="
echo "Step 3: Deleting pipeline infrastructure..."
echo "=========================================="

# Get the S3 bucket name from stack outputs
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="nt548-codepipeline-${ACCOUNT_ID}"

empty_s3_bucket "$BUCKET_NAME"
delete_stack "$PIPELINE_STACK"

echo ""
echo "============================================"
echo -e "${GREEN}  ALL RESOURCES DESTROYED SUCCESSFULLY!${NC}"
echo "============================================"
echo ""
echo "Deleted stacks:"
for stack in "${INFRA_STACKS[@]}"; do
  echo "  - $stack"
done
echo "  - $PIPELINE_STACK"
echo ""
echo "No more AWS charges from this lab."
