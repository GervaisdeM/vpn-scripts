#!/usr/bin/env bash

# {{{ set some default values

vpnControlPath=$(readlink -f "$0")
vpnScriptPath=$(dirname "$vpnControlPath")

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
# {{{ checkVPNname()

checkVPNname(){
  if [ -n "$1" ]; then
    vpnName="$1"
  else
    if [ -z "$myDefaultVPN" ]; then
      printf "Please pass a vpnName or set the environment variable myDefaultVPN\n"
      showUsage
    else
      vpnName=$myDefaultVPN
    fi
  fi
}

# }}}
# {{{ showUsage()

showUsage()
{
  cat << EOT

Usage:
  $0 [-c vpnName] [-d vpnName] [-ls] [-q] [-s vpnName] [-h]

  -c,  --connect ....... Connect to vpnName
  -d,  --disconnect .... Disconnect vpnName
  -ls, --list .......... List configured vpns
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
# {{{ vpnConnect()

vpnConnect() {
  ${vpnScriptPath}/${vpnName}-vpn.sh -c
}

# }}}
# {{{ vpnDisconnect()

vpnDisconnect() {
    ${vpnScriptPath}/${vpnName}-vpn.sh -d
}

# }}}
# {{{ vpnList ()

vpnList() {
  printf "The following vpn's are configured:\n"
  ls -1 ${vpnScriptPath}/*-vpn.sh | rev | cut -d"/" -f1 | rev | sed "s/-vpn.sh//"
}

# }}}
# {{{ vpnStatus()

vpnStatus() {
  cd ${vpnScriptPath}
  ./${vpnName}-vpn.sh -s
}

# }}}

checkVPNname "$2"
parseOpts "$@"
