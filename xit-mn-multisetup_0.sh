#!/bin/sh
# A shell script written to automate the ittrium Masternode Setup Process

Green=$(echo '\033[00;32m')
Cyan=$(echo '\033[00;36m')
RED=$(echo '\033[00;31m')
YELLOW=$(echo  '\033[00;33m')

echo "${Green}Im Starting to update!"
	apt update

echo "${Green}I've Finished updating! Now I need to upgrade."
	apt upgrade -y

echo "${Green}I've finished upgrading! Now I need to install dependencies"
	sudo apt-get install nano unzip git -y

echo "${Green}I've finished installing dependencies! Now I'll make folders and download the wallet."
	wget https://github.com/IttriumCore/ittrium/releases/download/v2.0.3/ittrium-v2.0.3-linux64.tar.gz
	tar -xzvf ittrium-v2.0.3-linux64.tar.gz
	chmod +x ittriumd
	chmod +x ittrium-cli
	
	./ittriumd -daemon
	sleep 5
	./ittrium-cli stop
echo "${Green}I've finished making folders and downloading the wallet! Now I'll create your ittrium.conf file."	
	cd /root/.ittrium/
	touch /root/.ittrium/ittrium.conf
	touch /root/.ittrium/masternode.conf
	echo "rpcallowip=127.0.0.1" >> /root/.ittrium/ittrium.conf
	sleep 5
	echo "${Green}Enter an RPC username (It doesn't matter really what it is, just try to make it secure)"
		read username
			echo "rpcuser=$username" >> /root/.ittrium/ittrium.conf

	echo "${Green}Enter an RPC password(It doesn't matter really what it is, just try to make it secure)"
		read password
			echo "rpcpassword=$password" >> /root/.ittrium/ittrium.conf
	
	echo "server=1" >> /root/.ittrium/ittrium.conf
	echo "listen=1" >> /root/.ittrium/ittrium.conf
	echo "staking=1" >> /root/.ittrium/ittrium.conf
	echo "port=39993" >> /root/.ittrium/ittrium.conf
	echo "masternode=1" >> /root/.ittrium/ittrium.conf
	
	echo "${Green}What is the Global IP of your VPS? I'll put this into your config file for you because I'm so nice."
		read VPSip
			echo "masternodeaddr=$VPSip:39993" >> /root/.ittrium/ittrium.conf
			echo "bind=$VPSip:39993" >> /root/.ittrium/ittrium.conf
			echo "externalip=$VPSip:39993" >> /root/.ittrium/ittrium.conf
	         
	echo "${Green}What is your masternode genkey? I'll put this into your config file."
		read genkey
			echo "masternodeprivkey=$genkey" >> /root/.ittrium/ittrium.conf

	
echo "${YELLOW}Okay, it looks like you are all set. Let's startup the daemon!"
	cd /root/

	./ittriumd -daemon
