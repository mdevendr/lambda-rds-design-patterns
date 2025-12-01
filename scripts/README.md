# Scripts Directory

This folder contains reference scripts and IAM policies used in the 
**Lambda → RDS Secure Access Patterns** architecture.

## Files

### `lambda-iam-policy.json`
Full IAM policy for a Lambda function accessing RDS via:
- IAM Authentication (`rds-db:connect`)
- Secrets Manager (fallback path)
- KMS for decrypting secrets/env vars
- CloudWatch Logs
- X-Ray tracing

Matches the secure patterns defined in the architecture diagram.

### `lambda-iam-policy-minimal.json`
Minimal IAM policy required for any Lambda:
- CloudWatch Logs only

Useful as a baseline for least-privilege design.

### `rds-iam-auth-example.sql`
SQL examples for configuring IAM Authentication with:
- RDS MySQL
- RDS PostgreSQL
- Aurora variants

Creates a database user mapped to IAM and grants schema/table privileges.

---

## Notes
These scripts are **reference only** and should be adapted for:
- Environment-specific resource ARNs
- Database names
- KMS key IDs
- Secrets naming conventions
- Role-based access boundaries

Use them to build secure, least-privilege Lambda → RDS access paths.
