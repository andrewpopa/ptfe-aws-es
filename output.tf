output "ec2_public_ip" {
  value = module.ec2.ec2_public_ip
}

output "ec2_public_dns" {
  value = module.ec2.ec2_ec2_dns
}

output "rds_hostname" {
  value = module.rds.rds_ip
}

output "s3_configuration" {
  value = module.ptfe-es.s3_bucket_id
}

output "fqdn" {
  value = module.dns.fqdn
}

output "ssh_key" {
  value = "ssh <user>@${module.ec2.ec2_public_ip} -i ${module.key-pair.public_key_name}.pem"
}