#!/opt/homebrew/bin/bash

# This script works on macOS to manage connecting, disconnecting, checking
# status of VPNs configured with vpn-scripts running on a Linux VM that has
# been set up using UTM (https://mac.getutm.app). It will start the vm if it is
# not running and it needs to check something on it and it can also be used to
# shutdown the VM when you are done with it. See showUsage() function.

# {{{ but WHY? ¯\(°_o)/¯

# 1. This allows me to be on the company VPN and not at the same time
# 2. My home internet is faster than some VPN connections I have to use
# 3. I like to be able to be on my home internet and connect to local things
# 4. If I need to be on more than one VPN at once, I can clone vpn-linux and
#     set it up as a second ProxyJump

# }}}
# {{{ set up instructions

# Set up:
#     1. Install Linux and openconnect on a VM running with UTM
#     2. Configure passwordless ssh and sudo on the VM
#         ie. setup a ~/.ssh/config so "ssh vpn-linux" works without and prompts
#             and once connected to vpn-linux sudo does not require a password
#     3. Pull down and configure vpn-scripts on vpn-linux as per README in:
#         https://github.com/GervaisdeM/vpn-scripts
#     4. Adjust the defaults below:
#         vpnServerName ... Name of the VM you created. I call mine vpn-linux
#         vpnScriptPath ... the path to vpn-scripts on vpnSeverName
#     5. Set up your local ~/.ssh/config to use vpnServerName as the jump server
#         for all your ssh connections that require you to connect through a
#         vpn configured on vpnServerName
#         Example:
#             Host vpn-linux vpn-linux.home VPN-Linux
#               Hostname vpn-linux
#               User gervais
#             Host serverBehindVPN
#               Hostname 10.160.18.245
#               User gervais
#               ProxyJump vpn-linux
#     6. Optional:
#         a. Set the myDefaultVPN environment variable to your most used
#           vpn that you set up on vpnServerName
#           Example:
#             echo 'export myDefaultVPN="myCompanyVPN"' >> ~/.bash_profile
#         b. symlink this script into your path
#         c. if using 1password, set myDefaultVault environment variable

# }}}
# {{{ set some default values

#Set Colours
boldTXT="\e[1m"
noBoldTXT="\e[0m"
resetTXT="\e[39m"
greenTXT="\e[32m"
redTXT="\e[31m"
yellowTXT="\x1B[33m"

vpnScriptPath="~/vpn-scripts"
vpnServerName="VPN-Linux"
vmStartWait=10

# }}}
# {{{ showUsage()

showUsage()
{
  cat << EOT

Usage:
  $0 [-c vpnName] [-d vpnName] [-ls] [-q] [-s vpnName] [-h]

  -c,  --connect ....... Connect to vpnName
  -d,  --disconnect .... Disconnect vpnName
  -ls, --list .......... List configured vpns on $vpnServerName
  -q,  --shutdown ...... Shutdown $vpnServerName server
  -s,  --status ........ Status of connection vpnName
  -h,  --help .......... Display this help

N.B.
    1. Set myDefaultVPN environment variable to set default vpnName
       If myDefaultVPN is not set, then vpnName must be passed to this script
    2. If using 1password command line set myDefaultVault environment variable
       Create 1password entries for all vpn's configure:
          op://\${myDefaultVault}/vpn-\${vpnName}/password

EOT
exit 3
}

# }}}
#{{{ checkVaultName()

checkVaultName() {
  if [ -z "$myDefaultVault" ]; then
    printf "${redTXT}Set environment variable myDefaultVault${resetTXT}\n"
    showUsage
  fi
}

#}}}
# {{{ checkVPNname()

checkVPNname(){
  if [ -n "$1" ]; then
    vpnName="$1"
  else
    if [ -z "$myDefaultVPN" ]; then
      showUsage
    else
      vpnName=$myDefaultVPN
    fi
  fi
}

# }}}
# {{{ startVPNlinux()

startVPNlinux() {
  printf "Starting ${boldTXT}${vpnServerName}${noBoldTXT} Server\n"
  osascript -e "open location \"utm://start?name=$vpnServerName\""
  if [ "$TERM_PROGRAM" = "Apple_Terminal" ]; then
    sleep 1
    printf "."
    osascript -e 'tell application "Terminal" to activate'
  fi
  myWaitCount=0
  ping -c 1 -t 1 $vpnServerName > /dev/null 2>&1
  pingResult=$?
  while [ $pingResult -ne 0 ] && [ $myWaitCount -lt 30 ]; do
    printf "."
    ping -c 1 -t 1 $vpnServerName > /dev/null 2>&1
    pingResult=$?
    let myWaitCount=myWaitCount+1
  done
  printf "\nWaiting $vmStartWait seconds for vm to fully initialize\n"
  printf "$vmStartWait"
  myWaitCount=0
  while [ $myWaitCount -lt $vmStartWait ]; do
    sleep 1
    let vmStartWait=vmStartWait-1
    printf "..$vmStartWait"
  done
  printf "\n"
}

# }}}
# {{{ checkVPNLinuxState()

checkVPNLinuxState() {
  ps aux | grep QEMULauncher | grep $vpnServerName.utm > /dev/null
  [ $? -eq 0 ] && VPNlinuxState=1 || VPNlinuxState=0
}

# }}}
#{{{ passwordFileCreate()

passwordFileCreate() {
  # op seems too generic. Let's make sure op is actually 1password
  op --help | head -n1 | grep 1Password >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    checkVaultName
    eval $(op signin)
    myPassword=$(op read op://${myDefaultVault}/vpn-${vpnName}-vpn/password)
    ssh $vpnServerName "echo $myPassword > ~/.${vpnName}-vpn-password"
  fi
}

# }}}
#{{{ passwordFileRemove()

passwordFileRemove() {
  # op seems too generic. Let's make sure op is actually 1password
  op --help | head -n1 | grep 1Password >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    ssh $vpnServerName "test -f ~/.${vpnName}-vpn-password && rm ~/.${vpnName}-vpn-password"
  fi
}

# }}}
# {{{ vpnConnect()

vpnConnect() {
  checkVPNLinuxState
  if [ $VPNlinuxState -eq 0 ]; then
    startVPNlinux
  fi
  passwordFileCreate
  ssh $vpnServerName "${vpnScriptPath}/${vpnName}-vpn.sh -c"
  passwordFileRemove
}

# }}}
# {{{ vpnDisconnect()

vpnDisconnect() {
  checkVPNLinuxState
  if [ "${VPNlinuxState}" -eq 1 ]; then
    passwordFileCreate
    ssh $vpnServerName "${vpnScriptPath}/${vpnName}-vpn.sh -d"
    passwordFileRemove
  else
    printf "${yellowTXT}VPN not connected${resetTXT}\n"
  fi
}

# }}}
# {{{ vpnLinuxShutdown()

vpnLinuxShutdown() {
  checkVPNLinuxState
  if [ "${VPNlinuxState}" -eq 1 ]; then
    printf "Shutting down ${boldTXT}${vpnServerName}${noBoldTXT} Server\n"
    ssh $vpnServerName "sudo poweroff &"
    checkVPNLinuxState
    while [ "${VPNlinuxState}" -eq 1 ]; do
      checkVPNLinuxState
    done
    ps aux | ack 'QEMULauncher|com.apple.Virtualization.VirtualMachine.xpc' > /dev/null || osascript -e 'tell application "UTM" to quit'
  else
    printf "${yellowTXT}${vpnServerName} Server is already offline${resetTXT}\n"
  fi

}

# }}}
# {{{ vpnStatus()

vpnStatus() {
  checkVPNLinuxState
  if [ "${VPNlinuxState}" -eq 1 ]; then
    passwordFileCreate
    ssh $vpnServerName "${vpnScriptPath}/${vpnName}-vpn.sh -s"
    passwordFileRemove
  else
    printf "VPN not connected\n"
  fi
}

# }}}
# {{{ vpnList ()

vpnList() {
  checkVPNLinuxState
  if [ "${VPNlinuxState}" -eq 0 ]; then
    startVPNlinux
  fi
  printf "The following vpn's are configured:\n"
  ssh $vpnServerName "ls -1 ${vpnScriptPath}/*-vpn.sh | rev | cut -d\"/\" -f1 | rev | sed \"s/-vpn.sh//\""
}

# }}}
# {{{ parseOpts()

parseOpts() {
  if [ $# -eq "0" ]; then
    showUsage
  else
    case $1 in
      -c|--connect)
        vpnConnect
        ;;
      -d|--disconnect)
        vpnDisconnect
        ;;
      -ls|--list)
        vpnList
        ;;
      -q|--shutdown)
        vpnLinuxShutdown
        ;;
      -s|--status)
        vpnStatus
        ;;
      -h|--help)
        showUsage
        ;;
      *)
        showUsage
        ;;
      esac
  fi
}

#}}}

checkVPNname $2
parseOpts "$@"
