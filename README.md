# root_modules

Terraform root modules (live infrastructure configurations) that consume reusable Terraform modules. Each subdirectory is an independent Terraform workspace with its own remote state, deployed via a shared GitHub Actions CI/CD pipeline.

---

## Repository Structure

```
root_modules/
├── ami_builder/          # Builds pre-baked Ubuntu AMI for GitHub Actions runners
├── self_hosted_runner/   # Deploys the ephemeral self-hosted runner system
│   ├── lambda_code_folder/   # Runner manager Lambda (ESM JavaScript)
│   └── webhook_validator/    # Webhook HMAC signature validator Lambda
├── vpc/                  # VPC, subnets, NAT Gateway
├── scp/                  # Service Control Policies (AWS Organizations)
│   └── policies/         # SCP JSON policy documents
├── s3_bucket/            # S3 bucket with lifecycle, encryption, and replication config
└── .github/
    ├── workflows/
    │   ├── terraform.yml           # Reusable Terraform CI/CD workflow
    │   ├── self_hosted_runner.yml  # Pipeline for self_hosted_runner
    │   ├── ami_builder.yml         # Pipeline for ami_builder
    │   ├── vpc.yml                 # Pipeline for vpc
    │   ├── scp.yml                 # Pipeline for scp
    │   └── s3_bucket.yml           # Pipeline for s3_bucket
    ├── actions/
    │   └── terraform-setup/        # Composite action: Terraform install, plugin cache, OIDC auth, init
    └── dependabot.yml              # Automated dependency updates for Actions and npm
```

---

## Key Modules

### [vpc](./vpc)
Creates the foundational networking layer: VPC, public/private subnets across two availability zones, NAT Gateway, and Internet Gateway.

**Source module:** [github.com/ochirdorj/vpc_module](https://github.com/ochirdorj/vpc_module)

**Outputs:** `vpc_id`, `public_subnet_ids`, `private_subnet_ids`, `nat_gateway_id`, `nat_gateway_ip`

**Default config:** `10.0.0.0/16` CIDR, `us-east-1a` / `us-east-1b`, two public + two private subnets

---

### [ami_builder](./ami_builder)
Builds a pre-baked Ubuntu AMI containing all runner dependencies (Node.js, Docker, Terraform, tflint, Checkov, AWS CLI). References VPC remote state to launch the builder instance in a private subnet.

**Source module:** [github.com/ochirdorj/ami_builder](https://github.com/ochirdorj/ami_builder)

**Default config:** `t3.medium` builder instance, `us-east-1`

---

### [self_hosted_runner](./self_hosted_runner)
Deploys a Lambda-driven ephemeral GitHub Actions runner system. GitHub webhooks are validated by the `webhook_validator` Lambda, queued to SQS, and consumed by the runner manager Lambda, which launches EC2 Spot instances per job. Instances self-terminate after the job completes or after 120 seconds of idle time.

**Source module:** [github.com/ochirdorj/self_hosted_runner](https://github.com/ochirdorj/self_hosted_runner)

**Lambda functions:**
- `lambda_code_folder/index.mjs` — Registers the runner with GitHub (via GitHub App + Octokit), launches a Spot EC2 instance with a user-data watchdog script, prevents duplicate launches using `ClientToken` idempotency
- `webhook_validator/index.js` — Validates GitHub webhook HMAC-SHA256 signatures (constant-time comparison), forwards valid events to SQS; rejects invalid ones with HTTP 401

**Default config:** Spot instance types `t3.medium`, `c5.large`, `c6i.large`; 30 GB root volume; runner labels `self-hosted, linux, x64`

---

### [scp](./scp)
Manages AWS Organizations Service Control Policies. The included policies enforce governance across accounts.

**Source module:** [github.com/ochirdorj/service_control_policy](https://github.com/ochirdorj/service_control_policy)

**Bundled policies (`scp/policies/`):**

| Policy file | Purpose |
|---|---|
| `tag_enforce_policy.json` | Deny resource creation unless all 5 tags are present: `Environment`, `Managed_By`, `Project`, `Team`, `Owner` — applies to EC2, RDS, Lambda, KMS, SNS, SQS, EFS, Secrets Manager |
| `block_all_region_except_use1_2.json` | Deny API calls outside `us-east-1` and `us-east-2` |
| `block_mp_ami.json` | Deny launching Marketplace AMIs |
| `block_service_accesss_root.json` | Restrict root account access to certain services |
| `ec2_tag_policy.json` | Additional EC2-specific tagging requirements |

**Default config:** Attaches `tag_enforce_policy.json` to the `Security` OU

---

### [s3_bucket](./s3_bucket)
Provisions a fully configurable S3 bucket with optional versioning, server-side encryption (SSE-S3 or SSE-KMS), lifecycle rules (transition + expiration for current and non-current versions), object lock, access block settings, transfer acceleration, static website hosting, and cross-region replication.

**Source module:** [github.com/ochirdorj/infra-core-storage-s3-bucket-template](https://github.com/ochirdorj/infra-core-storage-s3-bucket-template)

**Default config:** `sandbox-use1-ap13-s3-testing-example`, logging enabled, public access fully blocked

---

## CI/CD Pipeline

All modules share a reusable `terraform.yml` workflow with four stages:

```
PR / Push to main
      │
      ├─ security    tfsec + checkov static analysis
      ├─ validate    terraform fmt + validate + tflint
      ├─ plan        terraform plan (output posted as PR comment, artifact uploaded)
      └─ apply       terraform apply (main branch only, requires prod environment approval)
```

### Security Gates
Every PR is blocked until these pass:
- **tfsec** — Terraform security misconfiguration scanner
- **checkov** — Infrastructure compliance and best-practice checks
- **tflint** — Terraform linter for style and correctness

### self_hosted_runner Pipeline
Has three jobs before handing off to the reusable workflow:

```
build-lambda     npm install --omit=dev + zip lambda_code_folder and webhook_validator  (ubuntu-latest)
prep-terraform   download artifacts, cache zips for terraform job                       (ubuntu-latest)
terraform        security → validate → plan → apply                                     (self-hosted runner)
```

The zip caching step is required because the reusable workflow runs on a fresh runner and cannot access artifacts from parent workflow jobs directly.

### Runner Strategy
The `self_hosted_runner` and `ami_builder` pipelines run on **self-hosted runners** (`[self-hosted, linux, x64]`). All other pipelines default to GitHub-hosted `ubuntu-latest`. The runner type is controlled via the `runner` input on the reusable `terraform.yml` workflow.

---

## Terraform Setup Action

The composite action at `.github/actions/terraform-setup` is shared by all module pipelines and performs:
1. Installs the specified Terraform version (`hashicorp/setup-terraform@v4.0.0`)
2. Caches Terraform plugins and the `.terraform` directory to speed up subsequent runs
3. Assumes the deployment IAM role via **OIDC** (`aws-actions/configure-aws-credentials@v6.0.0`)
4. Runs `terraform init` (with optional `-upgrade` flag)

---

## Remote State

Each root module stores Terraform state in S3 with DynamoDB locking. State bucket: `ochirdorj-terraform-backend-bucket`.

| Module | State Key |
|---|---|
| `vpc` | `infra/vpc_backend/terraform.tfstate` |
| `ami_builder` | `infra/ami_builder/terraform.tfstate` |
| `self_hosted_runner` | `self_hosted_runner/terraform.tfstate` |
| `scp` | `scp/terraform.tfstate` |
| `s3_bucket` | `s3_bucket/terraform.tfstate` |

State from one module can be referenced by another using `terraform_remote_state` data sources (e.g., `ami_builder` reads VPC outputs from the `vpc` state to place the builder instance in the correct subnet).

---

## Deployment Order

For a first-time setup, apply modules in this order:

```
1. vpc                → creates VPC, subnets, NAT Gateway
2. ami_builder        → builds runner AMI (references VPC remote state)
3. self_hosted_runner → deploys runner system (uses AMI ID from ami_builder)
4. scp                → attaches governance policies to AWS Organization OUs
5. s3_bucket          → provisions S3 resources (independent of above)
```

---

## Authentication

Pipelines authenticate to AWS using **OIDC (OpenID Connect)** — no long-lived AWS access keys stored in GitHub Secrets. The `terraform-setup` composite action handles role assumption automatically.

Required GitHub secrets:
- `AWS_PROD_ROLE_ARN` — IAM role ARN to assume via OIDC
- `AWS_REGION` — Target AWS region

---

## Failure Alerting

On a failed `terraform apply`, the pipeline sends an email alert via Gmail SMTP containing:
- The failed module name
- The triggering actor and commit SHA
- A direct link to the GitHub Actions run

Required GitHub variables/secrets: `MAIL_USERNAME`, `MAIL_PASSWORD`, `MAIL_RECIPIENT`

---

## Dependency Updates

Dependabot is configured to automatically open PRs (up to 5 open at a time) for:
- **GitHub Actions** — weekly, every Monday at 09:00
- **npm** (`self_hosted_runner/lambda_code_folder`) — weekly, every Monday at 09:00
