# ☁️ AWS S3 Advanced Demo (CLI Edition)
> **Part of My AWS Learning Journey 🚀**

This project demonstrates advanced **Amazon S3** features including **Static Website Hosting**, **Lifecycle Policies**, **Pre-signed URLs**, and **S3 Access Points**.

> **⚠️ Note**: This project uses the **AWS CLI** directly due to Lab Environment restrictions (Service Control Policies).

## 📂 Project Structure

| File | Description |
|------|-------------|
| `deploy.sh` | 🛠️ **Deploy**: Primary script to provision buckets & resources. |
| `fix_policy.sh` | 🔒 **Secure**: Enforces strict "Explicit Deny" on Access Points. |
| `demo_guide.py` | 🎤 **Present**: Interactive script to guide the demo. |
| `www/` | 🌐 **Content**: Static website files (`index.html`, etc.). |

## 🌟 Key Features

1.  **🏠 Static Website**: A public bucket hosting a simple HTML site.
2.  **📜 Log Bucket**: A private bucket receiving server access logs.
3.  **⏳ Lifecycle Rules**: Auto-archive logs to GLACIER (30 days) & expire (90 days).
4.  **🔐 Security & Access**:
    -   **Pre-signed URLs**: Temporary access to private files (`secret.txt`).
    -   **S3 Access Points**: Restricted endpoints (e.g., "Auditor" view).

## 🚀 Usage

### 1. Deploy Infrastructure
```bash
chmod +x deploy.sh
./deploy.sh
```

### 2. Run the Demo Guide
```bash
python3 demo_guide.py
```

### 🎬 Demo Guide: What to Expect

**Step 1: 🌐 Static Website Hosting**
-   **Action**: Open the provided URL.
-   **Outcome**: You see the "Welcome" page. 🎉

**Step 2: 🔗 Pre-signed URL (Security)**
-   **Direct Link**: ⛔ **403 Forbidden** (Private file).
-   **Pre-signed Link**: ✅ **Success** (Temporary access granted).

**Step 3: 🕵️‍♀️ S3 Access Points (Granular Control)**
-   **List Logs**: ✅ **Success** (Auditor allowed).
-   **Steal Secret**:
    -   *Initially*: ⚠️ **Success** (If Admin).
    -   *After `fix_policy.sh`*: ⛔ **Access Denied** (Strict Policy Enforced).
-   **Retry Pre-signed**: ✅ **Success** (Proof that APs don't break other access methods).

### 3. Demonstrate Strict Security
During the demo, run the fix script to show how to lock down access points:
```bash
./fix_policy.sh
```

## 🧹 Cleanup
To remove all resources:
```bash
# Delete Buckets
aws s3 rb s3://<website-bucket> --force
aws s3 rb s3://<log-bucket> --force

# Delete Access Point
aws s3control delete-access-point --name <ap-name> --account-id <account-id>
```
