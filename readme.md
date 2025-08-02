Aztec Full Node Setup

This repository contains a Bash script (setup_aztec_full_node.sh) to automate the installation and configuration of an Aztec full node on the alpha-testnet using Docker. 
The script is designed for Ubuntu-based systems (20.04 or 22.04) and follows the official Aztec documentation: 

How to Run a Full Node.Overview

The script:Prompts for required configuration (Ethereum L1 URLs, VPS IP, etc.).
Validates inputs and saves them to an .env file.
Installs dependencies (Docker, Docker Compose, etc.).
Sets up the Aztec node using Docker Compose.
Provides post-setup instructions for monitoring and claiming the "Apprentice" role on the Aztec Discord.

Prerequisites
Before running the script, 
ensure you have:
System Requirements:Ubuntu 20.04 or 22.04.
4-core CPU, 
6 GB RAM, 
25 GB storage, 
25 Mbps up/down network.
Root or sudo access.

Network Configuration:
Public IP address for your server (for P2P networking).
Firewall configured to allow ports 40400 (TCP/UDP) and 8080.

Ethereum L1 URLs:
Execution Client URL: From services like Alchemy, Infura, or your own Geth/Nethermind node (e.g., https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY).
Consensus Client URL: From services like Chainstack or a public beacon node (e.g., https://beacon-sepolia.drpc.org).

Optional:
Access to the Aztec Discord for support and role claiming.
A tool like jq (installed by the script) for parsing JSON responses.

Installation

Clone or Download the Script:

bash

wget <URL_TO_SCRIPT> -O setup_aztec_full_node.sh

Replace <URL_TO_SCRIPT> with the script’s download link or copy it to your server.
Make the Script Executable:bash

chmod +x setup_aztec_full_node.sh

Run the Script:bash

./setup_aztec_full_node.sh

Provide Configuration:
The script will prompt you for:
Ethereum L1 Execution Client URL: Your execution client endpoint (e.g., Alchemy or Infura).
Ethereum L1 Consensus Client URL: Your consensus client endpoint (e.g., Chainstack).
VPS Public IP Address: Your server’s public IP.
Data Directory (default: /home/aztec-node/data).
Network Name (default: alpha-testnet).
Log Level (default: debug).
Review the summary and type y to proceed or n to abort.

Script Actions:
Updates the system and installs dependencies (Docker, Docker Compose, jq).
Creates a data directory with appropriate permissions.
Saves configuration to an .env file.
Generates a docker-compose.yml file.
Starts the Aztec node in the background.
Checks the latest synced block number.

Post-SetupCheck Node Status:
Monitor logs to ensure the node is syncing:bash

sudo docker logs -f $(docker ps -q --filter ancestor=aztecprotocol/aztec:alpha-testnet)

Verify Sync Progress:
Check the latest synced block:bash

curl -s -X POST -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","method":"node_getL2Tips","params":[],"id":67}' http://localhost:8080 | jq -r '.result.proven.number'

Compare with the latest block on AztecScan.
Claim the "Apprentice" Role:Join the Aztec Discord.
Go to the operators | start-here channel and use /operator start with your block number and proof.
Get the proof for a block:bash

curl -s -X POST -H 'Content-Type: application/json' -d '{"jsonrpc":"2.0","method":"node_getArchiveSiblingPath","params":[<block-number>,<block-number>],"id":67}' http://localhost:8080 | jq -r '.result'

Replace <block-number> with the synced block number.

Secure the .env File:
The .env file contains sensitive URLs (e.g., API keys). Restrict access:bash

chmod 600 .env

Troubleshooting
Node Not Syncing:Verify ETHEREUM_HOSTS and L1_CONSENSUS_HOST_URLS are valid and accessible.
Check firewall settings for ports 40400 (TCP/UDP) and 8080.
Ensure your server’s IP is correct in P2P_IP.

Docker Issues:Confirm Docker is installed: docker --version.
Add your user to the Docker group if needed:bash

sudo usermod -aG docker $USER

Log out and back in after adding to the group.

P2P Errors:Non-critical errors like p2p:reqresp Error on libp2p subprotocol are common and usually indicate issues with other nodes. Check the Aztec Discord for network status.

General Support:

Check logs for detailed errors (see "Check Node Status" above).
Join the Aztec Discord for community help.
Monitor node status with tools like UptimeKuma or the @azteccheck_bot on Telegram.

Advanced Configuration

Custom Ports: Modify docker-compose.yml to change ports if 40400 or 8080 are in use.
Running a Sequencer or Prover: Add --sequencer to the entrypoint in docker-compose.yml or refer to the Aztec documentation for dedicated guides.
Log Levels: Adjust LOG_LEVEL in .env (e.g., info, debug, trace) for more or less verbosity.

Notes
No Rewards Guaranteed: 
Running a node may not guarantee airdrops or rewards. Check the Aztec Discord for updates.
Network Changes: The alpha-testnet configuration may change. Verify the latest setup in the Aztec documentation.
Hardware: Ensure your server meets the minimum requirements to avoid performance issues.
Security: Regularly update your system and Docker images:bash

sudo apt update && sudo apt upgrade -y
docker-compose pull

License

This script is provided as-is under the MIT License. Use at your own risk.CreditsBased on the official Aztec documentation.
Community insights from the Aztec Discord and related guides.

For issues or contributions, please open a pull request or contact the maintainers.

