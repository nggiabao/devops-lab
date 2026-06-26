# Lấy Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="nt548-tfstate-${ACCOUNT_ID}"
REGION="us-east-1"

# Tạo S3 bucket
aws s3 mb s3://${BUCKET_NAME} --region ${REGION}

# Bật versioning
aws s3api put-bucket-versioning \
  --bucket ${BUCKET_NAME} \
  --versioning-configuration Status=Enabled

# Bật server-side encryption
aws s3api put-bucket-encryption \
  --bucket ${BUCKET_NAME} \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Tạo DynamoDB table cho state locking
aws dynamodb create-table \
  --table-name nt548-terraform-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ${REGION}

echo "Bucket: ${BUCKET_NAME}"
echo "DynamoDB: nt548-terraform-lock"