#!/bin/bash

# Finds all EC2 instances and waits for the server to intialize
# Connects via ssh with the key and asks the users which instance to connect to

# Use describe-instances command to get all EC2 instances and the IP addresses
instances=$(aws ec2 describe-instances --query 'Reservations[].Instances[].[InstanceId, PublicIpAddress, PrivateIpAddress, Tags[?Key==`Name`].Value | [0]]' --output text)

if [[ -z "$instances" ]]; then
    echo "No EC2 instances found in your account."
    exit 1
fi

# Check the number of instances
num_instances=$(grep -c '' <<< "$instances")

if [[ $num_instances -eq 1 ]]; then
    # If there is only one instance, automatically select it for SSH
    selected_ip=$(awk '{print $2}' <<< "$instances")
    internal_ip=$(awk '{print $3}' <<< "$instances")
    host_name=$(awk '{print $4}' <<< "$instances")
else
    echo "Starting servers. IP addresses of all EC2 instances in your account (public IP, private IP, hostname):"

    # Print a list of instances with their public IP addresses
    i=1
    while read -r instance_id ip_address; do
        if [[ -z "$ip_address" ]]; then
            echo "$i. Instance ID: $instance_id - No public IP address"
        else
            echo "$i. Instance ID: $instance_id - Public IP address: $ip_address $internal_ip $host_name "
            echo "Take a picture or note of these. "
        fi
        # start the instance (each one in this loop) and send the output to null
        aws ec2 start-instances --instance-ids $instance_id 1> /dev/null
        i=$((i+1))
    done <<< "$instances"
    echo "If using a bastion, connect to its public IP and then ssh into the internal IP of the other instance that does not have a public IP"
    # Prompt user to choose an instance by number
    read -p "Enter the number of the instance you want to SSH into (must have a public IP): " selected_num

    # Validate if the entered number is within the range of instances
    if ! [[ "$selected_num" =~ ^[1-9][0-9]*$ ]] || [[ "$selected_num" -gt "$num_instances" ]]; then        echo "Error: Invalid selection. Please enter a number from the list."
        exit 1
    fi

    # Get the selected IP address corresponding to the chosen number
    selected_ip=$(awk -v num="$selected_num" 'NR == num {print $2}' <<< "$instances")
fi

#Download update script
curl -O https://byui-cloud.github.io/cyber-201-materials/aws-terraform/update.sh && chmod a+x update.sh

echo "Connecting to the instance with IP (take note for RDP): $selected_ip..."
echo "Remember to turn everything off when you are done:"
echo "1 - Logout of the VM server: 'logout' and stop your instances in EC2 to save budget"
echo "For the Amazon Linux Mate with RDP, you have to enable RDP by setting the password once connected and rebuild the keys:"
echo “type ./update.sh once you are connected to do that”
read -p "Pausing for 45 seconds for the server to initialize. If it fails, try ./run201.sh again after a minute." -t 45

# Copy the key to the internal IP VM
scp -i private_key.pem private_key.pem "ec2-user@$selected_ip:/home/ec2-user/private_key.pem"
scp -i private_key.pem update.sh "ec2-user@$selected_ip:/home/ec2-user/update.sh"

# Initiate SSH session to the selected instance
ssh -i private_key.pem "ec2-user@$selected_ip"  # Replace 'ec2-user' with the appropriate SSH username for your EC2 instance



