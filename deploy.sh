#!/bin/bash
set -e

# Configuration
REGION="us-east-1"
RANDOM_SUFFIX=$(openssl rand -hex 4)
BUCKET_PREFIX="s3-demo-journey"
WEBSITE_BUCKET="${BUCKET_PREFIX}-${RANDOM_SUFFIX}"
LOG_BUCKET="${BUCKET_PREFIX}-logs-${RANDOM_SUFFIX}"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "=== AWS S3 Advanced Demo Deployment (CLI Workaround) ==="
echo "Region: $REGION"
echo "Website Bucket: $WEBSITE_BUCKET"
echo "Log Bucket: $LOG_BUCKET"
echo "Account ID: $ACCOUNT_ID"

# 1. Create Buckets
echo -e "\n[1/7] Creating Buckets..."
aws s3 mb s3://$WEBSITE_BUCKET --region $REGION
aws s3 mb s3://$LOG_BUCKET --region $REGION

# 2. Configure Log Bucket (ACLs & Versioning & Lifecycle)
echo -e "\n[2/7] Configuring Log Bucket..."
aws s3api put-bucket-versioning --bucket $LOG_BUCKET --versioning-configuration Status=Enabled

# Enable ACLs (Required for Log Delivery in this demo setup)
aws s3api put-bucket-ownership-controls --bucket $LOG_BUCKET --ownership-controls="Rules=[{ObjectOwnership=BucketOwnerPreferred}]"
aws s3api put-bucket-acl --bucket $LOG_BUCKET --acl log-delivery-write

# Lifecycle: Transition to Glacier > 30 days, Expire > 90 days
LIFECYCLE_CONFIG='{
    "Rules": [
        {
            "ID": "log-management",
            "Status": "Enabled",
            "Filter": {"Prefix": ""},
            "Transitions": [{"Days": 30, "StorageClass": "GLACIER"}],
            "Expiration": {"Days": 90}
        }
    ]
}'
aws s3api put-bucket-lifecycle-configuration --bucket $LOG_BUCKET --lifecycle-configuration "$LIFECYCLE_CONFIG"

# 3. Configure Website Bucket (Website, Logging, Policy)
echo -e "\n[3/7] Configuring Website Bucket..."
aws s3api put-bucket-versioning --bucket $WEBSITE_BUCKET --versioning-configuration Status=Enabled
aws s3api put-bucket-logging --bucket $WEBSITE_BUCKET --bucket-logging-status "{\"LoggingEnabled\":{\"TargetBucket\":\"$LOG_BUCKET\",\"TargetPrefix\":\"log/\"}}"
aws s3 website s3://$WEBSITE_BUCKET/ --index-document index.html --error-document error.html

# Remove Public Access Block
aws s3api delete-public-access-block --bucket $WEBSITE_BUCKET

# Public Read Policy
POLICY='{
    "Version": "2012-10-17",
    "Statement": [{
        "Sid": "PublicReadGetObject",
        "Effect": "Allow",
        "Principal": "*",
        "Action": "s3:GetObject",
        "Resource": "arn:aws:s3:::'$WEBSITE_BUCKET'/*"
    }]
}'
aws s3api put-bucket-policy --bucket $WEBSITE_BUCKET --policy "$POLICY"

# 4. Upload Content
echo -e "\n[4/7] Uploading Content..."
aws s3 cp www/index.html s3://$WEBSITE_BUCKET/ --content-type text/html
aws s3 cp www/error.html s3://$WEBSITE_BUCKET/ --content-type text/html
aws s3 cp www/secret.txt s3://$LOG_BUCKET/ --content-type text/plain

# 5. Access Point
echo -e "\n[5/7] Creating Access Point..."
AP_NAME="${BUCKET_PREFIX}-auditor-${RANDOM_SUFFIX}"
aws s3control create-access-point --account-id $ACCOUNT_ID --name $AP_NAME --bucket $LOG_BUCKET --region $REGION

# Wait for AP creation...
sleep 2

# Access Point Policy
AP_ARN="arn:aws:s3:$REGION:$ACCOUNT_ID:accesspoint/$AP_NAME"
AP_POLICY='{
    "Version": "2012-10-17",
    "Statement": [{
        "Sid": "AllowAuditorReadLogs",
        "Effect": "Allow",
        "Principal": {"AWS": "'$ACCOUNT_ID'"},
        "Action": ["s3:GetObject", "s3:ListBucket"],
        "Resource": ["'$AP_ARN'", "'$AP_ARN'/object/log/*"]
    }]
}'
aws s3control put-access-point-policy --account-id $ACCOUNT_ID --name $AP_NAME --policy "$AP_POLICY"

# 6. Generate Outputs (Mocking terraform output -json)
echo -e "\n[6/7] Generating Outputs..."
WEBSITE_ENDPOINT="http://$WEBSITE_BUCKET.s3-website-$REGION.amazonaws.com"
PRESIGN_CMD="aws s3 presign s3://$LOG_BUCKET/secret.txt --expires-in 300"
DIRECT_URL="https://$LOG_BUCKET.s3.amazonaws.com/secret.txt"
AUDITOR_CMD="aws s3 ls s3://$AP_ARN/log/"

cat > outputs.json <<EOF
{
  "website_endpoint": {
    "value": "$WEBSITE_ENDPOINT"
  },
  "log_bucket_name": {
    "value": "$LOG_BUCKET"
  },
  "secret_file_direct_url": {
    "value": "$DIRECT_URL"
  },
  "s3_presign_command": {
    "value": "$PRESIGN_CMD"
  },
  "auditor_access_point_arn": {
    "value": "$AP_ARN"
  },
  "auditor_access_command": {
    "value": "$AUDITOR_CMD"
  }
}
EOF

# 7. Update Demo Guide (No action needed, script auto-detects outputs.json)
echo -e "\n[7/7] Done! You can now run:"
echo "python3 demo_guide.py"
