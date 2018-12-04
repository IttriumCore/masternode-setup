#!/bin/bash
# A shell script written to automate the ittrium Masternode Setup Process

#esp yellow could be hard to read for users with a bright terminal background
#others could get only the \033[00;32m output
USECOLOR=FALSE
if [ "$USECOLOR" = "TRUE" ]
then
Green=$(echo '\033[00;32m')
Cyan=$(echo '\033[00;36m')
RED=$(echo '\033[00;31m')
YELLOW=$(echo  '\033[00;33m')
fi

#if the directory .ittrium exists skip the initial setup
if [ ! -d ~/.ittrium ]
then

#Upgrading is most of the time a good idea, but if the user isn't in the sudoers list it will fail
#and running as root should be discouraged
echo "${Green}Im Starting to update!"
	sudo apt update

echo "${Green}I've Finished updating! Now I need to upgrade."
	sudo apt upgrade -y

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
	echo
	echo
        echo "${Green}I've finished making folders and downloading the wallet! Now I'll create your ittrium.conf file."	
	 cd ~/.ittrium/
	 touch ~/.ittrium/ittrium.conf
	 touch ~/.ittrium/masternode.conf
	 echo "rpcallowip=127.0.0.1" >> ~/.ittrium/ittrium.conf
#	 sleep 5
#	echo "${Green}Enter an RPC username (It doesn't matter really what it is, just try to make it secure)"
#		read username
# /dev/urandom generates better passwords than the usual user input does

		username=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w16 | head -n1)
			echo "rpcuser=$username" >> ~/.ittrium/ittrium.conf

#	echo "${Green}Enter an RPC password(It doesn't matter really what it is, just try to make it secure)"
#		read password
# /dev/urandom generates better passwords than the usual user input does

		password=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w32 | head -n1)
			echo "rpcpassword=$password" >> ~/.ittrium/ittrium.conf
	
	echo "server=1" >> ~/.ittrium/ittrium.conf
	echo "listen=1" >> ~/.ittrium/ittrium.conf
	echo "staking=1" >> ~/.ittrium/ittrium.conf
	echo "port=39993" >> ~/.ittrium/ittrium.conf
	echo "masternode=1" >> ~/.ittrium/ittrium.conf
	
	echo "${Green}What is the Global IP of your VPS? I'll put this into your config file for you because I'm so nice."
	echo "If you want to use IPV6 enclose the address in [...] like [1b83:123:422d:badb:eef:bad:beef:1234]"
	echo "Possible addresses would be:"
#list the IPs for some convenience
	echo
		ip a|grep 'scope global'
	echo
		read -p 'IP: ' VPSip
			echo
			echo "masternodeaddr=$VPSip:39993" >> ~/.ittrium/ittrium.conf
			echo "bind=$VPSip:39993" >> ~/.ittrium/ittrium.conf
			echo "externalip=$VPSip:39993" >> ~/.ittrium/ittrium.conf
	         
	echo "${Green}What is your masternode genkey? I'll put this into your config file."
	echo "${Green}(You can get this key by opening your local wallets Debug-console and typing: masternode genkey)"
	echo
		read -p 'mnprivkey: ' genkey
			echo "masternodeprivkey=$genkey" >> ~/.ittrium/ittrium.conf

	echo
	echo "${YELLOW}Okay, it looks like you are all set. Let's startup the daemon!"
	echo
	 cd ~/

	./ittriumd -daemon
	exit 0
else
#the initial setup was already done ask if a new MN with the same IP should be generated
	echo "The initial setup was already done."
	echo "${Green}Do you want to setup a new MasterNode on the same IP?"
	read -p '(y)es or (n)o? ' answer
	if [ "$answer" != "${answer#[Nn]}" ] ;then
	#no exit
		exit 0 
	else
	#yes
	echo
	echo "Generating a new datadir for the new MasterNode."
#count the number of already installed .ittrium directorys 
	declare -i nnodes
	nnodes=$(ls 2>/dev/null -d .ittrium* | wc -l)
	#stop the aerium-daemon before copying the datadir 
	if [ -e ~/.ittrium/ittriumd.pid ]
	then
		./ittrium-cli stop
		sleep 1
		restart=TRUE
	fi

	nnodes=$nnodes+1
	newdirname=(.ittrium$nnodes)
	cp -r ~/.ittrium ~/$newdirname

	#restart the ittriumd 
	if [ "$restart" = "TRUE" ]
	then
		./ittriumd -daemon
	fi

	cd $newdirname	

	mv ittrium.conf ittrium0.conf
	touch ittrium.conf
	declare -i rpcp
	rpcp=50369+$nnodes
        echo "rpcallowip=127.0.0.1" >> ittrium.conf
	echo "bind=127.0.0.$nnodes" >> ittrium.conf
        username=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w32 | head -n1)
        echo "rpcuser=$username" >>  ittrium.conf
        password=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w32 | head -n1)
        echo "rpcpassword=$password" >> ittrium.conf
        echo "rpcport=$rpcp" >> ittrium.conf
        echo "server=1" >> ittrium.conf
        echo "listen=1" >> ittrium.conf
        echo "staking=1" >> ittrium.conf
        echo "masternode=1" >> ittrium.conf
        eip=$(grep externalip ittrium0.conf)
        echo $eip >> ittrium.conf
	
	echo
        echo "${Green}What is your masternode genkey? I'll put this into your config file."
        echo "${Green}(You can get this key by opening your local wallets Debug-console and typing: masternode genkey)"
                read -p 'mnprivkey: ' genkey
                        echo "masternodeprivkey=$genkey" >> ittrium.conf

	rm ittrium0.conf
	cd ~/

#create two scripts for an easy startup and access to the new MasterNode
#for about 2-5 MNs this approach should work
#for more i would suggest to create a $HOME/bin directory and copy all scripts there (ubuntu would have it already in its user $PATH)
#and add a script which takes the MN-number as argument, not one script for every MN.

	touch "ittriumd$nnodes"
	echo "#!/bin/bash" >> "ittriumd$nnodes"
	echo "~/ittriumd -datadir=$HOME/.ittrium$nnodes -daemon" >> "ittriumd$nnodes"
	chmod 770 "ittriumd$nnodes"

        touch "ittrium$nnodes-cli"
        echo "#!/bin/bash" >> "ittriumd$nnodes-cli"
        echo "~/ittrium-cli -datadir=$HOME/.ittrium$nnodes -rpcport=$rpcp \$@" >> "ittrium$nnodes-cli"
        chmod 770 "ittrium$nnodes-cli"

	echo
	echo "You can start your new MasterNode daemon with ./ittriumd$nnodes."
	echo "To get its status use: ./ittrium$nnodes-cli masternode status."
	echo "To stop the daemon use: ./ittrium$nnodes-cli stop."

	 fi
	fi


