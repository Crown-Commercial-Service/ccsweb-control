#!/bin/bash
# Stop application-related services

echo "Starting codedeploy server_stop.sh ..."

# Service will not be installed on the first run
sudo systemctl list-unit-files awslogsd.service|grep -q '^awslogsd\.service\s'
if [ $? -eq 0 ]; then
    sudo systemctl is-active --quiet awslogsd.service \
        && sudo systemctl stop awslogsd.service
fi

echo "Codedeploy server_stop.sh complete."
