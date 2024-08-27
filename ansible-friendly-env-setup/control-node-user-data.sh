#!/bin/bash
# This sets up an Ansible user called sylva with password 'ansible' and SSH access permissions compatible with AWS Amazon Linux 2023
#####################3REMEMBER TO EDIT IP ADDRESSES IN LINE 31 and 59, 60
# Install Ansible using dnf
sudo dnf install -y ansible

# Create a Sylva user and set the password
sudo useradd sylva
echo "sylva:ansible" | sudo chpasswd

# Grant Sylva passwordless sudo privileges
echo "sylva ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/sylva

# Enable password authentication and root login in SSH
sudo sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config
sudo sed -i "s/#PermitRootLogin yes/PermitRootLogin yes/g" /etc/ssh/sshd_config
sudo systemctl restart sshd

# Generate SSH key for Sylva user
sudo -u sylva ssh-keygen -t rsa -f /home/sylva/.ssh/id_rsa -q -N ""
sudo chmod 700 /home/sylva/.ssh
sudo chmod 600 /home/sylva/.ssh/id_rsa

# Install expect for automating SSH key copying
sudo dnf install -y expect

# Delay to allow remote instances to fully boot and SSH to be ready
sleep 60

# Array of host node IP addresses
REMOTE_NODES=("172.31.57.43" "172.31.48.95")

# Loop through each IP address and attempt to copy the SSH key
for REMOTE_NODE in "${REMOTE_NODES[@]}"; do
    for i in {1..5}; do
        echo "Attempting to copy SSH key to $REMOTE_NODE, try $i..."
        expect -c "
        spawn sudo -u sylva ssh-copy-id -i /home/sylva/.ssh/id_rsa.pub sylva@$REMOTE_NODE
        expect {
            \"*re you sure you want to continue connecting*\" { send \"yes\r\"; exp_continue }
            \"*password*\" { send \"ansible\r\"; exp_continue }
            \"*pass*\" { send \"ansible\r\" }
        }
        expect eof
        " && break || sleep 10
    done
done

# Additional commands to set up the ansible configuration and hosts files
sudo mkdir -p /etc/ansible/hosts

# Create the ansible.cfg file
echo "[defaults]
inventory = /etc/ansible/hosts" | sudo tee /etc/ansible/ansible.cfg

# Create the hosts file
echo "[web]
# Manually add the IP addresses of the web servers.
54.237.225.220
54.175.107.221

[web:vars]
http_port=80

# Additional groups or variables can be defined here if needed
" | sudo tee /etc/ansible/hosts/hosts

sudo chown -R sylva:sylva /etc/ansible


# Revert SSH settings for improved security
# sudo sed -i "s/^PermitRootLogin yes/PermitRootLogin prohibit-password/" /etc/ssh/sshd_config
# sudo sed -i "s/^PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config
#sudo systemctl restart sshd

