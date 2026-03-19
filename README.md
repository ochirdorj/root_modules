# root_modules

Terraform root modules (live infrastructure configurations) that consume reusable Terraform modules. Each subdirectory is an independent Terraform workspace with its own remote state, deployed via a shared GitHub Actions CI/CD pipeline.

---

## Repository Structure

```
root_modules/
├── ami_builder/          # Builds pre-baked Ubuntu AMI for GitHub Actions runners
├── self_hosted_runner/   # Deploys the ephemeral self-hosted runner system
├── vpc/                  # VPC, subnets, NAT Gateway
├── scp/                  # Service Control Policies (AWS Organizations)
├── s3_bucket/            # S3 bucket resources
└── .github/
    ├── workflows/
    │   ├── terraform.yml           # Reusable Terraform CI/CD workflow
    │   ├── self_hosted_runner.yml  # Pipeline for self_hosted_runner
    │   ├── ami_builder.yml         # Pipeline for ami_builder
    │   ├── vpc.yml                 # Pipeline for vpc
    │   ├── scp.yml                 # Pipeline for scp
    │   └── s3_bucket.yml           # Pipeline for s3_bucket
    └── actions/
        └── terraform-setup/        # Composite action: init, auth, format check
```

---

## Key Modules

### [self_hosted_runner](./self_hosted_runner)
Deploys a Lambda-driven ephemeral GitHub Actions runner system. GitHub webhooks trigger Lambda functions that spin up EC2 Spot instances per job and terminate them on completion.

**Source module:** [github.com/ochirdorj/self_hosted_runner](https://github.com/ochirdorj/self_hosted_runner)

### [ami_builder](./ami_builder)
Builds a pre-baked Ubuntu AMI containing all runner dependencies (Node.js, Docker, Terraform, tflint, Checkov, AWS CLI). Output AMI is consumed by `self_hosted_runner`.

**Source module:** [github.com/ochirdorj/ami_builder](https://github.com/ochirdorj/ami_builder)

---

## CI/CD Pipeline

All modules share a reusable `terraform.yml` workflow with four stages:

```
PR / Push to main
      │
      ├─ security    tfsec + checkov static analysis
      ├─ validate    terraform fmt + validate + tflint
      ├─ plan        terraform plan (output posted as PR comment)
      └─ apply       terraform apply (main branch only, requires prod environment approval)
```

### Security Gates
Every PR is blocked until these pass:
- **tfsec** — Terraform security misconfiguration scanner
- **checkov** — Infrastructure compliance and best-practice checks
- **tflint** — Terraform linter for style and correctness

### self_hosted_runner Pipeline
Has two extra pre-steps before Terraform runs:

```
build-lambda     npm install + zip lambda_code_folder  (self-hosted runner)
prep-terraform   cache zips for terraform job          (self-hosted runner)
terraform        security → validate → plan → apply    (self-hosted runner)
```

### Runner Strategy
The `self_hosted_runner` and `ami_builder` pipelines run on **self-hosted runners** (`[self-hosted, linux, x64]`). All other pipelines default to GitHub-hosted `ubuntu-latest`. The runner type is controlled via the `runner` input on the reusable `terraform.yml` workflow.

---

## Remote State

Each root module stores Terraform state in S3 with DynamoDB locking:

| Module | State Key |
|---|---|
| `self_hosted_runner` | `self_hosted_runner/terraform.tfstate` |
| `ami_builder` | `ami_builder/terraform.tfstate` |
| `vpc` | `vpc/terraform.tfstate` |

State from one module can be referenced by another using `terraform_remote_state` data sources (e.g., `ami_builder` reads VPC outputs from the `vpc` state).

---

## Deployment Order

For a first-time setup, apply modules in this order:

```
1. vpc               → creates VPC, subnets, NAT Gateway
2. ami_builder       → builds runner AMI (references VPC remote state)
3. self_hosted_runner → deploys runner system (uses AMI ID from ami_builder)
```

---

## Authentication

Pipelines authenticate to AWS using **OIDC (OpenID Connect)** — no long-lived AWS access keys stored in GitHub Secrets. The `terraform-setup` composite action handles:
1. Configuring the Terraform version
2. Assuming the deployment IAM role via OIDC
3. Running `terraform init` with the S3 backend

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
