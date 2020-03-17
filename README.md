# Description
Modular terraform code which will deploy private TFE on AWS with external service mode

As external service TFE application will use S3 bucket for state file and snapshot as well as RDS(PostgreSQL)  for application configuration

# Pre-requirements
- [Terraform](https://www.terraform.io)
- [PTFE](https://www.terraform.io/docs/enterprise/index.html)
- License (provided by HashiCorp)
- Get Letsencrypt certificate (or any other valid)
- DNS [record](https://www.cloudflare.com/)
- [AWS](https://aws.amazon.com) account
  - we will use m5.large as [recommended](https://www.terraform.io/docs/enterprise/before-installing/reference-architecture/aws.html) type

# Terraform version
This module was written and tested with Terraform v0.12.20

# Assumptions
- You want to install private TFE using terraform code in external service mode
- You have access to AWS console where you can create you security credentials `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
- You configured your security credentials as your environment variables `~/.bash_profile` 

```
export AWS_ACCESS_KEY_ID=XXXX
export AWS_SECRET_ACCESS_KEY=XXXX
export AWS_DEFAULT_REGION=XXXX
```

# How to consume

```bash
git clone git@github.com:andrewpopa/ptfe-aws-es.git
cd ptfe-aws-es
```

- [`main.tf`](https://github.com/andrewpopa/ptfe-aws-es/blob/master/main.tf) file has all the configuration

As the installation it's modular it consume it's dependencies from separate modules. When you'll use this dependencies, you'll have a list of inputs/outputs variables for each of module which need to be populated.

## Dependencies
- [vpc](github.com/andrewpopa/terraform-aws-vpc) - AWS VPC provisioning
- [security-group](github.com/andrewpopa/terraform-aws-security-group) - AWS security group provisioning
- [alb](github.com/andrewpopa/terraform-aws-alb) - AWL application load balancer provisioning
- [rds](github.com/andrewpopa/terraform-aws-rds) - AWS RDS(postgreSQL) instance provisioning
- [ptfe-es](github.com/andrewpopa/terraform-aws-s3) - AWS S3 bucket for state files
- [ptfe-es-snapshot](github.com/andrewpopa/terraform-aws-s3) - AWSS3 bucket for TFE snapshot
- [dns](github.com/andrewpopa/terraform-cloudflare-dns) - Cloudflare DNS management
- [key-pair](github.com/andrewpopa/terraform-aws-key-pair) - SSH key-pair for EC2 instance
- [ec2](github.com/andrewpopa/terraform-aws-ec2) - AWS EC2 instance 
- [silent](https://github.com/andrewpopa/ptfe-aws-es/tree/master/modules/silent) - silent module which does installation and also has logic in case of EC2 instance fail to restore the latest snapshot

Beyond the inputs variables for dependencies which need to be populated, silent module has input and output variables.

## Inputs
| **Name**  | **Type** | **Default** | **Required** | **Description** |
| ------------- | ------------- | ------------- | ------------- | ------------- |
| aws_access_key_id | string |  | no | AWS access key id |
| aws_secret_access_key | string |  | no | AWS secrete access key |
| fqdn | string | module.dns.fqdn | yes | FQDN where you are deploying pTFE |
| dashboard_default_password | string |  | yes | Admin panel password |
| pg_dbname | string | module.rds.db_name | yes | RDS name |
| pg_netloc | string | module.rds.rds_ip | yes | RDS fqdn |
| pg_password | string | Password123# | yes | RDS password |
| pg_user | string | module.rds.db_username | yes | RDS user |
| s3_bucket_svc | string | module.ptfe-es.s3_bucket_id | yes | S3 bucket for state files |
| s3_region | string | module.ptfe-es.s3_bucket_region | yes | S3 region |
| s3_bucket_svc_snapshots | string | module.ptfe-es-snapshot.s3_bucket_id | yes | S3 bucket for snapshots |
| download_fullchain | string |  | yes | URL to download fullchain |
| download_private | string |  | yes | URL to download private key |
| download_license | string |  | yes | URL to download pTFE license file |

One all inputs variables are populated, you can proceed to run it

```bash
$ terraform init
$ terraform apply
```

## Outputs
| **Name**  | **Type** | **Description** |
| ------------- | ------------- | ------------- |
| ec2_public_ip | string | EC2 public ip |
| ec2_public_dns | string | EC2 public dns |
| rds_hostname | string | Bucket region |
| s3_configuration | string | S3 for state files |
| fqdn | string | FQDN to access the service |
| ssh_key | string | SSH command to access the instance directly if it's public |

# Private/Public deployment

To not expose the service directly to the internet, service will be deployed behind application load balancer, however in case you want to deploy it in public subnet for any reason you can choose subnet 

```hcl
module "ec2" {
  source   = "github.com/andrewpopa/terraform-aws-ec2"
  ami_type = "ami-0085d4f8878cddc81"
  subnet_id              = module.vpc.public_subnets[0] # substitute with `private_subnets`
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
```

# Failure imitation
Once service is available and we can login, we can imitate failure of the instance, keeping in mind that service is deployed as external service and EC2 instance failure doesn't mean data failure.

# Create snapshot
When application is up and running you can create snapshot in admin panel by clicking `Start Snapshot` button

![alt text](img/snapshot.png "Create snapshot")

Once snapshot is created you can check current state list, run the following

```bash
$ terraform state list
```

you'll see similar output, but bigger

```bash
module.alb.aws_lb_target_group_attachment.tf_attach_frontend[1]
module.dns.cloudflare_record.record_name
module.ec2.aws_instance.tf_ec2
module.key-pair.aws_key_pair.generated_key
module.key-pair.local_file.private_key_pem
```

mark EC2 instance as taint

```
$ terraform taint module.ec2.aws_instance.tf_ec2
Resource instance module.ec2.aws_instance.tf_ec2 has been marked as tainted.
```

run terraform apply, once again

```
$ terraform apply
```

Once terraform apply will finish, the new EC2 instance will be created and data will be restored from snapshot. The logic to restore from snapshot is inside silent module.

# TODO
- [ ] add automatic SSL certificate generation
