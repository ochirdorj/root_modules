# Project Summary: AWS Self-Hosted GitHub Actions Runner Infrastructure

## 1. What the Project Does Overall

This repository is a **production-grade, Terraform-based AWS infrastructure-as-code (IaC) project** that implements a fully automated, event-driven GitHub Actions self-hosted runner system — including the networking foundation, a custom pre-baked AMI, and an organization-level compliance enforcement layer.

At its core, the system eliminates the need for static, always-on CI/CD servers. When a GitHub Actions workflow job is triggered, a webhook fires into AWS, a Lambda function validates it, and a new ephemeral EC2 instance is launched (using Spot pricing when possible), runs exactly one job, and then terminates itself. The entire lifecycle — from webhook to compute to cleanup — is fully automated, serverless-orchestrated, and audit-trailed through Git.

The project is structured as a **Terraform monorepo** with independent root modules, each with its own remote state, deployed through a shared, reusable GitHub Actions CI/CD pipeline.

---

## 2. What Each Module Does

### `vpc/` — Foundational Networking

Provisions the AWS networking layer that all other compute resources rely on.

- **2 public subnets** (`10.0.1.0/24`, `10.0.2.0/24`) across `us-east-1a` and `us-east-1b`
- **2 private subnets** (`10.0.3.0/24`, `10.0.4.0/24`) for secure EC2 and Lambda placement
- **NAT Gateway** for outbound internet access from private subnets (required for runner software downloads and GitHub API calls)
- Multi-AZ design for high availability
- Delegates all resource creation to a reusable external module (`github.com/ochirdorj/vpc_module`)
- State stored at: `s3://ochirdorj-terraform-backend-bucket/infra/vpc_backend/terraform.tfstate`

---

### `ami_builder/` — Custom Runner AMI

Builds a hardened, pre-baked Ubuntu AMI that contains all GitHub Actions runner dependencies, so runners launch fast without bootstrapping from scratch.

Software baked into the AMI:
- GitHub Actions runner agent
- Node.js
- Docker
- Terraform
- tflint
- Checkov
- AWS CLI

- Uses a `t3.medium` builder instance running in a private subnet (VPC state read via `terraform_remote_state`)
- Delegates to an external module (`github.com/ochirdorj/ami_builder`)
- The resulting AMI ID is consumed by the `self_hosted_runner` module
- State stored at: `s3://ochirdorj-terraform-backend-bucket/infra/ami_builder/terraform.tfstate`

---

### `self_hosted_runner/` — Event-Driven Ephemeral Runner System

The centerpiece of the project. Implements a fully serverless, event-driven architecture for launching EC2-backed GitHub Actions runners on demand.

**Architecture flow:**

```
GitHub Workflow Triggered
        │
        ▼
  GitHub Webhook (workflow_job event)
        │
        ▼
  API Gateway (HTTP endpoint)
        │
        ▼
  Webhook Validator Lambda (Node.js)
  - HMAC-SHA256 signature validation
  - Constant-time comparison (anti-timing-attack)
  - Secret fetched from AWS Secrets Manager
        │
        ▼
  SQS Queue (decoupling + buffering)
  - DLQ after 3 failed receive attempts
        │
        ▼
  Runner Manager Lambda (ESM JavaScript)
  - Parses GitHub job metadata (jobId, runId, repo, owner)
  - Filters: only launch for jobs with `self-hosted` label
  - Fetches GitHub runner registration token via GitHub App auth
  - Tries Spot instance → falls back to On-Demand
  - Hash-based subnet selection (multi-AZ load distribution)
  - Idempotent launch via EC2 ClientToken
        │
        ▼
  EC2 Instance (from pre-baked AMI)
  - User-data script registers runner with GitHub
  - Runs job
  - Watchdog: 600s startup timeout, 120s idle limit
  - Self-terminates after job completes or timeout
```

**Key technical features:**
- **IMDSv2 enforced** (`http_tokens = required`, hop limit 2 for containers)
- **No public IP addresses** — instances run in private subnets
- **Spot-first strategy** with on-demand fallback
- **Concurrency prevention**: checks for existing runner before launching
- **Structured JSON logging** with job context
- **IAM least-privilege**: Lambda can only terminate instances tagged `Team=ap13`
- **Idempotency**: EC2 `ClientToken` prevents duplicate launches on retry

Infrastructure components provisioned:
- API Gateway (HTTP API)
- 2× Lambda functions (validator + runner manager)
- SQS queue + DLQ
- EC2 Launch Template
- IAM roles and policies (Lambda execution role, EC2 instance profile)
- CloudWatch Log Groups
- AWS Secrets Manager secret for webhook HMAC key

State stored at: `s3://ochirdorj-terraform-backend-bucket/infra/self_hosted_runner/terraform.tfstate`

---

### `scp/` — AWS Organizations Governance

Implements guardrails across the AWS Organization using Service Control Policies (SCPs). These policies are **preventive controls** — they block non-compliant API calls before they succeed, regardless of IAM permissions.

| Policy | What It Enforces |
|---|---|
| `tag_enforce_policy.json` | Denies resource creation (VPC, RDS, Lambda, KMS, SNS, SQS, EFS, Secrets Manager) without all 5 mandatory tags |
| `ec2_tag_policy.json` | Denies EC2 `RunInstances`, ECS `CreateCluster`, EKS `CreateCluster` without mandatory tags |
| `block_all_region_except_use1_2.json` | Denies all AWS API calls outside `us-east-1` and `us-east-2`; exempts global services (IAM, Route53, CloudFront, STS) |
| `block_mp_ami.json` | Denies `RunInstances` with AMIs from non-approved owners; whitelist includes AWS, Canonical, RedHat, Ubuntu |
| `block_service_accesss_root.json` | Denies all `ec2:*` actions to the root IAM principal |

**Mandatory tags enforced across the organization:**
- `Environment`
- `Managed_By`
- `Project`
- `Team`
- `Owner`

Applied to the `Security` organizational unit. State stored at: `s3://ochirdorj-terraform-backend-bucket/infra/scp_tag_enforcement/terraform.tfstate`

---

### `s3_bucket/` — S3 Bucket with Lifecycle Management

Provisions a hardened S3 bucket with comprehensive security and lifecycle configuration.

- **Public access**: Fully blocked (all 4 block settings enabled)
- **Versioning**: Configurable (suspended in this deployment)
- **Object Lock**: Disabled (configurable for WORM compliance)
- **Lifecycle rules**:
  - Current objects → `STANDARD_IA` after 60 days
  - Non-current versions → transitioned after 30 days
  - Objects expire after 365 days
- **Encryption**: Optional SSE-S3 or SSE-KMS
- **Access logging**: Enabled
- **Transfer acceleration**: Disabled
- **Cross-region replication**: Configurable

State stored at: `s3://ochirdorj-terraform-backend-bucket/infra/s3_bucket/terraform.tfstate`

---

## 3. Technologies and Tools Used

### Infrastructure as Code
| Tool | Version | Role |
|---|---|---|
| Terraform | ~1.13.0 | Core IaC provisioning |
| AWS Provider | ~6.10.0 | AWS resource management |
| archive provider | ~2.4 | Lambda deployment packaging |
| time provider | ~0.9 | Time-based resource dependencies |

### AWS Services
| Category | Services |
|---|---|
| Compute | EC2, Lambda, EC2 Spot Instances |
| Networking | VPC, Subnets, NAT Gateway, Security Groups, API Gateway |
| Messaging | SQS (with DLQ) |
| Storage | S3, EBS (encrypted) |
| Security | IAM, AWS Secrets Manager, AWS Organizations (SCPs) |
| Monitoring | CloudWatch Logs |
| Identity | OIDC (GitHub Actions → IAM role federation) |

### CI/CD
| Tool | Role |
|---|---|
| GitHub Actions | Pipeline orchestration |
| Reusable Workflows | DRY pipeline shared by all modules |
| Composite Actions | Encapsulated Terraform init + auth step |
| OIDC Federation | Keyless AWS authentication |

### Security & Code Quality
| Tool | Role |
|---|---|
| tfsec | Terraform security misconfiguration scanning |
| Checkov | Infrastructure compliance checks (CIS, SOC2, etc.) |
| tflint | Terraform linting and style enforcement |
| terraform fmt | Code formatting validation |
| HMAC-SHA256 | GitHub webhook signature validation |

### Languages
- **HCL (Terraform)**: All infrastructure definitions
- **JavaScript / Node.js (ESM)**: Lambda functions (webhook validator, runner manager)
- **Bash**: EC2 user-data runner startup and watchdog scripts

---

## 4. What Makes This Impressive from a DevOps Perspective

### No Long-Lived Credentials
The entire CI/CD pipeline authenticates to AWS using **OIDC (OpenID Connect)** — GitHub Actions receives a short-lived JWT that it exchanges for a temporary IAM role session. There are no static `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` secrets anywhere in the repository.

### Zero-Cost-at-Rest Runner Infrastructure
GitHub-hosted runners cost money whether you use them or not, at a per-minute rate. This system provisions EC2 compute **only when a job is queued** and terminates it **the moment the job finishes**. Spot instance pricing is tried first, achieving up to 70–90% compute cost reduction vs. on-demand.

### Self-Hosting the Pipeline That Manages Itself
The `self_hosted_runner` module's own CI/CD pipeline runs on the self-hosted runners it creates. This is a self-referential bootstrap: once the system is live, all subsequent infrastructure changes deploy through runners it spawned.

### Layered Security Model
- **Preventive controls** (SCPs): Block non-compliant actions at the Organizations level before they reach IAM
- **Detective controls**: CloudWatch Logs for all Lambda executions
- **Workload isolation**: Compute in private subnets, no public IPs, IMDSv2 required
- **Supply chain control**: AMI owner whitelist via SCP blocks unauthorized marketplace images
- **Anti-timing-attack**: Constant-time HMAC comparison in webhook validator

### DRY CI/CD Pipeline Architecture
Rather than duplicating pipeline logic across 5 modules, a single **reusable GitHub Actions workflow** (`terraform.yml`) is called by all module-specific workflows with a module path parameter. Any pipeline improvement — new security scanner, different approval gate — is made once and inherited everywhere.

### Cross-Module Dependency Management via Remote State
The `ami_builder` module reads VPC outputs via `terraform_remote_state` data sources instead of hardcoding subnet IDs. This means infrastructure dependencies are tracked in code and automatically resolved, enabling safe independent deployments.

### Production-Quality Failure Handling
- SQS DLQ captures webhook events that fail after 3 processing attempts (no lost jobs)
- Gmail alert integration on `terraform apply` failure with commit SHA, actor, and run URL for fast incident response
- EC2 Spot capacity `InsufficientInstanceCapacity` errors trigger automatic fallback to on-demand
- 600-second startup watchdog prevents zombie instances if runner fails to register

### Organizational Compliance as Code
The SCP module encodes compliance requirements — mandatory tagging, region restriction, root account lockdown — as versioned, reviewable, diff-able Terraform. Compliance posture is part of the same Git history as the application infrastructure.

---

## 5. Interesting Technical Decisions and Patterns

### Pre-Baked AMI vs. Bootstrap at Launch
**Decision**: Build a custom AMI with all runner dependencies pre-installed rather than installing them via user-data at launch time.

**Why it matters**: Cold-start time for a GitHub Actions runner that must install Node.js, Docker, Terraform, AWS CLI, etc. from scratch can exceed 3–5 minutes. With a pre-baked AMI, the runner registers with GitHub and is ready to accept jobs in under 60 seconds. The `ami_builder` module separates the slow "build" step (done once) from the fast "launch" step (done per job).

### Event-Driven SQS Decoupling
**Decision**: Place an SQS queue between the API Gateway webhook receiver and the Lambda that actually launches EC2 instances.

**Why it matters**: If GitHub fires a burst of webhooks (e.g., a matrix job with 50 parallel runs), API Gateway can absorb all of them instantly into SQS. The runner manager Lambda processes them at its own concurrency limit, preventing a thundering herd from overwhelming EC2 API rate limits. SQS also provides automatic retry semantics and DLQ for observability on failures.

### Idempotent EC2 Launches via ClientToken
**Decision**: Pass a deterministic `ClientToken` derived from job metadata to `RunInstances`.

**Why it matters**: SQS delivers messages *at-least-once*. Without idempotency, a retried SQS delivery could launch two runners for the same job, wasting money and potentially causing unexpected job failures. The `ClientToken` ensures EC2 treats duplicate launch requests as the same operation.

### Hash-Based Multi-AZ Subnet Selection
**Decision**: Use a modulo hash of the job ID to pick a subnet, rather than always launching in the same one.

**Why it matters**: Spot instance availability is AZ-specific. By distributing launches across subnets/AZs based on job ID, the system naturally spreads load and reduces the chance of hitting an AZ-level Spot capacity shortage.

### Watchdog Script Inside User-Data
**Decision**: The EC2 user-data script includes a bash watchdog that monitors the runner process and terminates the instance if it hasn't started within 600 seconds or has been idle for 120 seconds.

**Why it matters**: Without this, a runner that fails to register (network issue, bad token, etc.) would run indefinitely, burning cost. The watchdog is the last line of defense ensuring ephemeral instances are truly ephemeral — even in failure scenarios.

### Terraform Remote State as Cross-Module API
**Decision**: Use `terraform_remote_state` data sources to share outputs between modules rather than using a Terraform workspace or monolithic root module.

**Why it matters**: Each module has its own state, lifecycle, and blast radius. The VPC can be modified without touching the runner infrastructure, and vice versa. Remote state data sources make inter-module dependencies explicit and code-readable, functioning like a typed API contract between infrastructure layers.

### Composite GitHub Action for Setup
**Decision**: Encapsulate the Terraform setup logic (OIDC auth, plugin cache, `terraform init`) in a reusable composite action at `.github/actions/terraform-setup`.

**Why it matters**: With 5+ modules each running the same init sequence, a composite action means changes to init logic (e.g., updating Terraform version, changing backend config) are made in one place. This mirrors the same DRY principle applied to the reusable workflow.

---

## Deployment Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│  GitHub Actions CI/CD                                           │
│  ┌────────────┐  ┌──────────────┐  ┌──────┐  ┌─────────────┐  │
│  │  tfsec     │→ │  terraform   │→ │ plan │→ │apply (gated)│  │
│  │  checkov   │  │  fmt/validate│  │      │  │             │  │
│  └────────────┘  └──────────────┘  └──────┘  └─────────────┘  │
└─────────────────────────────────────────────────────────────────┘
         │ deploys (OIDC, no static keys)
         ▼
┌─────────────────────────────────────────────────────────────────┐
│  AWS Account (us-east-1)                                        │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  VPC (10.0.0.0/16)                                       │  │
│  │  ┌──────────────┐   ┌──────────────────────────────────┐ │  │
│  │  │ Public Subnets│  │ Private Subnets                  │ │  │
│  │  │ (NAT Gateway) │  │ ┌──────────┐  ┌──────────────┐   │ │  │
│  │  └──────────────┘  │ │ Lambda   │  │ EC2 Runners  │   │ │  │
│  │                    │ │ Functions│  │ (ephemeral,  │   │ │  │
│  │                    │ └──────────┘  │  Spot-first) │   │ │  │
│  │                    │               └──────────────┘   │ │  │
│  │                    └──────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  API Gateway → SQS → Lambda → EC2 (runner lifecycle)           │
│  AWS Organizations SCPs (preventive compliance controls)        │
│  S3 Remote State Buckets (per-module state isolation)          │
└─────────────────────────────────────────────────────────────────┘
```

---

## Module Dependency Order

```
1. vpc/                → Foundational networking
2. ami_builder/        → Custom runner AMI (reads VPC state)
3. self_hosted_runner/ → Event-driven runner system (uses AMI ID)
4. scp/                → Org governance (independent)
5. s3_bucket/          → Storage (independent)
```

---

## Terraform Remote State Locations

| Module | State Key |
|---|---|
| VPC | `infra/vpc_backend/terraform.tfstate` |
| AMI Builder | `infra/ami_builder/terraform.tfstate` |
| Self-Hosted Runner | `infra/self_hosted_runner/terraform.tfstate` |
| SCP | `infra/scp_tag_enforcement/terraform.tfstate` |
| S3 Bucket | `infra/s3_bucket/terraform.tfstate` |

All state stored in: `s3://ochirdorj-terraform-backend-bucket` with encryption enabled and DynamoDB state locking.
