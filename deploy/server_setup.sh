#!/bin/bash
# System setup

echo "Starting codedeploy server_setup.sh ..."

SCRIPTDIR=$(dirname $0)
FIRST_RUN_PATH="/codedeploy.server_setup"

# Update system packages
sudo yum update -y

# Tasks to only run once for a given server
if [ ! -e "$FIRST_RUN_PATH" ]; then
    # Install/setup AWS CW logging
    sudo yum install -y awslogs

    sudo chown root:root \
        "$SCRIPTDIR/files/awscli.conf" \
        "$SCRIPTDIR/files/awslogs.conf"

    sudo chmod 640 \
        "$SCRIPTDIR/files/awscli.conf" \
        "$SCRIPTDIR/files/awslogs.conf"

    sudo mv -f \
        "$SCRIPTDIR/files/awscli.conf" \
        "$SCRIPTDIR/files/awslogs.conf" \
        /etc/awslogs/

    # Install MySQL 5.7 (for taking backups)
    sudo wget https://dev.mysql.com/get/mysql80-community-release-el7-1.noarch.rpm
    sudo yum install -y https://dev.mysql.com/get/mysql80-community-release-el7-1.noarch.rpm
    sudo rm -f mysql80-community-release-el7-1.noarch.rpm
    sudo yum-config-manager --disable mysql-connectors-community
    sudo yum-config-manager --disable mysql-tools-community
    sudo yum-config-manager --disable mysql80-community
    sudo yum-config-manager --enable mysql57-community
    sudo yum install -y mysql-community-client

    # Ensure there are no updates to be applied
    sudo yum -y update

    # Prepare secure backup location
    sudo mkdir -p \
        ~ec2-user/mysqldump/bin \
        ~ec2-user/mysqldump/credentials \
        ~ec2-user/mysqldump/data \
        ~ec2-user/mysqldump/log

    sudo chmod 700 \
        ~ec2-user/mysqldump \
        ~ec2-user/mysqldump/credentials \
        ~ec2-user/mysqldump/data

    sudo chmod +x \
        "$SCRIPTDIR/files/s3_db_backup.sh" \
        "$SCRIPTDIR/files/s3_db_backup_all.sh"

    sudo mv -f \
        "$SCRIPTDIR/files/s3_db_backup.sh" \
        "$SCRIPTDIR/files/s3_db_backup_all.sh" \
        ~ec2-user/mysqldump/bin/

    sudo chown -R ec2-user:ec2-user ~ec2-user/mysqldump

    # Sync cron configuration
    sudo yum install -y jq

    AWS_REGION="eu-west-2"
    if [ "$DEPLOYMENT_GROUP_NAME" == "control-dev" ]; then
        AWS_REGION="eu-west-1"
    fi

    SSM_SECRETS_BUCKET_NAME=$(aws --region "$AWS_REGION" ssm get-parameter --name "/CCS/SECRETS_BUCKET_NAME" | jq -r ".Parameter.Value")

    sudo yum remove -y jq

    aws --region "$AWS_REGION" s3 sync s3://$SSM_SECRETS_BUCKET_NAME/control/cron ~ec2-user/cron

    # Configure cron tasks
    sudo chown root:root ~ec2-user/cron/*.cron
    sudo chmod 644 ~ec2-user/cron/*.cron
    sudo mv -f ~ec2-user/cron/*.cron /etc/cron.d/
    sudo rm -rf ~ec2-user/cron

    sudo touch "$FIRST_RUN_PATH"
fi

echo "Codedeploy server_setup.sh complete."
