#!/bin/bash
# install and start ecs agent 
sudo yum install -y awscli

EC2_INSTANCE_ID=$(ec2-metadata --instance-id | sed 's/instance-id: //')
aws ec2 attach-volume --volume-id ${EBS_VOLUME_ID} --instance-id $EC2_INSTANCE_ID --device /dev/xvdf --region ${EBS_REGION}
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

echo "ECS_CLUSTER=${ECS_CLUSTER}" >> /etc/ecs/ecs.config