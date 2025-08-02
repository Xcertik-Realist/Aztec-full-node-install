#!/bin/bash

# Aztec Full Node Setup Script
# Based on: https://docs.aztec.network/the_aztec_network/guides/run_nodes/how_to_run_full_node
# Tested on Ubuntu 20.04/22.04
# Prompts for variables and saves them to .env

# Exit on any error
set -e

# Default values
DATA_DIR="/home/aztec-node/data"
NETWORK="alpha-testnet"
LOG_LEVEL="debug"

# Function to validate non-empty input
validate_input() {
    local input=$1
    local field_name=$2
    if [ -z "$input" ]; then
        echo "Error: $field_name cannot be empty."
        exit 1
    fi
}

# Step 1: Prompt for variables
echo "=== Aztec Full Node Setup ==="
echo "Please provide the following configuration details."

read -p "Enter Ethereum L1 Execution Client URL (e.g., https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY): " ETHEREUM_HOSTS
validate_input "$ETHEREUM_HOSTS" "Ethereum L1 Execution Client URL"

read -p "Enter Ethereum L1 Consensus Client URL (e.g., https://beacon-sepolia.drpc.org): " L1_CONSENSUS_HOST_URLS
validate_input "$L1_CONSENSUS_HOST_URLS" "Ethereum L1 Consensus Client URL"

read -p "Enter your VPS public IP address: " P2P_IP
validate_input "$P2P_IP" "VPS public IP address"

read -p "Enter data directory [default: $DATA_DIR]: " input_data_dir
DATA_DIR=${input_data_dir:-$DATA_DIR}

read -p "Enter network name [default: $NETWORK]: " input_network
NETWORK=${input_network:-$NETWORK}

read -p "Enter log level [default: $LOG_LEVEL]: " input_log_level
LOG_LEVEL=${input_log_level:-$LOG_LEVEL}

# Step 2: Confirm inputs
echo -e "\n=== Configuration Summary ==="
echo "Ethereum L1 Execution Client URL: $ETHEREUM_HOSTS"
echo "Ethereum L1 Consensus Client URL: $L1_CONSENSUS_HOST_URLS"
echo "VPS Public IP: $P2P_IP"
echo "Data Directory: $DATA_DIR"
echo "Network: $NETWORK"
echo "Log Level: $LOG_LEVEL"
read -p "Are these values correct? (y/n): " confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "Aborting setup. Please run the script again with correct values."
    exit 1
fi

# Step 3: Update system and install dependencies
echo "Updating system and installing dependencies..."
sudo apt update -y && sudo apt upgrade -y
sudo apt install -y ca-certificates curl gnupg docker.io jq

# Step 4: Install Docker Compose
echo "Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version

# Step 5: Remove any old Docker packages (clean up)
echo "Removing old Docker packages..."
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
    sudo apt-get remove -y $pkg || true
done

# Step 6: Add Docker's official GPG key and repository
echo "Setting up Docker repository..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update -y
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Step 7: Create data directory
echo "Creating data directory at $DATA_DIR..."
sudo mkdir -p "$DATA_DIR"
sudo chmod -R 777 "$DATA_DIR" # Ensure permissions for Docker

# Step 8: Create .env file for configuration
echo "Creating .env file..."
cat << EOF > .env
ETHEREUM_HOSTS=$ETHEREUM_HOSTS
L1_CONSENSUS_HOST_URLS=$L1_CONSENSUS_HOST_URLS
P2P_IP=$P2P_IP
DATA_DIRECTORY=$DATA_DIR
LOG_LEVEL=$LOG_LEVEL
EOF

# Step 9: Create Docker Compose configuration
echo "Creating docker-compose.yml..."
cat << EOF > docker-compose.yml
name: aztec-node
services:
  node:
    network_mode: host
    image: aztecprotocol/aztec:$NETWORK
    environment:
      ETHEREUM_HOSTS: "\${ETHEREUM_HOSTS}"
      L1_CONSENSUS_HOST_URLS: "\${L1_CONSENSUS_HOST_URLS}"
      DATA_DIRECTORY: \${DATA_DIRECTORY}
      P2P_IP: \${P2P_IP}
      LOG_LEVEL: \${LOG_LEVEL}
    entrypoint: >
      sh -c 'node --no-warnings /usr/src/yarn-project/aztec/dest/bin/index.js start --network $NETWORK --node --archiver'
    ports:
      - 40400:40400/tcp
      - 40400:40400/udp
      - 8080:8080
    volumes:
      - \${DATA_DIRECTORY}:/data
EOF

# Step 10: Source .env file
echo "Sourcing .env file..."
source .env

# Step 11: Start the Aztec node
echo "Starting Aztec full node..."
docker-compose up -d

# Step 12: Check node status
echo "Waiting for node to start (this may take a few minutes)..."
sleep 60 # Wait for initial sync to begin

# Check latest synced block
echo "Checking latest synced block..."
curl -s -X POST -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","method":"node_getL2Tips","params":[],"id":67}' http://localhost:8080 | jq -r '.result.proven.number'

# Step 13: Provide instructions for further steps
echo "Aztec full node setup complete!"
echo "To check node logs: sudo docker logs -f \$(docker ps -q --filter ancestor=aztecprotocol/aztec:$NETWORK)"
echo "To verify your node and claim the 'Apprentice' role, go to the Aztec Discord 'operators | start-here' channel and use '/operator start' with your block number and proof."
echo "To get the proof, run: curl -s -X POST -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"method\":\"node_getArchiveSiblingPath\",\"params\":[<block-number>,<block-number>],\"id\":67}' http://localhost:8080 | jq -r '.result'"
echo "Check the latest block number at: https://aztecscan.xyz/"
echo "Join the Aztec Discord for support: https://discord.com/invite/aztec"

exit 0
