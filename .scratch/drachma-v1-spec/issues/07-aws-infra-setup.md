Type: task
Status: claimed

## Question

Provision the AWS infrastructure the spec assumes: an ECS Fargate cluster running two services (the FastAPI API and the sync worker) from one container image, an ECR repository for that image, and the networking (VPC, subnets, security groups, load balancer for the API service) to reach them. Also provision the sync pipeline's queueing: an SQS FIFO queue (`MessageGroupId = connection_id`) sitting between the API and the sync worker, a DLQ with `maxReceiveCount: 8`, and a CloudWatch alarm on DLQ depth (see [Sync worker retry handling](issues/04-sync-worker-retry-handling.md) for why). Requires an AWS account and IAM access the agent doesn't have — human-driven, with the agent scripting what it can (Dockerfile, task definitions, IaC) once account access exists.

## Comments

Scripted the AFK-able part: `infra/Dockerfile` (single image, per-service command override), `infra/terraform/` (VPC with public/private subnets, one NAT gateway, ALB + target group + HTTPS listener, ECR repo, ECS cluster, and both task definitions/services), and `infra/CHECKLIST.md` (the account-and-IAM steps that need a human: AWS account/IAM setup, ACM cert, Secrets Manager secret, first `terraform apply`, image build/push, DNS).

Still open until a human runs the checklist. Ticket stays `claimed`; re-run resolution once the infra exists, recording the ECR repo URL, ALB DNS name, and secret ARN in the answer (tickets 08 and 09 need them).

The [Sync worker retry handling](issues/04-sync-worker-retry-handling.md) resolution landed after the above Terraform was scripted, so `infra/terraform/` is still missing the SQS FIFO queue, its DLQ (`maxReceiveCount: 8`), and the CloudWatch alarm on DLQ depth. Add those to the Terraform before running the checklist.
