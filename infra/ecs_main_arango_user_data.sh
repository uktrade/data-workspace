#!/bin/bash
# install and start ecs agent 

mkdir /etc/ecs/
echo "ECS_CLUSTER=data-workspace-dev-a" >> /etc/ecs/ecs.config
sudo yum update -y ecs-init
sudo systemctl restart ecs
#echo "ECS_ENABLE_AWSLOGS_EXECUTIONROLE_OVERRIDE=true" >> /etc/ecs/ecs.config
# install the REX-Ray Docker volume plugin
#docker plugin install rexray/ebs "REXRAY_PREEMPT=true" "EBS_REGION=eu-west-2" --grant-all-permission
# restart the ECS agent. This ensures the plugin is active and recognized once the agent starts.
#sudo yum update -y ecs-init
#sudo systemctl restart ecs