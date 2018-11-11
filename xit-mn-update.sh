#!/bin/bash

# Make sure curl is installed
apt-get -qq update
apt -qqy install curl
clear

TARBALLURL=$(curl -s https://api.github.com/repos/IttriumCore/ittrium/releases/latest | grep browser_download_url | grep -e "ittrium.*linux64" | cut -d '"' -f 4)
TARBALLNAME=$(curl -s https://api.github.com/repos/IttriumCore/ittrium/releases/latest | grep browser_download_url | grep -e "ittrium.*linux64" | cut -d '"' -f 4 | cut -d "/" -f 9)
XITVERSION=$(curl -s https://api.github.com/repos/IttriumCore/ittrium/releases/latest | grep browser_download_url | grep -e "ittrium.*linux64" | cut -d '"' -f 4 | cut -d "/" -f 8)

clear
echo "This script will update your masternode to version $XITVERSION"
read -rp "Press Ctrl-C to abort or any other key to continue. " -n1 -s
clear

if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root."
  exit 1
fi

USER=$(ps -o user= -p "$(pgrep ittriumd)")
USERHOME=$(eval echo "~$USER")

echo "Downloading new version..."
wget "$TARBALLURL"

echo "Shutting down masternode..."
if [ -e /etc/systemd/system/ittrium.service ]; then
  systemctl stop ittrium.service
else
  su -c "ittrium-cli stop" "$USER"
fi

echo "Installing Ittrium $XITVERSION..."
rm /usr/local/bin/ittriumd /usr/local/bin/ittrium-cli
tar -xzvf "$TARBALLNAME" -C /usr/local/bin
rm "$TARBALLNAME"

if [ -e /usr/bin/ittriumd ];then rm -rf /usr/bin/ittriumd; fi
if [ -e /usr/bin/ittrium-cli ];then rm -rf /usr/bin/ittrium-cli; fi
if [ -e /usr/bin/ittrium-tx ];then rm -rf /usr/bin/ittrium-tx; fi

# Remove addnodes from ittrium.conf
sed -i '/^addnode/d' "$USERHOME/.ittrium/ittrium.conf"

# Add Fail2Ban memory hack if needed
if ! grep -q "ulimit -s 256" /etc/default/fail2ban; then
  echo "ulimit -s 256" | sudo tee -a /etc/default/fail2ban
  systemctl restart fail2ban
fi

echo "Restarting Ittrium daemon..."
if [ -e /etc/systemd/system/ittrium.service ]; then
  systemctl disable ittrium.service
  rm /etc/systemd/system/ittrium.service
fi

cat > /etc/systemd/system/ittrium.service << EOL
[Unit]
Description=Ittriums's distributed currency daemon
After=network.target
[Service]
Type=forking
User=${USER}
WorkingDirectory=${USERHOME}
ExecStart=/usr/local/bin/ittriumd -conf=${USERHOME}/.ittrium/ittrium.conf -datadir=${USERHOME}/.ittrium
ExecStop=/usr/local/bin/ittrium-cli -conf=${USERHOME}/.ittrium/ittrium.conf -datadir=${USERHOME}/.ittrium stop
Restart=on-failure
RestartSec=1m
StartLimitIntervalSec=5m
StartLimitInterval=5m
StartLimitBurst=3
[Install]
WantedBy=multi-user.target
EOL
sudo systemctl enable ittrium.service
sudo systemctl start ittrium.service

sleep 10

clear

if ! systemctl status ittrium.service | grep -q "active (running)"; then
  echo "ERROR: Failed to start ittriumd. Please contact support."
  exit
fi

echo "Waiting for wallet to load..."
until su -c "ittrium-cli getinfo 2>/dev/null | grep -q \"version\"" "$USER"; do
  sleep 1;
done

clear

echo "Your masternode is syncing. Please wait for this process to finish."
echo "This can take up to a few hours. Do not close this window."
echo ""

until su -c "ittrium-cli mnsync status 2>/dev/null | grep '\"IsBlockchainSynced\": true' > /dev/null" "$USER"; do 
  echo -ne "Current block: $(su -c "ittrium-cli getblockcount" "$USER")\\r"
  sleep 1
done

clear

cat << EOL
Now, you need to start your masternode. If you haven't already, please add this
node to your masternode.conf now, restart and unlock your desktop wallet, go to
the Masternodes tab, select your new node and click "Start Alias."
EOL

read -rp "Press Enter to continue after you've done that. " -n1 -s

clear

su -c "ittrium-cli masternode status" "$USER"

cat << EOL
Masternode update completed.
EOL
