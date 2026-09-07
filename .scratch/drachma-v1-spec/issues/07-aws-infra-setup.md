Type: task
Status: open

## Question

Provision the AWS infrastructure the spec assumes: an ECS Fargate cluster running two services (the FastAPI API and the sync worker) from one container image, an ECR repository for that image, and the networking (VPC, subnets, security groups, load balancer for the API service) to reach them. Requires an AWS account and IAM access the agent doesn't have — human-driven, with the agent scripting what it can (Dockerfile, task definitions, IaC) once account access exists.
