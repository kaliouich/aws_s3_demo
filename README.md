# AWS S3 Advanced Demo (CLI Edition)

This project demonstrates advanced AWS S3 features including **Static Website Hosting**, **Lifecycle Policies**, **Pre-signed URLs**, and **S3 Access Points** with restricted policies.

> **Note**: This project was originally designed for Terraform, but due to Lab Environment restrictions (Service Control Policies blocking `s3:GetAccelerateConfiguration`), it has been converted to use the **AWS CLI** directly.

## Project Structure

-   `deploy.sh`: Primary deployment script (Bash + AWS CLI).
-   `fix_policy.sh`: Script to enforce strict "Explicit Deny" policies on the Access Point.
-   `demo_guide.py`: Interactive Python script to guide the presenter.
-   `www/`: Static website content (`index.html`, `error.html`, `secret.txt`).

## Features Application

1.  **Static Website**: A public bucket hosting a simple HTML site.
2.  **Log Bucket**: A private bucket receiving server access logs from the website.
3.  **Lifecycle Rules**: Logs are transitioned to GLACIER after 30 days and expired after 90 days.
4.  **Granular Access**:
    -   **Pre-signed URLs**: Temporary access to private files (`secret.txt`).
    -   **S3 Access Points**: A specific endpoint restricted to only view logs, blocking access to other private files.

## Prerequisites

-   **AWS CLI** (v2 recommended)
-   **Python 3**
-   Active AWS credentials

## Usage

### 1. Deploy the Infrastructure
Run the deployment script to create buckets, upload files, and configure policies.
```bash
chmod +x deploy.sh
./deploy.sh
```

### 2. Run the Demo Guide
Use the Python script to walk through the features interactively.

```bash
python3 demo_guide.py
```

### Demo Guide: Step-by-Step Explanation

The script guides you through 3 main features. Here is what to expect:

**Step 1: Static Website Hosting**
- **Action**: The script provides a URL (e.g., `http://...s3-website...`).
- **Expected Outcome**: Opening this link shows the "Welcome" HTML page. This confirms the bucket is public and correctly hosting the static site.

**Step 2: Pre-signed URL (Security)**
- **Action 1**: The script provides a Direct Link to `secret.txt`.
- **Expected Outcome**: **403 Forbidden**. The file is in a private bucket, so direct access is blocked.
- **Action 2**: The script generates a long Pre-signed URL.
- **Expected Outcome**: **Success**. Opening this temporary link allows you to view the secret file, demonstrating secure, temporary access sharing.

**Step 3: S3 Access Points (Granular Control)**
- **Action 1**: The script lists logs using the "Auditor" Access Point.
- **Expected Outcome**: **Success**. The policy allows viewing logs.
    > **Note**: Real S3 access logs take 15-60 minutes to appear. To see data immediately during a demo, you can "simulate" a log file:
    > ```bash
    > echo "Simulated Log Entry" > dummy.txt
    > aws s3 cp dummy.txt s3://s3-demo-journey-logs-38483287/log/simulated-log.txt
    > ```
- **Action 2**: The script tries to "steal" the secret using the same Access Point.
    - *Initially*: This may **Succeed** if you are an Admin.
    - *After Security Fix*: Once you run `fix_policy.sh`, this action will fail with **Access Denied**.
- **Action 3**: Retry the **Pre-signed URL** from Step 2.
- **Expected Outcome**: **Success**. This proves that restricting the Access Point does *not* break other valid access methods (like pre-signed URLs) to the underlying bucket.

### 3. Demonstrate Security (Access Points)
During the demo, you will see that the "Auditor" Access Point might initially allow too much access (if you are an Admin).
To demonstrate **strict** security, apply the "Explicit Deny" policy:

```bash
chmod +x fix_policy.sh
./fix_policy.sh
```
*Now retry the "steal secret" step in the demo—it will be denied.*

## Cleanup
To remove all resources created by the script, you will need to manually delete the buckets and access points via the AWS Console or CLI.
```bash
# Example Cleanup (Replace with your actual bucket names)
aws s3 rb s3://<website-bucket-name> --force
aws s3 rb s3://<log-bucket-name> --force
aws s3control delete-access-point --name <access-point-name> --account-id <your-account-id>
```
