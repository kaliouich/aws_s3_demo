#!/bin/bash
set -e

# Configuration dynamically loaded from outputs.json
if [ ! -f "outputs.json" ]; then
    echo "Error: outputs.json not found. Run ./deploy.sh first."
    exit 1
fi

# Extract values using Python (reliable strings handling)
AP_ARN=$(python3 -c "import json; print(json.load(open('outputs.json'))['auditor_access_point_arn']['value'])")
AP_NAME=$(echo $AP_ARN | rev | cut -d'/' -f1 | rev)
ACCOUNT_ID=$(echo $AP_ARN | cut -d':' -f5)

echo "Detected Configuration:"
echo "  AP_ARN:     $AP_ARN"
echo "  AP_NAME:    $AP_NAME"
echo "  ACCOUNT_ID: $ACCOUNT_ID"

# Find AWS CLI
if command -v aws &> /dev/null; then
    AWS_CMD="aws"
elif [ -f "/usr/local/bin/aws" ]; then
    AWS_CMD="/usr/local/bin/aws"
elif [ -f "/usr/bin/aws" ]; then
    AWS_CMD="/usr/bin/aws"
elif [ -f "/snap/bin/aws" ]; then
    AWS_CMD="/snap/bin/aws"
else
    echo "Error: AWS CLI not found in standard paths."
    exit 1
fi

echo "Using AWS CLI: $AWS_CMD"

echo "Updating Access Point Policy to be STRICT (Explicit Deny)..."

# Policy:
# 1. Allow reading logs.
# 2. Explicitly DENY reading anything that is NOT logs (Exceptions: the AP itself for listing).
POLICY='{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowAuditorReadLogs",
            "Effect": "Allow",
            "Principal": {"AWS": "'$ACCOUNT_ID'"},
            "Action": ["s3:GetObject", "s3:ListBucket"],
            "Resource": ["'$AP_ARN'", "'$AP_ARN'/object/log/*"]
        },
        {
            "Sid": "ExplicitDenyEverythingElse",
            "Effect": "Deny",
            "Principal": {"AWS": "*"},
            "Action": "s3:GetObject",
            "NotResource": [
                "'$AP_ARN'/object/log/*",
                "'$AP_ARN'"
            ]
        }
    ]
}'

$AWS_CMD s3control put-access-point-policy --account-id $ACCOUNT_ID --name $AP_NAME --policy "$POLICY"

echo "Policy updated. The 'Secret' should now be denied."
