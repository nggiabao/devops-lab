$PROJECT_NAME = "nt548-lab01"
$REGION       = "us-east-1"
$KEY_NAME     = "nt548-keypair"
$YOUR_IP      = (Get-Content ./ip_address.text).Trim()
$ALLOWED_CIDR = "$YOUR_IP/32"

Write-Host "Deploying with IP: $ALLOWED_CIDR" -ForegroundColor Cyan

# 1. VPC
Write-Host "[1/5] Deploying VPC..." -ForegroundColor Yellow
aws cloudformation deploy `
  --template-file templates/vpc.yaml `
  --stack-name "$PROJECT_NAME-vpc" `
  --parameter-overrides ProjectName=$PROJECT_NAME `
  --region $REGION

# 2. NAT Gateway
Write-Host "[2/5] Deploying NAT Gateway..." -ForegroundColor Yellow
aws cloudformation deploy `
  --template-file templates/nat_gateway.yaml `
  --stack-name "$PROJECT_NAME-nat" `
  --parameter-overrides ProjectName=$PROJECT_NAME `
  --region $REGION

# 3. Route Tables
Write-Host "[3/5] Deploying Route Tables..." -ForegroundColor Yellow
aws cloudformation deploy `
  --template-file templates/route_tables.yaml `
  --stack-name "$PROJECT_NAME-routes" `
  --parameter-overrides ProjectName=$PROJECT_NAME `
  --region $REGION

# 4. Security Groups
Write-Host "[4/5] Deploying Security Groups..." -ForegroundColor Yellow
aws cloudformation deploy `
  --template-file templates/security_groups.yaml `
  --stack-name "$PROJECT_NAME-sg" `
  --parameter-overrides ProjectName=$PROJECT_NAME AllowedSshCidr=$ALLOWED_CIDR `
  --region $REGION

# 5. EC2
Write-Host "[5/5] Deploying EC2..." -ForegroundColor Yellow
aws cloudformation deploy `
  --template-file templates/ec2.yaml `
  --stack-name "$PROJECT_NAME-ec2" `
  --parameter-overrides ProjectName=$PROJECT_NAME KeyName=$KEY_NAME `
  --region $REGION

Write-Host "Done!" -ForegroundColor Green