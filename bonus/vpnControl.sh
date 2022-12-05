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

# }}}
# {{{ set some default values

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

N.B. Set myDefaultVPN environment variable to set default vpnName
     If myDefaultVPN is not set, then vpnName must be passed to this script

EOT
exit 3
}

# }}}
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
  echo -n "Starting $vpnServerName Server"
  osascript -e "open location \"utm://start?name=$vpnServerName\""
  if [ "$TERM_PROGRAM" = "Apple_Terminal" ]; then
    sleep 1
    echo -n "."
    osascript -e 'tell application "Terminal" to activate'
  fi
  myWaitCount=0
  ping -c 1 -t 1 $vpnServerName > /dev/null 2>&1
  pingResult=$?
  while [ $pingResult -ne 0 ] && [ $myWaitCount -lt 30 ]; do
    ping -c 1 -t 1 $vpnServerName > /dev/null 2>&1
    pingResult=$?
    let myWaitCount=myWaitCount+1
  done
  echo -e "\nWaiting $vmStartWait seconds for vm to fully initialize"
  echo -n "$vmStartWait"
  myWaitCount=0
  while [ $myWaitCount -lt $vmStartWait ]; do
    sleep 1
    let vmStartWait=vmStartWait-1
    echo -n "..$vmStartWait"
  done
  echo ""
}

# }}}
# {{{ checkVPNLinuxState()

checkVPNLinuxState() {
  ps aux | grep QEMULauncher | grep $vpnServerName.utm > /dev/null
  [ $? -eq 0 ] && VPNlinuxState=1 || VPNlinuxState=0
}

# }}}
# {{{ vpnConnect()

vpnConnect() {
  checkVPNLinuxState
  if [ $VPNlinuxState -eq 0 ]; then
    startVPNlinux
  fi
  ssh $vpnServerName "${vpnScriptPath}/${vpnName}-vpn.sh -c"
}

# }}}
# {{{ vpnDisconnect()

vpnDisconnect() {
  checkVPNLinuxState
    if [ "${VPNlinuxState}" -eq 1 ]; then
    ssh $vpnServerName "${vpnScriptPath}/${vpnName}-vpn.sh -d"
  else
    echo "VPN not connected"
  fi
}

# }}}
# {{{ vpnLinuxShutdown()

vpnLinuxShutdown() {
  checkVPNLinuxState
  if [ "${VPNlinuxState}" -eq 1 ]; then
    echo "Shutting down $vpnServerName Server"
    ssh $vpnServerName "sudo poweroff &"
    checkVPNLinuxState
    while [ "${VPNlinuxState}" -eq 1 ]; do
      checkVPNLinuxState
    done
    ps aux | ack 'QEMULauncher|com.apple.Virtualization.VirtualMachine.xpc' > /dev/null || osascript -e 'tell application "UTM" to quit'
  else
    echo "$vpnServerName Server is already offline"
  fi

}

# }}}
# {{{ vpnStatus()

vpnStatus() {
  checkVPNLinuxState
  if [ "${VPNlinuxState}" -eq 1 ]; then
    ssh $vpnServerName "${vpnScriptPath}/${vpnName}-vpn.sh -s"
  else
    echo "VPN not connected"
  fi
}

# }}}
# {{{ vpnList ()

vpnList() {
  checkVPNLinuxState
  if [ "${VPNlinuxState}" -eq 0 ]; then
    startVPNlinux
  fi
  echo "The following vpn's are configured:"
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
        checkVPNname $2
        vpnConnect
        ;;
      -d|--disconnect)
        checkVPNname $2
        vpnDisconnect
        ;;
      -ls|--list)
        vpnList
        ;;
      -q|--shutdown)
        vpnLinuxShutdown
        ;;
      -s|--status)
        checkVPNname $2
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

parseOpts "$@"
