#!/bin/bash
# Log file location
LOG_FILE="/var/log/user_data.log"

# Update package list and install Ansible and Git, logging output and errors
{
    echo "Starting package update and installation..." >> $LOG_FILE
    sudo apt update -y
    sudo apt install -y ansible git

    # Check if Ansible and Git are installed successfully
    if command -v ansible >/dev/null 2>&1 && command -v git >/dev/null 2>&1; then
        echo "Ansible and Git installed successfully." >> $LOG_FILE
    else
        echo "Installation of Ansible or Git failed." >> $LOG_FILE
        exit 1
    fi

    # Download the deployment file and run the playbook
    wget https://raw.githubusercontent.com/ngetichnicholas/Vivaldi20-Frontend/refs/heads/main/deploy/deployment.yaml -O /home/ubuntu/deployment.yaml

    # Run ansible-playbook if the file was downloaded successfully
    if [ -f /home/ubuntu/deployment.yaml ]; then
        ansible-playbook /home/ubuntu/deployment.yaml >> $LOG_FILE 2>&1
    else
        echo "Failed to download deployment.yaml" >> $LOG_FILE
        exit 1
    fi
} >> $LOG_FILE 2>&1