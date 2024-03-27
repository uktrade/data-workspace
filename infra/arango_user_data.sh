#!/bin/bash
echo "ECS_CLUSTER=data-workspace-dev-a" >> /etc/ecs/ecs.config
# install the REX-Ray Docker volume plugin
docker plugin install rexray/ebs REXRAY_PREEMPT=true EBS_REGION=${EBS_REGION} --grant-all-permission
# restart the ECS agent. This ensures the plugin is active and recognized once the agent starts.
#sudo systemctl restart ecs