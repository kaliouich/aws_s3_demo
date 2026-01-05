#!/bin/bash
set -e

# Configuration derived from your specific deployment
AP_ARN="arn:aws:s3:us-east-1:012584563464:accesspoint/s3-demo-journey-auditor-38483287"
AP_NAME="s3-demo-journey-auditor-38483287"
ACCOUNT_ID="012584563464"

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
