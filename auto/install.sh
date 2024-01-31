#!/bin/bash

# Full Node Build
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y 
source $HOME/.cargo/env

# Install CometBFT
cd $HOME
mkdir cometbft
wget https://github.com/cometbft/cometbft/releases/download/v0.37.2/cometbft_0.37.2_linux_amd64.tar.gz
tar xvf cometbft_0.37.2_linux_amd64.tar.gz -C ./cometbft
chmod +x cometbft/cometbft
sudo mv cometbft/cometbft /usr/local/bin/
rm -rf cometbft*

# Check CometBFT version
cometbft version

# Install Node
# Replace the username and operating system
USER="<YOUR USERNAME HERE>"
OPERATING_SYSTEM="Linux" # or "Darwin" for MacOS

latest_release_url=$(curl -s "https://api.github.com/repos/anoma/namada/releases/latest" | grep "browser_download_url" | cut -d '"' -f 4 | grep "$OPERATING_SYSTEM")
wget "$latest_release_url"
tar -xzvf namada-v0.31.0-Linux-x86_64.tar.gz
cd namada-v0.31.0-Linux-x86_64
sudo cp namada* /home/$USER/.cargo/bin/

# Check Node version
namada --version

# Join the network as pre-genesis validator
# Replace with the actual chain-id and alias
export CHAIN_ID="shielded-expedition.b40d8e9055"
export ALIAS="<ENTER YOU ALIAS HERE>"
namada client utils join-network --chain-id $CHAIN_ID --genesis-validator $ALIAS

# Join the network as post-genesis validator
# Replace with the actual chain-id
export CHAIN_ID="shielded-expedition.b40d8e9055"
namada client utils join-network --chain-id $CHAIN_ID

# Running namada as a systemd service
# Make sure namada is installed from source

# Create a service file for systemd
echo "[Unit]
Description=namada
After=network-online.target

[Service]
User=$USER
WorkingDirectory=/home/$USER/.cargo/bin
ExecStart=/home/$USER/.cargo/bin/namada node ledger run
Restart=always
RestartSec=10
ExecStartPre=-/usr/bin/rm -rf /home/$USER/.local/share/namada/shielded-expedition.b40d8e9055/tx_wasm_cache /home/$USER/.local/share/namada/shielded-expedition.b40d8e9055/vp_wasm_cache
Environment=\"CMT_LOG_LEVEL=p2p:none,pex:error\"
Environment=\"RUST_BACKTRACE=full\"
Environment=\"COLORBT_SHOW_HIDDEN=1\"
Environment=\"NAMADA_CMT_STDOUT=true\"
Environment=\"NAMADA_LOG_COLOR=true\"
Environment=\"NAMADA_LOG_FMT=pretty\"
Environment=\"NAMADA_LOG_ROLLING=daily\"
Environment=\"CHAIN_ID=shielded-expedition.b40d8e9055\"
Environment=\"VALIDATOR_ALIAS=VALIDATOR_ALIAS\"
StandardOutput=syslog
StandardError=syslog
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/namadad.service

# Enable the service
sudo systemctl daemon-reload
sudo systemctl enable namadad

# Start node
sudo systemctl start namadad && sudo journalctl -u namadad -f -o cat
