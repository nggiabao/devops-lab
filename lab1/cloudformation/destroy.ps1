$PROJECT_NAME = "nt548-lab01"
$REGION = "us-east-1"

$stacks = @("ec2", "sg", "routes", "nat", "vpc")

foreach ($STACK in $stacks) {
    Write-Host "Deleting stack: $PROJECT_NAME-$STACK"
    
    aws cloudformation delete-stack `
        --stack-name "$PROJECT_NAME-$STACK" `
        --region $REGION
        
    aws cloudformation wait stack-delete-complete `
        --stack-name "$PROJECT_NAME-$STACK" `
        --region $REGION
        
    Write-Host "Deleted $STACK" -ForegroundColor Green
}

Write-Host "All stacks deleted." -ForegroundColor Cyan