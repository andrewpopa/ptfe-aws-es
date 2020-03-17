module "vpc" {
  source = "github.com/andrewpopa/terraform-aws-vpc"

  # VPC
  cidr_block          = "172.16.0.0/16"
  vpc_public_subnets  = ["172.16.10.0/24", "172.16.11.0/24", "172.16.12.0/24"]
  vpc_private_subnets = ["172.16.13.0/24", "172.16.14.0/24", "172.16.15.0/24"]
  vpc_tags = {
    vpc            = "my-aws-vpc"
    public_subnet  = "public-subnet"
    private_subnet = "private-subnet"
    internet_gw    = "my-internet-gateway"
    nat_gateway    = "nat-gateway"
  }
}

module "security-group" {
  source = "github.com/andrewpopa/terraform-aws-security-group"

  # Security group
  security_group_name        = "my-aws-security-group"
  security_group_description = "my-aws-security-group-descr"
  ingress_ports              = [22, 443, 8800, 5432]
  tf_vpc                     = module.vpc.vpc_id
}

module "alb" {
  source = "github.com/andrewpopa/terraform-aws-alb"

  # Load balancer
  name_cert       = "ptfe-lb-certs"
  cert_body       = "${file("./cert1.pem")}"
  cert_chain      = "${file("./chain1.pem")}"
  priv_key        = "${file("./privkey1.pem")}"
  alb_name_prefix = "ptfe-loadbalancer"
  ssl_policy      = "ELBSecurityPolicy-2016-08"
  ec2_instance    = module.ec2.ec2_ec2_id
  tf_vpc          = module.vpc.vpc_id
  tf_subnet       = module.vpc.public_subnets
  sg_id           = module.security-group.sg_id
  lbports = {
    8800 = "HTTPS",
    443  = "HTTPS",
  }
  alb_tags = {
    lb = "alb-name"
  }
}

module "rds" {
  source                 = "github.com/andrewpopa/terraform-aws-rds"
  identifier             = "mydbname1"
  engine                 = "postgres"
  instance_class         = "db.m5.xlarge"
  engine_version         = "9.6"
  storage_type           = "gp2"
  allocated_storage      = 50
  db_name                = "postgres"
  db_password            = "Password123#"
  availability_zone      = "eu-central-1a"
  db_subnets             = module.vpc.private_subnets
  vpc_security_group_ids = module.security-group.sg_id
  db_tags = {
    rds_name    = "DBName1"
    rds_subnets = "DB subnets"
  }
  db_group_description = "DB-group-subnets"
}

module "ptfe-es" {
  source = "github.com/andrewpopa/terraform-aws-s3"
  bucket = "ptfe-external-svc"
  force_destroy = true
  region        = "eu-central-1"
  versioning    = true
  tags = {
    Name = "ptfe-external-services"
  }
}

module "ptfe-es-snapshot" {
  source = "github.com/andrewpopa/terraform-aws-s3"
  bucket = "ptfe-external-svc-snapshot"
  force_destroy = true
  region        = "eu-central-1"
  versioning    = true
  tags = {
    Name = "ptfe-external-services-snapshot"
  }
}

module "dns" {
  source        = "github.com/andrewpopa/terraform-cloudflare-dns"
  api_email     = "EMAIL-ADDRESS"
  api_token     = "CLOUDFLARE-API-TOKEN"
  zone_id       = "CLOUDFLARE-ZONEID-TOKEN"
  cf_domain     = "YOUR-DOMAIN"
  cf_sub_domain = "SUBDOMAIN"
  pointer       = module.alb.alb_dns_name
  record_type   = "CNAME"
}

module "key-pair" {
  source   = "github.com/andrewpopa/terraform-aws-key-pair"
}

module "iam-profile" {
  source = "github.com/andrewpopa/terraform-aws-iam-profile"
  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": ["s3:*"],
        "Resource": [
          "${module.ptfe-es.s3_bucket_arn}",
          "${module.ptfe-es-snapshot.s3_bucket_arn}"
        ]
      },
      {
        "Effect": "Allow",
        "Action": "s3:ListAllMyBuckets",
        "Resource": "arn:aws:s3:::*"
      }
    ]
  }
  EOF
}

module "ec2" {
  source   = "github.com/andrewpopa/terraform-aws-ec2"
  ami_type = "AMI-TYPE"
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = module.security-group.sg_id
  key_name               = module.key-pair.public_key_name
  public_key             = module.key-pair.public_key
  public_ip              = true
  user_data              = module.silent.silent_template
  instance_profile       = module.iam-profile.iam_instance_profile
  ec2_instance = {
    type          = "m5.large"
    root_hdd_size = 50
    root_hdd_type = "gp2"
  }

  ec2_tags = {
    ec2 = "my-ptfe-instance"
  }
}

module "silent" {
  source = "./modules/silent/"

  # DNS
  fqdn = module.dns.fqdn

  # Config
  dashboard_default_password = "Password123#"

  # RDS
  pg_dbname   = module.rds.db_name
  pg_netloc   = module.rds.rds_ip
  pg_port     = module.rds.db_port
  pg_password = "Password123#"
  pg_user     = module.rds.db_username

  # S3
  s3_bucket_svc = module.ptfe-es.s3_bucket_id
  s3_region     = module.ptfe-es.s3_bucket_region
  s3_bucket_svc_snapshots = module.ptfe-es-snapshot.s3_bucket_id

  # Certs
  tls_cert = "/tmp/fullchain1.pem"
  tls_key  = "/tmp/privkey1.pem"

  # Application file
  settings_file = "/tmp/application-settings.json"
  license_file  = "/tmp/hashicorp-andrei-popa---tam.rli"

  # Certificate and license path to download
  download_fullchain = "WHERE-FROM-DOWNLOAD-FULLCHAIN"
  download_private = "WHERE-FROM-DOWNLOAD-PRIVATEKEY"
  download_license  = "WHERE-FROM-DOWNLOAD-PTFELICENSE"
}