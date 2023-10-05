#!/bin/bash
# Function to find subnet and allocation ID by instance name
find_subnet_and_allocation_id() {
  INSTANCE_NAME="owasp-juice2021"
  
  # Find the subnet ID based on the instance name
  SUBNET_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$INSTANCE_NAME" --query 'Reservations[].Instances[].SubnetId' --output text)
  if [ -z "$SUBNET_ID" ]; then
    echo "Instance with name '$INSTANCE_NAME' not found or subnet ID not specified in tags."
    exit 1
  fi

  # Find the Elastic IP Allocation ID based on the instance's subnet
  EIP_ALLOCATION_ID=$(aws ec2 describe-addresses --filters "Name=domain,Values=vpc" "Name=network-interface.subnet-id,Values=$SUBNET_ID" --query 'Addresses[].AllocationId' --output text)
  if [ -z "$EIP_ALLOCATION_ID" ]; then
    echo "Elastic IP Allocation ID not found for the subnet associated with instance '$INSTANCE_NAME'."
    exit 1
  fi

  echo "Found Subnet ID: $SUBNET_ID"
  echo "Found Allocation ID: $EIP_ALLOCATION_ID"
}

# Function to add a NAT Gateway
add_nat_gateway() {
    find_subnet_and_allocation_id "$INSTANCE_NAME"
    echo "Creating a NAT Gateway..."
    NAT_GATEWAY_ID=$(aws ec2 create-nat-gateway --subnet-id "$SUBNET_ID" --allocation-id "$EIP_ALLOCATION_ID" | jq -r '.NatGateway.NatGatewayId')
    echo "NAT Gateway created with ID: $NAT_GATEWAY_ID"
  
    echo "Waiting for the NAT Gateway to become available..."
    aws ec2 wait nat-gateway-available --nat-gateway-ids "$NAT_GATEWAY_ID"
  
    # Update your route table here
  
    echo "NAT Gateway setup complete."
}

# Function to remove a NAT Gateway
remove_nat_gateway() {
    find_subnet_and_allocation_id "$INSTANCE_NAME"
    echo "Deleting NAT Gateway with ID: $NAT_GATEWAY_ID"
    aws ec2 delete-nat-gateway --nat-gateway-id "$NAT_GATEWAY_ID"
    
    echo "Waiting for the NAT Gateway to be deleted..."
    aws ec2 wait nat-gateway-deleted --nat-gateway-ids "$NAT_GATEWAY_ID"
    
    # Remove the route from your route table here
    
    echo "NAT Gateway deletion complete."
}

# Main menu
echo "NAT Gateway Management Script"
echo "1. Add NAT Gateway"
echo "2. Remove NAT Gateway"
echo "3. Quit"

read -p "Select an option (1/2/3): " choice

case $choice in
  1)
    add_nat_gateway
    ;;
  2)
    remove_nat_gateway
    ;;
  3)
    echo "Exiting script."
    exit 0
    ;;
  *)
    echo "Invalid option. Please select 1, 2, or 3."
    exit 1
    ;;
esac
