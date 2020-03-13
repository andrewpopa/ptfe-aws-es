variable "aws_access_key_id" {
  description = "AWS key id"
  type        = string
  default     = ""
}

variable "aws_secret_access_key" {
  description = "AWS access key"
  type        = string
  default     = ""
}

variable "fqdn" {
  description = "FQDN where ptfe has been deployed"
  type        = string
  default     = ""
}

variable "dashboard_default_password" {
  description = "PTFE dashboard password"
  type        = string
  default     = ""
}

variable "pg_dbname" {
  description = "RDS DB name"
  type        = string
  default     = ""
}

variable "pg_netloc" {
  description = "RDS aws FQDN"
  type        = string
  default     = ""
}

variable "pg_port" {
  description = "RDS port"
  type        = string
  default     = ""
}

variable "pg_password" {
  description = "DB password"
  type        = string
  default     = ""
}

variable "pg_user" {
  description = "RDS username"
  type        = string
  default     = ""
}

variable "s3_bucket_svc_snapshots" {
  description = "S# bucket name for svc"
  type        = string
  default     = ""
}

variable "s3_bucket_svc" {
  description = "S3 bucket name for svc"
  type        = string
  default     = ""
}

variable "s3_region" {
  description = "S3 region"
  type        = string
  default     = ""
}

variable "ec2_public_ip" {
  description = "EC2 public ip"
  type        = string
  default     = ""
}

variable "ec2_private_ip" {
  description = "EC2 private ip"
  type        = string
  default     = ""
}

variable "tls_cert" {
  description = "Fullchain certificate"
  type        = string
  default     = ""
}

variable "tls_key" {
  description = "Private key"
  type        = string
  default     = ""
}

variable "settings_file" {
  description = "PTFE setting file"
  type        = string
  default     = ""
}

variable "license_file" {
  description = "PTFE license file"
  type        = string
  default     = ""
}

variable "download_fullchain" {
  description = "Download path for fullchain certificate"
  type        = string
  default     = ""
}

variable "download_private" {
  description = "Download path fro private key"
  type        = string
  default     = ""
}

variable "download_license" {
  description = "Download path for PTFE license"
  type        = string
  default     = ""
}