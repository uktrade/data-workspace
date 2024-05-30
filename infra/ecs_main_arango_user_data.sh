#!/bin/bash
# install and start ecs agent 

EC2_INSTANCE_ID=$(ec2-metadata --instance-id | sed 's/instance-id: //')
aws ec2 attach-volume --volume-id vol-0496244e683c15b0a --instance-id ${EC2_INSTANCE_ID} --device /dev/xvdf --region eu-west-2
# Follow symlinks to find the real device
device=$(sudo readlink -f /dev/xvdf)
  # Wait for the drive to be attached
while [ ! -e $device ] ; do sleep 1 ; done
# Format /dev/sdh if it does not contain a partition yet
if [ "$(sudo file -b -s $device)" == "data" ]; then
sudo mkfs -t ext4 $device
fi
# Mount the drive
sudo mkdir -p /data
sudo mount $device /data

mkdir /etc/ecs/
echo "ECS_CLUSTER=data-workspace-dev-a" >> /etc/ecs/ecs.config
sudo yum install -y ecs-init
sudo systemctl restart ecs




