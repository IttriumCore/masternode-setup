# Masternode setup guide and script. 

This script will install and configure your Ittrium masternode.  If you wish to install and setup your masternode manually, please refer to the Ittrium Masternode Setup Guide pdf.

# System requirements

The VPS you plan to install your masternode on needs to have at least 1GB of RAM and 10GB of free disk space. We do not recommend using servers who do not meet those criteria, and your masternode will not be stable. We also recommend you do not use elastic cloud services like AWS or Google Cloud for your masternode - to use your node with such a service would require some networking knowledge and manual configuration. The bester more reliable VPS are provided by www.hetzner.com, www.digitalocean.com or www.vultr.com

# Funding your Masternode

First, we will do the initial collateral TX and send exactly 5000 XIT to one of your own addresses. 

        Open your XIT wallet and switch to the "Receive" tab.

        Click into the label field and create a label, I will use MN01

        Now click on "Request payment"

        The generated address will now be labelled as MN01.  
        
If you have multiple masternodes to setup, it less problematic to set them up one at a time.  Once the address has been created send 5000 XIT each to them (NOTE: you will need an additional 0.0001 XIT in your wallet to pay the transfer fee). Ensure that you send exactly 5000 XIT and do it in a single transaction. You can double check where the coins are coming from by checking it via coin control usually, that's not an issue.

Once the transactions has been completed, you need to wait for 15 confirmations. You can check this in your wallet or use the explorer. It should take around 15 minutes.

# Generate your Masternode Private Key and setup the mastenode config file

In your wallet, open Tools -> Debug console and run the following command to get your masternode key:

    masternode genkey

Please note: If you plan to set up more than one masternode, you need to create a key with the above command for each one. These keys are not tied to any specific masternode, but each masternode you run requires a unique key.

Run this command to get your output information:

    masternode outputs

Copy both the key and output information to a text file.

Close your wallet and open the Ittrium Appdata folder. Its location depends on your OS.

    Windows: Press Windows+R and write %appdata% - there, open the folder Ittrium.
    
    macOS: Press Command+Space to open Spotlight, write ~/Library/Application Support/Ittrium and press Enter.
    
    Linux: Open ~/.ittrium/

In your appdata folder, open masternode.conf with a text editor and add a new line in this format to the bottom of the file:

    masternodename ipaddress:39993 genkey collateralTxID outputID

An example would be

    MN01 127.0.0.2:39993 93HaYBVUCYjEMeeH1Y4sBGLALQZE1Yc1K64xiqgX37tGBDQL8Xg 2bcd3c84c84f87eaa86e4e56834c92927a07f9e18718810b92e0d0324456a67c 0

masternodename is a name you choose, ipaddress is the public IP of your VPS, masternodeprivatekey is the output from masternode genkey, and collateralTxID & outputID come from masternode outputs. Please note that masternodename must not contain any spaces, and should not contain any special characters.

Restart and unlock your wallet.

# VPS setting up and Ittrium wallet installation

SSH (Putty on Windows, Terminal.app on macOS) to your VPS, login as root (Please note: It's normal that you don't see your password after typing or pasting it) and run the following commands:

    wget 'https://raw.githubusercontent.com/IttriumCore/masternode-setup/master/xit-mn-setup.sh'
    
    chmod 755 xit-mn-setup.sh
    
    ./xit-mn-setup.sh
 
 After completion, return back to you GUI wallet. 

# Starting the masternode 

Go to the Debug Console and enter the following command, remembering to use your masternode ID (i.e. MN01 in this example). 

    startmasternode alias false MN01


# Tearing down a Masternode

If you no longer wish to operate your Masternode, stop running MN01 on your VPS.

    ./ittrium-cli stop

Then from your controller wallet, edit your masternode.conf by deleting the MN01 masternode line entry.  Now restart the controller wallet and your 5,000 XIT collateral will now be unlocked.

