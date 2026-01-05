# AWS S3 Terraform Demo

**Part of the AWS Terraform Learning Journey**

This project demonstrates an advanced setup of Amazon S3 using Terraform. It deploys a secure, static website with automated logging, versioning, and lifecycle management.

## Architecture Highlights

1.  **Static Website Hosting**:
    - Hosted on S3 with a public read policy.
    - Custom `index.html` and `error.html` pages.
    - **Versioning**: Enabled to keep history of changes and prevent accidental deletions.
    - **Encryption**: Server-Side Encryption (SSE-S3) enabled by default.

2.  **Access Logging**:
    - A separate S3 bucket is created to store access logs from the website bucket.
    - Logs are stored in a `log/` prefix.

3.  **Lifecycle Management (Cost Optimization)**:
    - **Transition**: Logs older than **30 days** are moved to **GLACIER** storage class.
    - **Expiration**: Logs older than **90 days** are permanently deleted.

4.  **Pre-signed URL Demo**:
    -   A `secret.txt` file is uploaded to the **private** Log Bucket.
    -   Demonstrates secure, temporary access sharing without making the bucket public.

5.  **S3 Access Point ("Auditor")**:
    -   A specific entry point for the Log Bucket.
    -   Policy restricted to **only** allow access to `log/*` objects.
    -   Demonstrates how to provide granular access control for specific use cases (e.g., Auditing) without modifying the main bucket policy.

## Project Structure

```
aws_s3_demo/
├── main.tf        # Main Terraform configuration (Resources)
├── variables.tf   # Configuration variables
├── outputs.tf     # Output definitions (Website URL)
├── README.md      # This documentation
└── www/
    ├── index.html # Website entry point
    └── error.html # 404 Error page
```

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) installed (v1.0+).
- AWS Credentials configured (e.g., via `aws configure` or environment variables).

## Deployment

1.  **Initialize Terraform**:
    Downloads necessary providers.
    ```bash
    terraform init
    ```

2.  **Plan the Deployment**:
    Preview the changes Terraform will make.
    ```bash
    terraform plan
    ```

3.  **Apply Changes**:
    Provision the infrastructure.
    ```bash
    terraform apply
    ```
    *Type `yes` when prompted.*

4.  **Run the Demo Guide**:
    For a guided experience, run the included Python script:
    ```bash
    python3 demo_guide.py
    ```
    This script will read the Terraform outputs and walk you through the following steps interactively.

5.  **Manual Verification**:
    If you prefer to verify manually:
    -   **Access the Website**: Open the `website_endpoint` URL.
    -   **Test Pre-signed URLs**:
        -   Try the `secret_file_direct_url` (Expect 403).
        -   Run `s3_presign_command` and visit the generated URL.
    -   **Test Access Points**:
        -   Run `auditor_access_command`.
        -   Try accessing the secret file via the Access Point (Expect Access Denied).

## Clean Up

To destroy all resources and stop incurring costs:

```bash
terraform destroy
```
*Note: The buckets are configured with `force_destroy = true`, so they will be deleted even if they contain objects.*
