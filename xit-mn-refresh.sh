#!/bin/bash

# Make sure curl is installed
apt-get -qq update
apt -qqy install curl
clear

BOOTSTRAPURL=$(curl -s https://api.github.com/repos/IttriumCore/ittrium/releases/latest | grep bootstrap.dat.xz | grep browser_download_url | cut -d '"' -f 4)
BOOTSTRAPARCHIVE="bootstrap.dat.xz"

clear
echo "This script will refresh your masternode."
read -rp "Press Ctrl-C to abort or any other key to continue. " -n1 -s
clear

if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as root."
  exit 1
fi

USER=$(ps -o user= -p "$(pgrep ittriumd)")
USERHOME=$(eval echo "~$USER")

if [ -e /etc/systemd/system/ittrium.service ]; then
  systemctl stop ittriumd
else
  su -c "ittrium-cli stop" "$USER"
fi

echo "Refreshing node, please wait."

sleep 5

rm -rf "$USERHOME/.ittrium/blocks"
rm -rf "$USERHOME/.ittrium/database"
rm -rf "$USERHOME/.ittrium/chainstate"
rm -rf "$USERHOME/.ittrium/peers.dat"

cp "$USERHOME/.ittrium/ittrium.conf" "$USERHOME/.ittrium/ittrium.conf.backup"
sed -i '/^addnode/d' "$USERHOME/.ittrium/ittrium.conf"

echo "Installing bootstrap file..."
wget "$BOOTSTRAPURL" && xz -cd $BOOTSTRAPARCHIVE > "$USERHOME/.ittrium/bootstrap.dat" && rm $BOOTSTRAPARCHIVE

if [ -e /etc/systemd/system/ittrium.service ]; then
  sudo systemctl start ittrium.service
else
  su -c "ittriumd -daemon" "$USER"
fi

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

until [ -n "$(ittrium-cli getconnectioncount 2>/dev/null)"  ]; do
  sleep 1
done

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

sleep 1
su -c "/usr/local/bin/ittrium-cli startmasternode local false" "$USER"
sleep 1
clear
su -c "/usr/local/bin/ittrium-cli masternode status" "$USER"
sleep 5

echo "" && echo "Masternode refresh completed." && echo ""