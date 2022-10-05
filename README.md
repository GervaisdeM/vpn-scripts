# vpn-scripts

## Introduction
I have to connect to multiple client vpn's for work and did not want to install vpn clients from multiple vendors, so I decided to use openconnect as it supports multiple protocols. The network-manager-gui controls were not working well for me on Ubuntu 22, so I decided to write a script to facilitate vpn connections.

This script has been tested on Ubuntu, but should also work on macOS (the colour's will need adjusting).

## Requirements
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
## Setting up
* To use these scripts clone them down to your computer.
* Keep the files all in the same folder.
* cd into vpn-scripts
* make a symnlink based on the name of the connection to vpn.sh
* copy example-vpn-env to a file with matching the symlink name
* adjust symlinkname-vpn.sh for that vpn connection - this is the only file you should need to edit
* create a file named `~/.matchingname-password` and put your password in it
* launch the script based on the symlink name - you never run `vpn.sh`

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