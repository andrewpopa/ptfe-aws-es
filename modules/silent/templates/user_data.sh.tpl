#!/bin/bash

set -x

curl -o ${tls_cert} ${download_fullchain}
curl -o ${tls_key} ${download_private}
curl -o ${license_file} ${download_license}

# postgre schema
curl -o /tmp/postgresql.sql https://raw.githubusercontent.com/andrewpopa/ptfe-aws-es/master/files/postgresql.sql

# application settings
curl -o /tmp/application-settings.json https://raw.githubusercontent.com/andrewpopa/ptfe-aws-es/master/files/application-settings.json

sed -i 's/tf_aws_access_key_id/${aws_access_key_id}/g' /tmp/application-settings.json
sed -i 's#tf_aws_secret_access_key#${aws_secret_access_key}#g' /tmp/application-settings.json
sed -i 's/tf_enc_password/${dashboard_default_password}/g' /tmp/application-settings.json
sed -i 's/tf_hostname/${fqdn}/g' /tmp/application-settings.json
sed -i 's/tf_pg_dbname/${pg_dbname}/g' /tmp/application-settings.json
sed -i 's/tf_pg_netloc/${pg_netloc}/g' /tmp/application-settings.json
sed -i 's/tf_pg_password/${pg_password}/g' /tmp/application-settings.json
sed -i 's/tf_pg_user/${pg_user}/g' /tmp/application-settings.json
sed -i 's/s3_bucket_svc/${s3_bucket_svc}/g' /tmp/application-settings.json
sed -i 's/tf_s3_region/${s3_region}/g' /tmp/application-settings.json

# replicated settings
curl -o /tmp/replicated.conf https://raw.githubusercontent.com/andrewpopa/ptfe-aws-es/master/files/replicated.conf

sed -i 's/tf_password/${dashboard_default_password}/g' /tmp/replicated.conf
sed -i 's/tf_fqdn/${fqdn}/g' /tmp/replicated.conf
sed -i 's#tls_cert#${tls_cert}#g' /tmp/replicated.conf
sed -i 's#tls_key#${tls_key}#g' /tmp/replicated.conf
sed -i 's#settings_file#${settings_file}#g' /tmp/replicated.conf
sed -i 's#license_file#${license_file}#g' /tmp/replicated.conf

# silent restore settings
curl -o /tmp/silent_restore.sh https://raw.githubusercontent.com/andrewpopa/ptfe-aws-es/master/files/silent_restore.sh

sed -i 's/your_bucket_to_store_snapshots/${s3_bucket_svc_snapshots}/g' /tmp/silent_restore.sh
sed -i 's/region_of_the_bucket/${s3_region}/g' /tmp/silent_restore.sh
sed -i 's/aws_access_key_id/${aws_access_key_id}/g' /tmp/silent_restore.sh
sed -i 's#aws_secret_access_key#${aws_secret_access_key}#g' /tmp/silent_restore.sh

# replicated config to etc
sudo cp /tmp/replicated.conf /etc/replicated.conf

# download TF installer
curl -o /tmp/install.sh https://install.terraform.io/ptfe/stable
sudo chmod +x /tmp/install.sh

sudo apt-get update -y 
sudo apt-get install -y postgresql-client   
sudo apt-get install python3-pip -y

export LC_ALL=C
pip3 install awscli --upgrade --user
export PATH=/home/ubuntu/.local/bin:$PATH

export AWS_ACCESS_KEY_ID=${aws_access_key_id}
export AWS_SECRET_ACCESS_KEY=${aws_secret_access_key}
export AWS_DEFAULT_REGION=eu-central-1

export PGPASSWORD=${pg_password}; psql -h ${pg_netloc} -d ${pg_dbname} -U ${pg_user} -p ${pg_port} -a -q -f /tmp/postgresql.sql

#public_ip = $(curl http://169.254.169.254/latest/meta-data/public-ipv4)
#private_ip = $(curl http://169.254.169.254/latest/meta-data/local-ipv4)

# if snapshots already exist on S3 restore latest snapshot
(aws s3 ls s3://${s3_bucket_svc_snapshots}/files/db.dump) && {
  echo "Restoring everything from backup"
  sudo chmod +x /tmp/silent_restore.sh
  sudo bash /tmp/silent_restore.sh
}

# if there are no existing snapshots, perform fresh install
(aws s3 ls s3://${s3_bucket_svc_snapshots}/files/db.dump) || {
  echo "Performing fresh installation in silent mode"
  echo "Creating DBs"
  export PGPASSWORD=${pg_password}; psql -h ${pg_netloc} -d ${pg_dbname} -U ${pg_user} -p ${pg_port} -a -q -f /tmp/postgresql.sql
  sudo bash /tmp/install.sh no-proxy private-address=$(curl http://169.254.169.254/latest/meta-data/local-ipv4) public-address=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
}