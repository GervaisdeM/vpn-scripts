# vpn-scripts

## Introduction
I have to connect to multiple client vpn's for work and did not want to install vpn clients from multiple vendors, so I decided to use openconnect as it supports multiple protocols. The network-manager-gui controls were not working well for me on Ubuntu 22, so I decided to write a script to facilitate vpn connections.

This script has been tested on Ubuntu and macOS.

## Requirements
See example-openconnect-vpn-env for an example config.
* openconnect

### Install openconnect
##### Ubuntu
```
sudo apt install openconnect
```
##### macOS
```
brew install openconnect
```

## Optional
See example-openfortivpn-vpn-env for an example config.  
Although openconnect supports fortinet protocol, it does not support SSO authentication. If you require SSO auth, you need a way to grab your session cookie. I cloned openfortivpn-webviews repo and built the Electron app for this purpose.  
 
* openfortivpn
* openfortivpn-webview

### Install openfortivpn
##### Ubuntu
```
sudo apt install openfortivpn
```
##### macOS
```
brew install openfortivpn
```
### Install openfortivpn-webview
Clone this repo and built the Electron app following the directions on the repo or download the prebuilt versions if they run for you.

	git clone https://github.com/gm-vm/openfortivpn-webview

## Setting up
* To use these scripts clone them down to your computer.
* Keep the files all in the same folder.
* cd into vpn-scripts
* make a symnlink based on the name of the connection to vpn.sh
* copy example-vpn-env to a file with matching the symlink name
* adjust symlinkname-vpn-env for that vpn connection - this is the only file you should need to edit
* most secure (requires 1Password) create an entry named vpn-symlinkname-vpn and put your password in it
* less secure option -> create a file named `~/.matchingname-password` and put your password in it
* launch the script by calling the symlink name - you never run `vpn.sh`

### example
#### set up customer1 vpn

```
cd ~
git clone https://github.com/GervaisdeM/vpn-scripts.git
cd vpn-scripts
ln -s vpn.sh customer1-vpn.sh
cp example-vpn-env customer1-vpn-env
	# edit customer1-vpn-env to suite your needs
	# you do need to know a little bit about openconnect to get this right
echo "myFancySecureVPNpassword" > ~/.customer1-vpn-password
./customer1-vpn.sh
Usage:
  ./customer1-vpn.sh [-c] [-d] [-s] [-h]
  -c ... Connect
  -d ... Disconnect
  -s ... Show connections status
  -h ... Display this help
```
#### add customer2 vpn
```
cd vpn-scripts
ln -s vpn.sh customer2-vpn.sh
cp example-vpn-env customer2-vpn-env
	# edit customer2-vpn-env to suite your needs
	# you do need to know a little bit about openconnect to get this right
echo "myLovelySecureVPNpassword" > ~/.customer2-vpn-password
./customer2-vpn.sh -s
No active connections
```
## Usage
### Check status 

```
~/vpn-scripts/customer1-vpn.sh -s
No active connections
```
or
```
~/vpn-scripts/customer1-vpn.sh -s
VPN customer1-vpn connected.
```
or
```
~/vpn-scripts/customer2-vpn.sh -s
customer1-vpn is already connected!
Run /home/gervais/vpn-scripts/customer1-vpn.sh -d and try again.
```
### Connect
```
./customer1-vpn.sh -c
Connecting to customer1-vpn...
VPN connected.
```
or
```
./customer2-vpn.sh -c
customer1-vpn is already connected!
Run /home/gervais/vpn-scripts/customer1-vpn.sh -d and try again.
```
### Disconnect
```
./customer2-vpn.sh -d
customer1-vpn is already connected!
Run /home/gervais/vpn-scripts/customer1-vpn.sh -d and try again.
```
or
```
./customer1-vpn.sh -d
Disconnected
```

## vpnControl.sh
Although this should work on Linux, it has only been tested on macOS.
Symlink this into my path and use it to launch any previously configured VPN. 

See the help:
```
vpnControl.sh -h
```

## vpnVMcontrol.sh
This has only been tested on macOS with Ubuntu 22 running on UTM. It could easily be extended or altered to support alternal VM controlers such as vmWare or VirtualBox.

See the help:
```
vpnVMcontrol.sh -h
```
