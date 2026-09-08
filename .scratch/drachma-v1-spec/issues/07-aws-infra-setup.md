Type: task
Status: open

## Question

Provision the AWS infrastructure the spec assumes: an ECS Fargate cluster running two services (the FastAPI API and the sync worker) from one container image, an ECR repository for that image, and the networking (VPC, subnets, security groups, load balancer for the API service) to reach them. Also provision the sync pipeline's queueing: an SQS FIFO queue (`MessageGroupId = connection_id`) sitting between the API and the sync worker, a DLQ with `maxReceiveCount: 8`, and a CloudWatch alarm on DLQ depth (see [Sync worker retry handling](issues/04-sync-worker-retry-handling.md) for why). Requires an AWS account and IAM access the agent doesn't have — human-driven, with the agent scripting what it can (Dockerfile, task definitions, IaC) once account access exists.
