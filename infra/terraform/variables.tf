variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Name prefix for all resources"
  type        = string
  default     = "drachma"
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones to spread subnets across"
  type        = number
  default     = 2
}

variable "container_image" {
  description = "Full ECR image URI:tag, set after the first `docker push`"
  type        = string
  default     = null
}

variable "api_container_port" {
  type    = number
  default = 8000
}

variable "api_desired_count" {
  type    = number
  default = 1
}

variable "worker_desired_count" {
  type    = number
  default = 1
}

variable "api_cpu" {
  type    = number
  default = 256
}

variable "api_memory" {
  type    = number
  default = 512
}

variable "worker_cpu" {
  type    = number
  default = 256
}

variable "worker_memory" {
  type    = number
  default = 512
}

variable "acm_certificate_arn" {
  description = "ACM cert for the ALB's HTTPS listener (see CHECKLIST.md)"
  type        = string
  default     = null
}

variable "task_env_secrets_arn" {
  description = "ARN of the Secrets Manager secret holding SUPABASE_URL, SUPABASE_SERVICE_KEY, DEEPSEEK_API_KEY, STRIPE_SECRET_KEY, etc. (see CHECKLIST.md)"
  type        = string
  default     = null
}
