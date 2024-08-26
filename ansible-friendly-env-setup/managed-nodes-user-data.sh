#!/bin/bash
sudo useradd ansible
sudo echo ansible:ansible | chpasswd
sudo echo "ansible ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
sudo sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config
sudo sed -i "s/.*#PermitRootLogin yes/PermitRootLogin yes/g" /etc/ssh/sshd_config
sudo service sshd restart

######################################################
#To create a user 'sylva', password "ansible" compatible with Amazon Linux 2023 AMI
#!/bin/bash
# Create a new user 'sylva'
sudo useradd sylva
# Set password for 'sylva' user
echo "sylva:ansible" | sudo chpasswd
# Grant 'sylva' user sudo privileges without requiring a password
echo "sylva ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers
# Enable password authentication for SSH
sudo sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config
# Permit root login via SSH
sudo sed -i "s/#PermitRootLogin yes/PermitRootLogin yes/g" /etc/ssh/sshd_config
# Restart SSH service to apply the changes
sudo systemctl restart sshd
