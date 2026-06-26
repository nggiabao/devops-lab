#!/bin/bash
# Test Cases – NT548-Lab01 Infrastructure Verification

REGION="us-east-1"
PROJECT_NAME="nt548-lab01"
PASS=0
FAIL=0

# Helper functions
pass() { echo "PASS: $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL: $1"; FAIL=$((FAIL+1)); }
check() {
  local name=$1
  local val=$2
  if [ -n "$val" ] && [ "$val" != "None" ] && [ "$val" != "null" ]; then
    pass "$name"
  else
    fail "$name"
  fi
}

echo " NT548-Lab01 Infrastructure Test"


echo ""
echo "TEST GROUP 1: VPC"
echo "------------------"

VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Project,Values=$PROJECT_NAME" \
  --query "Vpcs[0].VpcId" \
  --output text --region $REGION 2>/dev/null)

check "VPC tồn tại" "$VPC_ID"

if [ -n "$VPC_ID" ] && [ "$VPC_ID" != "None" ]; then

  VPC_CIDR=$(aws ec2 describe-vpcs --vpc-ids $VPC_ID \
    --query "Vpcs[0].CidrBlock" --output text --region $REGION)
  check "VPC CIDR đúng (10.0.0.0/16)" "$([ "$VPC_CIDR" = "10.0.0.0/16" ] && echo ok)"

  DNS_SUPPORT=$(aws ec2 describe-vpc-attribute \
    --vpc-id $VPC_ID --attribute enableDnsSupport \
    --query "EnableDnsSupport.Value" --output text --region $REGION)
  check "DNS Support bật" "$([ "$DNS_SUPPORT" = "True" ] && echo ok)"

  DNS_HOSTNAME=$(aws ec2 describe-vpc-attribute \
    --vpc-id $VPC_ID --attribute enableDnsHostnames \
    --query "EnableDnsHostnames.Value" --output text --region $REGION)
  check "DNS Hostnames bật" "$([ "$DNS_HOSTNAME" = "True" ] && echo ok)"

  PUBLIC_SUBNET=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Type,Values=Public" \
    --query "Subnets[0].SubnetId" --output text --region $REGION)
  check "Public Subnet tồn tại" "$PUBLIC_SUBNET"

  PRIVATE_SUBNET=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Type,Values=Private" \
    --query "Subnets[0].SubnetId" --output text --region $REGION)
  check "Private Subnet tồn tại" "$PRIVATE_SUBNET"

  IGW=$(aws ec2 describe-internet-gateways \
    --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
    --query "InternetGateways[0].InternetGatewayId" \
    --output text --region $REGION)
  check "Internet Gateway gắn với VPC" "$IGW"


  echo ""
  echo "TEST GROUP 2: NAT Gateway"
  echo "--------------------------"

  NAT_GW=$(aws ec2 describe-nat-gateways \
    --filter "Name=vpc-id,Values=$VPC_ID" "Name=state,Values=available" \
    --query "NatGateways[0].NatGatewayId" --output text --region $REGION)
  check "NAT Gateway tồn tại và available" "$NAT_GW"

  if [ -n "$NAT_GW" ] && [ "$NAT_GW" != "None" ]; then
    NAT_SUBNET=$(aws ec2 describe-nat-gateways \
      --nat-gateway-ids $NAT_GW \
      --query "NatGateways[0].SubnetId" --output text --region $REGION)
    check "NAT Gateway ở Public Subnet" \
      "$([ "$NAT_SUBNET" = "$PUBLIC_SUBNET" ] && echo ok)"
  fi

  echo ""
  echo "TEST GROUP 3: Route Tables"
  echo "---------------------------"

  PUBLIC_RT=$(aws ec2 describe-route-tables \
    --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Type,Values=Public" \
    --query "RouteTables[0].RouteTableId" --output text --region $REGION)
  check "Public Route Table tồn tại" "$PUBLIC_RT"

  if [ -n "$PUBLIC_RT" ] && [ "$PUBLIC_RT" != "None" ]; then
    IGW_ROUTE=$(aws ec2 describe-route-tables \
      --route-table-ids $PUBLIC_RT \
      --query "RouteTables[0].Routes[?DestinationCidrBlock=='0.0.0.0/0'].GatewayId" \
      --output text --region $REGION)
    check "Public RT có route đến IGW" \
      "$(echo $IGW_ROUTE | grep -c igw- || true)"
  fi

  PRIVATE_RT=$(aws ec2 describe-route-tables \
    --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Type,Values=Private" \
    --query "RouteTables[0].RouteTableId" --output text --region $REGION)
  check "Private Route Table tồn tại" "$PRIVATE_RT"

  if [ -n "$PRIVATE_RT" ] && [ "$PRIVATE_RT" != "None" ]; then
    NAT_ROUTE=$(aws ec2 describe-route-tables \
      --route-table-ids $PRIVATE_RT \
      --query "RouteTables[0].Routes[?DestinationCidrBlock=='0.0.0.0/0'].NatGatewayId" \
      --output text --region $REGION)
    check "Private RT có route đến NAT GW" \
      "$(echo $NAT_ROUTE | grep -c nat- || true)"
  fi

  echo ""
  echo "TEST GROUP 4: Security Groups"
  echo "------------------------------"

  PUBLIC_SG=$(aws ec2 describe-security-groups \
    --filters "Name=vpc-id,Values=$VPC_ID" \
              "Name=group-name,Values=${PROJECT_NAME}-public-ec2" \
    --query "SecurityGroups[0].GroupId" --output text --region $REGION)
  check "Public EC2 Security Group tồn tại" "$PUBLIC_SG"

  if [ -n "$PUBLIC_SG" ] && [ "$PUBLIC_SG" != "None" ]; then
    SSH_RULE=$(aws ec2 describe-security-groups \
      --group-ids $PUBLIC_SG \
      --query "SecurityGroups[0].IpPermissions[?FromPort==\`22\`].FromPort" \
      --output text --region $REGION)
    check "Public SG có rule SSH (port 22)" "$SSH_RULE"
  fi

  PRIVATE_SG=$(aws ec2 describe-security-groups \
    --filters "Name=vpc-id,Values=$VPC_ID" \
              "Name=group-name,Values=${PROJECT_NAME}-private-ec2" \
    --query "SecurityGroups[0].GroupId" --output text --region $REGION)
  check "Private EC2 Security Group tồn tại" "$PRIVATE_SG"

  if [ -n "$PRIVATE_SG" ] && [ "$PRIVATE_SG" != "None" ]; then
    PRIVATE_SG_SOURCE=$(aws ec2 describe-security-groups \
      --group-ids $PRIVATE_SG \
      --query "SecurityGroups[0].IpPermissions[0].UserIdGroupPairs[0].GroupId" \
      --output text --region $REGION)
    check "Private SG chỉ cho phép SSH từ Public SG" \
      "$([ "$PRIVATE_SG_SOURCE" = "$PUBLIC_SG" ] && echo ok)"
  fi

  echo ""
  echo "TEST GROUP 5: EC2 Instances"
  echo "----------------------------"

  PUBLIC_EC2=$(aws ec2 describe-instances \
    --filters "Name=vpc-id,Values=$VPC_ID" \
              "Name=tag:Type,Values=Public" \
              "Name=instance-state-name,Values=running" \
    --query "Reservations[0].Instances[0].InstanceId" \
    --output text --region $REGION)
  check "Public EC2 đang chạy (running)" "$PUBLIC_EC2"

  if [ -n "$PUBLIC_EC2" ] && [ "$PUBLIC_EC2" != "None" ]; then
    PUBLIC_IP=$(aws ec2 describe-instances \
      --instance-ids $PUBLIC_EC2 \
      --query "Reservations[0].Instances[0].PublicIpAddress" \
      --output text --region $REGION)
    check "Public EC2 có Public IP" "$PUBLIC_IP"

    echo "   → Public EC2 IP: $PUBLIC_IP"
  fi

  PRIVATE_EC2=$(aws ec2 describe-instances \
    --filters "Name=vpc-id,Values=$VPC_ID" \
              "Name=tag:Type,Values=Private" \
              "Name=instance-state-name,Values=running" \
    --query "Reservations[0].Instances[0].InstanceId" \
    --output text --region $REGION)
  check "Private EC2 đang chạy (running)" "$PRIVATE_EC2"

  if [ -n "$PRIVATE_EC2" ] && [ "$PRIVATE_EC2" != "None" ]; then
    PRIVATE_IP=$(aws ec2 describe-instances \
      --instance-ids $PRIVATE_EC2 \
      --query "Reservations[0].Instances[0].PrivateIpAddress" \
      --output text --region $REGION)
    check "Private EC2 chỉ có Private IP" "$PRIVATE_IP"

    PRIV_PUBLIC_IP=$(aws ec2 describe-instances \
      --instance-ids $PRIVATE_EC2 \
      --query "Reservations[0].Instances[0].PublicIpAddress" \
      --output text --region $REGION)
    check "Private EC2 KHÔNG có Public IP" \
      "$([ -z "$PRIV_PUBLIC_IP" ] || [ "$PRIV_PUBLIC_IP" = "None" ] && echo ok)"

    echo "   → Private EC2 IP: $PRIVATE_IP"
  fi
fi

echo ""
echo " Kết quả: $PASS passed  |  $FAIL failed"