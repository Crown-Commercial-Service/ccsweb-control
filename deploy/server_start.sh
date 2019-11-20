#!/bin/bash
# Start/enable application-related services

echo "Starting codedeploy server_start.sh ..."

sudo systemctl is-enabled --quiet awslogsd.service \
    || sudo systemctl enable awslogsd.service

sudo systemctl is-active --quiet awslogsd.service \
    || sudo systemctl start awslogsd.service

echo "Codedeploy server_start.sh complete."
