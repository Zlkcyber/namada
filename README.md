# namada testnet configuration


# Full Node Build

## Install Rust
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y 
source $HOME/.cargo/env
```

## Install CometBFT
```bash
cd $HOME
mkdir cometbft
wget https://github.com/cometbft/cometbft/releases/download/v0.37.2/cometbft_0.37.2_linux_amd64.tar.gz
tar xvf cometbft_0.37.2_linux_amd64.tar.gz -C ./cometbft
chmod +x cometbft/cometbft
sudo mv cometbft/cometbft /usr/local/bin/
rm -rf cometbft*
```
To check that the installation was successful, you can run the following command
```bash
cometbft version
```
Which should output something like:
```
0.37.2
```

## Install Node
Install the current version of node binary.
```bash
USER="<YOUR USERNAME HERE>"
OPERATING_SYSTEM="Linux" # or "Darwin" for MacOS

latest_release_url=$(curl -s "https://api.github.com/repos/anoma/namada/releases/latest" | grep "browser_download_url" | cut -d '"' -f 4 | grep "$OPERATING_SYSTEM")
wget "$latest_release_url"
tar -xzvf namada-v0.31.0-Linux-x86_64.tar.gz
cd namada-v0.31.0-Linux-x86_64
sudo cp namada* /home/$USER/.cargo/bin/
```
To check that the installation was successful, you can run the following command
```bash
namada --version
```
Which should output something like:
```
Namada v0.31.0
```

## Join the network as pre-genesis validator
Once the chain-id has been distributed, it is possible to join the network with the CHAIN_ID:
```bash
export CHAIN_ID="shielded-expedition.b40d8e9055" ## (replace with the actual chain-id)  
export ALIAS="<ENTER YOU ALIAS HERE>" ## (replace with the actual chain-id)  
namada client utils join-network --chain-id $CHAIN_ID --genesis-validator $ALIAS
```

## Join the network as post-genesis validator
Once the chain-id has been distributed, it is possible to join the network with the CHAIN_ID:
```bash
export CHAIN_ID="shielded-expedition.b40d8e9055" ## (replace with the actual chain-id)  
namada client utils join-network --chain-id $CHAIN_ID
```

## Running namada as a systemd service
The below assumes you have installed namada from source, with `make install`. It at least assumes the respective binaries are in `/home/user/.cargo/bin/namada`.
```bash
which namada ## (should return /home/user/.cargo/bin/namada)
```
The below makes a service file for systemd, which will run namada as a service. This is useful for running a node in the background, and also for auto-restarting the node if it crashes.
```bash
sudo nano /etc/systemd/system/namadad.service
```
```
[Unit]
Description=namada
After=network-online.target

[Service]
User=$USER
WorkingDirectory=/home/$USER/.cargo/bin
ExecStart=/home/$USER/.cargo/bin/namada node ledger run
Restart=always
RestartSec=10
ExecStartPre=-/usr/bin/rm -rf /home/$USER/.local/share/namada/shielded-expedition.b40d8e9055/tx_wasm_cache /home/$USER/.local/share/namada/shielded-expedition.b40d8e9055/vp_wasm_cache
Environment="CMT_LOG_LEVEL=p2p:none,pex:error"
Environment="RUST_BACKTRACE=full"
Environment="COLORBT_SHOW_HIDDEN=1"
Environment="NAMADA_CMT_STDOUT=true"
Environment="NAMADA_LOG_COLOR=true"
Environment="NAMADA_LOG_FMT=pretty"
Environment="NAMADA_LOG_ROLLING=daily"
Environment="CHAIN_ID="shielded-expedition.b40d8e9055"
Environment="VALIDATOR_ALIAS=VALIDATOR_ALIAS"
StandardOutput=syslog
StandardError=syslog
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
```

Enable the service with the below commands:
```bash
sudo systemctl daemon-reload
sudo systemctl enable namadad
```
Now you can manage the node through systemd commands:
Run the node

```bash
sudo systemctl start namadad
```
Stop the node
```bash
sudo systemctl stop namadad
```
Restart the node
```bash
sudo systemctl restart namadad
```
Show node logs
```bash
sudo journalctl -u namadad -f -o cat
```

## Using a wallet from the namada extension

### Initializing a new validator account
The user must first generate a key pair for their validator account.
```bash
KEY_ALIAS="aliace"
namada wallet key gen --alias $KEY_ALIAS
```
Now choose a name for your validator:
```bash
export VALIDATOR_ALIAS="<your-validator-name>"
export EMAIL="<your-validator-email-for-communication>"
```

### Request tokens from faucet
Go to `<faucet url>` and input address

### Initiate Validator 

A validator account requires additional keys compared to a user account, so start by initializing a validator account:
```bash
namada client init-validator \
  --alias $VALIDATOR_ALIAS \  
  --account-keys $KEY_ALIAS \  
  --signing-keys $KEY_ALIAS \  
  --commission-rate <enter-your-commission-rate> \  
  --max-commission-rate-change <enter-decimal-rate> \  
  --email $EMAIL
```
It is also possible to convert an established account to a validator account:
```bash
namada client become-validator \  
--address $ESTABLISHED_ACCOUNT_ADDRESS \  
--signing-keys $KEY_ALIAS \  
--commission-rate <enter-your-commission-rate> \  
--max-commission-rate-change <enter-decimal-rate> \  
--email $EMAIL
```
The validator account will now have the same alias as the established account.
When initializing a validator account, it is also mandatory to specify both the commission-rate charged by the validator for delegation rewards (in decimal format) as well as the maximum-commission-rate-change per epoch in the commission-rate. Both are expressed as a decimal between 0 and 1. The standard for mainnet will be set by social consensus, but for testnets, the standard has been 0.01 and 0.05, respectively.
This command will generate the keys required for running a validator:
- Consensus key, which is used in `<consensus key usage>`.
- Validator account key for signing transactions on the validator account, such as token self-bonding, unbonding and withdrawal, validator keys, validity predicate, state and metadata updates.

Then, it submits a transaction to the ledger that generates the new validator account with established address, which can be used to receive new delegations.
The keys and the alias of the address will be saved in your wallet.

### Bond tokens to your validator

```bash
namada client bond \
 --source "${KEY_NAME}" \
 --validator "${VAL_NAME}" \
 --amount 1000
```

