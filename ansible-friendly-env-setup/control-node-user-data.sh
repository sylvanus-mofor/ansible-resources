#!/bin/bash
# Install Ansible using dnf
sudo dnf install -y ansible

# Create an Ansible user and set the password
sudo useradd ansible
echo "ansible:ansible" | sudo chpasswd

# Grant the Ansible user passwordless sudo privileges
echo "ansible ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/ansible

# Enable password authentication and root login in SSH
sudo sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config
sudo sed -i "s/#PermitRootLogin yes/PermitRootLogin yes/g" /etc/ssh/sshd_config
sudo systemctl restart sshd

# Generate SSH key for Ansible user
sudo -u ansible ssh-keygen -t rsa -f /home/ansible/.ssh/id_rsa -q -N ""
sudo chmod 700 /home/ansible/.ssh
sudo chmod 600 /home/ansible/.ssh/id_rsa

# Install expect for automating SSH key copying
sudo dnf install -y expect

# Array of host node IP addresses
REMOTE_NODES=("172.31.42.112" "172.31.38.84") # Replace & add more IPs as needed

# Loop through each IP address and copy the SSH key
for REMOTE_NODE in "${REMOTE_NODES[@]}"; do
    expect -c "
    spawn sudo -u ansible ssh-copy-id ansible@$REMOTE_NODE
    expect {
        \"*re you sure you want to continue connecting*\" { send \"yes\r\"; exp_continue }
        \"*pass*\" { send \"ansible\r\"; exp_continue }
        \"*Pass*\" { send \"ansible\r\" }
    }
    expect eof
    "
done
