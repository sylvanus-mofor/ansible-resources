#!/bin/bash
# Install Ansible using dnf
sudo dnf install -y ansible

# Create the sylva user and set the password to 'ansible'
sudo useradd sylva
echo "sylva:ansible" | sudo chpasswd

# Grant the sylva user passwordless sudo privileges
echo "sylva ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/sylva

# Enable password authentication and root login in SSH
sudo sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config
sudo sed -i "s/#PermitRootLogin yes/PermitRootLogin yes/g" /etc/ssh/sshd_config
sudo systemctl restart sshd

# Generate SSH key for sylva user
sudo -u sylva ssh-keygen -t rsa -f /home/sylva/.ssh/id_rsa -q -N ""
sudo chmod 700 /home/sylva/.ssh
sudo chmod 600 /home/sylva/.ssh/id_rsa

# Install expect for automating SSH key copying
sudo dnf install -y expect

# Array of host node IP addresses
REMOTE_NODES=("172.31.42.112" "172.31.38.84") # Replace & add more IPs as needed

# Loop through each IP address and copy the SSH key
for REMOTE_NODE in "${REMOTE_NODES[@]}"; do
    expect -c "
    spawn sudo -u sylva ssh-copy-id sylva@$REMOTE_NODE
    expect {
        \"*re you sure you want to continue connecting*\" { send \"yes\r\"; exp_continue }
        \"*pass*\" { send \"ansible\r\"; exp_continue }
        \"*Pass*\" { send \"ansible\r\" }
    }
    expect eof
    "
done


###########################################################################
#This sets us an ansible user called sylva with password 'ansible' and ssh access permissions compatible with Aws amazon linux 2023
#!/bin/bash
# Install Ansible using dnf
sudo dnf install -y ansible

# Create a Sylva user and set the password
sudo useradd sylva
echo "sylva:ansible" | sudo chpasswd

# Grant the Sylva user passwordless sudo privileges
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

# Array of host node IP addresses
REMOTE_NODES=("172.31.57.43" "172.31.48.95")

# Loop through each IP address and copy the SSH key
for REMOTE_NODE in "${REMOTE_NODES[@]}"; do
    expect -c "
    spawn sudo -u sylva ssh-copy-id sylva@$REMOTE_NODE
    expect {
        \"*re you sure you want to continue connecting*\" { send \"yes\r\"; exp_continue }
        \"*pass*\" { send \"ansible\r\"; exp_continue }
        \"*Pass*\" { send \"ansible\r\" }
    }
    expect eof
    "
done

##########################################################################
#Here is the same script now using variables instead of hardcoding and re-directing all output data to a log file for troubleshooting
#!/bin/bash

# Configuration Variables
USERNAME="sylva"
PASSWORD="ansible"
SSH_KEY_FILE="/home/${USERNAME}/.ssh/id_rsa"
REMOTE_NODES=("172.31.57.43" "172.31.48.95")
LOG_FILE="/var/log/ansible_setup.log"

# Redirect all output to log file
exec > >(tee -a ${LOG_FILE}) 2>&1

# Install Ansible and Expect
sudo dnf install -y ansible expect

# Create user and set password
sudo useradd -m -s /bin/bash ${USERNAME} || { echo "Failed to add user ${USERNAME}"; exit 1; }
echo "${USERNAME}:${PASSWORD}" | sudo chpasswd || { echo "Failed to set password for ${USERNAME}"; exit 1; }

# Grant passwordless sudo privileges
echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/${USERNAME} > /dev/null || { echo "Failed to set sudo privileges for ${USERNAME}"; exit 1; }

# Enable SSH password authentication and root login
sudo sed -i "s/^PasswordAuthentication no/PasswordAuthentication yes/" /etc/ssh/sshd_config
sudo sed -i "s/^#PermitRootLogin.*/PermitRootLogin yes/" /etc/ssh/sshd_config
sudo systemctl restart sshd || { echo "Failed to restart SSH service"; exit 1; }

# Generate SSH key for the user
sudo -u ${USERNAME} ssh-keygen -t rsa -f ${SSH_KEY_FILE} -q -N "" || { echo "Failed to generate SSH key"; exit 1; }
sudo chmod 700 /home/${USERNAME}/.ssh
sudo chmod 600 ${SSH_KEY_FILE}

# Copy SSH key to remote nodes
for REMOTE_NODE in "${REMOTE_NODES[@]}"; do
    expect -c "
    spawn sudo -u ${USERNAME} ssh-copy-id ${USERNAME}@${REMOTE_NODE}
    expect {
        \"*re you sure you want to continue connecting*\" { send \"yes\r\"; exp_continue }
        \"*pass*\" { send \"${PASSWORD}\r\"; exp_continue }
        \"*Pass*\" { send \"${PASSWORD}\r\" }
    }
    expect eof
    " || { echo "Failed to copy SSH key to ${REMOTE_NODE}"; }
done

# Revert SSH settings for improved security
# sudo sed -i "s/^PermitRootLogin yes/PermitRootLogin prohibit-password/" /etc/ssh/sshd_config
# sudo sed -i "s/^PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config
sudo systemctl restart sshd || { echo "Failed to restart SSH service"; exit 1; }

echo "Setup complete. Review ${LOG_FILE} for details."

