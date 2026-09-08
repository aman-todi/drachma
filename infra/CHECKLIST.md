# AWS infra setup — human checklist

Resolves [AWS infra setup](../.scratch/drachma-v1-spec/issues/07-aws-infra-setup.md).
Scripted parts (Dockerfile, Terraform) live in this directory; the steps
below need an AWS account and IAM access the agent doesn't have.

1. **Create the AWS account** (or pick the one this will live in) and enable
   MFA on the root user.
2. **Create an IAM user or role for Terraform** with permissions for: EC2
   (VPC/subnets/security groups), ECS, ECR, IAM (role creation — this needs
   `iam:PassRole` and `iam:CreateRole` scoped to `${project}-ecs-*`),
   Elastic Load Balancing, CloudWatch Logs, and Secrets Manager. Configure
   the AWS CLI locally with its credentials (`aws configure`).
3. **Request an ACM certificate** for the API's domain (`api.<yourdomain>`)
   in the same region as `var.region`, validate it (DNS validation via your
   registrar), and note its ARN.
4. **Create the Secrets Manager secret** the task definitions read from —
   one JSON secret with keys `SUPABASE_URL`, `SUPABASE_SERVICE_KEY`,
   `DEEPSEEK_API_KEY`, `STRIPE_SECRET_KEY`, `PLAID_CLIENT_ID`,
   `PLAID_SECRET` — and note its ARN.
5. **(Optional but recommended) create an S3 bucket for Terraform state**
   and uncomment the `backend "s3"` block in `terraform/main.tf`.
6. **First apply**, to create the ECR repository before an image exists:
   ```
   cd infra/terraform
   terraform init
   terraform apply \
     -var="acm_certificate_arn=<arn from step 3>" \
     -var="task_env_secrets_arn=<arn from step 4>" \
     -target=aws_ecr_repository.app
   ```
7. **Build and push the image**:
   ```
   aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <account-id>.dkr.ecr.<region>.amazonaws.com
   docker build -t <ecr_repository_url>:v1 -f infra/Dockerfile .
   docker push <ecr_repository_url>:v1
   ```
8. **Full apply**, now that an image exists:
   ```
   terraform apply \
     -var="container_image=<ecr_repository_url>:v1" \
     -var="acm_certificate_arn=<arn from step 3>" \
     -var="task_env_secrets_arn=<arn from step 4>"
   ```
9. **Point DNS** (`api.<yourdomain>`) at the `alb_dns_name` output (a CNAME,
   or an ALIAS if the zone is Route 53).
10. Confirm the API service goes healthy: `GET https://api.<yourdomain>/healthz`
    should return 200 once the FastAPI app implements that route (build
    session's job — the target group's health check already expects it).

Record the resulting ECR repo URL, ALB DNS name, and secret ARN on the
ticket's `## Answer` once this is done — later tickets (Supabase and Stripe
setup) reference them.
