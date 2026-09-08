Type: grilling
Status: claimed

## Question

How should the sync worker handle a failed Plaid webhook delivery or a failed `/transactions/sync` call? Needs a stated retry/backoff policy, a dead-letter path for repeated failures, and whether/how a user-visible staleness indicator surfaces when a Connection's Mirror data falls behind. The worker runs as an AWS ECS Fargate service, so consider AWS-native primitives (e.g. SQS as a durable queue in front of the worker) rather than in-process retry only.
