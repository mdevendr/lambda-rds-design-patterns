# AWS Lambda → RDS Secure Access Patterns  
Secure Design Patterns for RDS Proxy, IAM Authentication & Secrets Manager

This repository provides **production-grade secure access patterns** for connecting AWS Lambda functions to Amazon RDS using modern, least-privilege, scalable design techniques.

It includes:

- Secure network architecture (multi-AZ RDS Proxy)
- IAM Authentication (SigV4 DB auth)
- Secrets Manager fallback path (Engine not supporting IAM Auth)
- VPC Endpoint designs (KMS, Secrets Manager, CloudWatch Logs)
- Engine compatibility matrix
- All 4 Lambda → RDS access patterns

This repo is intended for Cloud Architects, Serverless Engineers, and teams operating in **regulated environments** (PCI-DSS, DORA, ISO 27001, FS/Banking).

---



****Mahesh Devendran — Multi Cloud Architect & DevOps Leader | AWS | Azure | GCP | Kubernetes | CKA & Terraform Certified | Gen AI & Automation****
****https://www.linkedin.com/in/mahesh-devendran-83a3b214/****

---
##  Architecture Diagram

> **AWS Lambda → RDS Secure Design Patterns Architecture**

<img width="7408" height="3428" alt="architecture" src="https://github.com/user-attachments/assets/dd2d95e6-7bd2-4d6c-9e21-4c721aafbcdb" />


---

#  Secure Access Patterns Overview

Lambda can connect to RDS using **four valid access patterns**, depending on:

- RDS engine family  
- Security requirements  
- Desired performance  
- Whether IAM Authentication & RDS Proxy are supported  

---
---

##  Architecture

This architecture secures connectivity between AWS Lambda and Amazon RDS using:

- Multi-AZ **RDS Proxy** for connection pooling, failover, and scaling  
- **IAM Authentication (SigV4)** for passwordless DB access  
- **Secrets Manager** as a fallback pattern for engines without IAM Auth  
- **Private subnets** with NACL and SG isolation  
- **VPC Endpoints** (KMS, Secrets Manager, CloudWatch Logs) for private API access  
- **TLS 1.2/1.3** enforced between Proxy and RDS  
- **Engine compatibility matrix** defining valid Lambda→RDS patterns  

All paths follow least-privilege and zero-trust cloud networking principles.

---

##  Design Considerations

Key design decisions include:

- **Patterns**: Support for all 4 Lambda→RDS connection models (IAM Auth, Secrets, Proxy, Direct).  
- **Scaling**: RDS Proxy reduces connection storms from Lambda concurrency.  
- **Availability**: Proxy deployed across multiple AZs with ENIs and a single DNS endpoint.  
- **Performance**: IAM Auth tokens avoid Secrets Manager latency for supported engines.  
- **Compatibility**: Proxy + IAM Auth supported only for MySQL/PostgreSQL families.  
- **Maintainability**: Clear separation of responsibilities (Lambda IAM role, Proxy auth, RDS engine params).  
- **Cost**: Eliminates NAT Gateway for Lambda (VPCE route).

---

##  Security & Compliance

This architecture aligns with security best practices for regulated industries (PCI-DSS, ISO 27001, DORA):

- **Zero stored DB credentials** when using IAM Authentication  
- **Encryption everywhere** (AWS-managed + KMS CMKs)  
- **Private connectivity only** with required VPC endpoints  
- **IAM least-privilege** (`rds-db:connect`, `kms:Decrypt`, `secretsmanager:GetSecretValue`)  
- **TLS enforced** (`rds.force_ssl=1`, `require_secure_transport=ON`)  
- **Network isolation** with SG chaining: Lambda → Proxy → RDS  
- **No inbound access to Lambda or RDS**  
- **Audit logs** via CloudWatch Logs, CloudTrail, and Enhanced Monitoring  
- **Proxy abstracts failovers**, reducing credential exposure and operational risk  

This provides a strong security boundary layer and compliance-ready design for financial services, fintech, and regulated workloads.

---

#  **Pattern A — IAM Authentication via RDS Proxy (Recommended)**  
**Lambda → RDS Proxy → RDS (IAM DB Auth via SigV4)**

- No stored DB credentials  
- Most secure (zero password surface)  
- Best scalability due to connection pooling  
- Fully supports Multi-AZ failover  
- Fast warm connections  
- Works for:  
  ✔ RDS MySQL  
  ✔ RDS PostgreSQL  
  ✔ Aurora MySQL  
  ✔ Aurora PostgreSQL  
  ✔ Aurora Serverless v2  

**Use this whenever possible.**

---

#  **Pattern B — Secrets Manager via RDS Proxy (Fallback Path)**  
**Lambda → Secrets Manager → RDS Proxy → RDS**

Used when:

- The engine does NOT support IAM Auth  
- Older Aurora/MySQL/PG versions  
- Multi-language or legacy drivers that cannot generate SigV4 tokens  
- Static DB credentials required for certain workflows  

Still benefits from:

- Connection pooling  
- Proxy-based failover  
- Reduced connection storms

**Valid but secondary pattern.**

---

#  **Pattern C — Direct to RDS (IAM or Secrets)**  
**Lambda → RDS (Direct)**

- Supported for all engines  
- Works with IAM Auth for MySQL/PG  
- Works with Secrets Manager for every engine  
- No connection pooling  
- Suitable only for **low concurrency workloads**  

**Not recommended for scaling workloads.**

---

#  **Pattern D — Secrets Manager Direct (Legacy Engines Only)**  
**Lambda → Secrets Manager → RDS (Direct)**

Required for engines that **do not support**:

- RDS Proxy  
- IAM Authentication  

These engines MUST use static credentials + TLS:

- SQL Server  
- Oracle  
- MariaDB  
- RDS Custom (Oracle/SQL Server)

**This is the only secure choice for these engines.**

---

#  Engine Compatibility Matrix

|Engine           |   IAM  | Proxy |  Secrets   | Multi-AZ                |
|-----------------|--------|-------|------------|----------------------- -|
|MySQL            |   ✔   |  ✔    |   Optional | ✔                       |
|PostgreSQL       |   ✔   |  ✔    |   Optional | ✔                       |
|Aurora MySQL     |   ✔   |  ✔    |   Optional | ✔ (via Aurora storage)  |
|Aurora PG        |   ✔   |  ✔    |   Optional | ✔ (via Aurora storage)  |
|A. Srv v2        |   ✔   |  ✔    |   Optional | ✔ (via Aurora storage)  |
|A. Srv v1        |   ✖   |  ✖    |   ✔       |  ✖  (no HA standby)     |
|SQL Server       |   ✖   |  ✖    |   ✔       |  ✔  (edition-dependent) |
|Oracle           |   ✖   |  ✖    |   ✔       |  ✔  (Data Guard)        |
|MariaDB          |   ✖   |  ✖    |   ✔       |  ✔                      |
|RDS Custom       |   ✖   |  ✖    |   ✔       |  ✖  (no Multi-AZ)       |


---

#  Security Hardening Highlights

###  IAM Authentication (SigV4 DB Auth)
- No static DB password  
- 15-minute ephemeral tokens  
- Lambda IAM role controls DB access  

###  TLS 1.2/1.3 enforced
- `rds.force_ssl=1` (PostgreSQL)  
- `require_secure_transport=ON` (MySQL/Aurora)  

###  VPC Endpoints for private AWS API access
- Secrets Manager  
- KMS  
- CloudWatch Logs  

No NAT required. No public internet path.

###  RDS Proxy in Multi-AZ Subnet Group
- ENIs deployed per-AZ  
- Single proxy DNS endpoint  
- AWS routes Lambda to local AZ ENI  

###  SG/NACL Zero-Trust Controls
- Lambda SG → Proxy SG → RDS SG  
- Only DB port allowed  
- No inbound access to Lambda  

---

Feel free to fork and customize.







