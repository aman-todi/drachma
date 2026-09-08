Type: task
Status: claimed

## Question

Provision the AWS infrastructure the spec assumes: an ECS Fargate cluster running two services (the FastAPI API and the sync worker) from one container image, an ECR repository for that image, and the networking (VPC, subnets, security groups, load balancer for the API service) to reach them. Requires an AWS account and IAM access the agent doesn't have — human-driven, with the agent scripting what it can (Dockerfile, task definitions, IaC) once account access exists.

## Comments

Scripted the AFK-able part: `infra/Dockerfile` (single image, per-service command override), `infra/terraform/` (VPC with public/private subnets, one NAT gateway, ALB + target group + HTTPS listener, ECR repo, ECS cluster, and both task definitions/services), and `infra/CHECKLIST.md` (the account-and-IAM steps that need a human: AWS account/IAM setup, ACM cert, Secrets Manager secret, first `terraform apply`, image build/push, DNS).

Still open until a human runs the checklist. Ticket stays `claimed`; re-run resolution once the infra exists, recording the ECR repo URL, ALB DNS name, and secret ARN in the answer (tickets 08 and 09 need them).
