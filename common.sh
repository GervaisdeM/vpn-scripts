# Default values for scripts in this directory

#{{{ Set Colours

boldTXT="\e[1m"
noBoldTXT="\e[0m"
resetTXT="\e[39m"
greenTXT="\e[32m"
redTXT="\e[31m"
yellowTXT="\x1B[33m"

# }}}
#{{{ checkVaultName()

checkVaultName() {
  if [ -z "$myDefaultVault" ]; then
    printf "${redTXT}It looks like we are using 1Password.\n"
    printf "Please set environment variable myDefaultVault${resetTXT}\n"
    showUsage
  fi
}

#}}}
#{{{ passwordFileCreate()

passwordFileCreate() {
  if [ -z "$SUDO_COMMAND" ]; then
    # op seems too generic. Let's make sure op is actually 1password
    hash op >/dev/null 2>&1
    if [ $? -eq 0 ]; then
      op --help | head -n1 | grep 1Password >/dev/null 2>&1
      if [ $? -eq 0 ]; then
        checkVaultName
        eval $(op signin --account my)
        myPassword=$(op read op://${myDefaultVault}/vpn-${myName}/password)
        echo $myPassword > ~/.${myName}-password
      fi
    else
      printf "Please put your password in ~/.${myName}-password\n"
      exit 1
    fi
  fi
}

# }}}
#{{{ passwordFileRemove()

passwordFileRemove() {
  # op seems too generic. Let's make sure op is actually 1password
  hash op >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    op --help | head -n1 | grep 1Password >/dev/null 2>&1
    if [ $? -eq 0 ]; then
      test -f ~/.${myName}-password && rm ~/.${myName}-password || return 0
    fi
  fi
}

# }}}
# {{{ sanityCheck()

sanityCheck() {
  # Set up password
  if [ ! -f ~/.${myName}-password ]; then
    passwordFileCreate
  fi

  # Set up connection
  if [ ! -f ${myDir}/${myName}-env ]; then
    printf "${yellowTXT}${myName}-env not found${resetTXT}\n"
    printf "Please put connection params in ${myDir}/${myName}-env\n"
    exit 1
  else
    source ${myDir}/${myName}-env
  fi

  # Check how we were called and re-run script as sudo if we were not already
  if [ -z "$SUDO_COMMAND" ]; then
    sudo -E $0 "$@"
    exit
  fi
}

# }}}
# {{{ showUsage()

showUsage()
{
  cat << EOT
Usage:
  $0 [-c] [-d] [-s] [-h]
  -c ... Connect
  -d ... Disconnect
  -s ... Show connections status
  -h ... Display this help

EOT
exit 3
}

# }}}
#{{{ vpnDisconnect()

vpnDisconnect() {
  if [ -f ${pidFile} ]; then
    kill $(cat ${pidFile})
    sleep .5
    printf "${boldTXT}${yellowTXT}Disconnected${resetTXT}${noBoldTXT}\n"
    test -f ${pidFile} && rm -f ${pidFile}
    if [ -n "$keepAlivePing" ]; then
      kill $(pgrep -f "$keepAlivePing")
    fi
  else
    $0 -s
  fi
}

#}}}
#{{{ vpnStatus()

vpnStatus() {
  openconnectPid=$(ps aux | pgrep openfortivpn) || openconnectPid=$(ps aux | pgrep openconnect)
  if [ $? -eq 0 ]; then
    if [ -f ${pidFile} ]; then
      ps p $(cat ${pidFile}) | grep -E "${myName}|${myHost}" > /dev/null
      if [ $? -eq 0 ]; then
        printf "${greenTXT}VPN ${myName} connected.${resetTXT}\n"
        exit 0
      fi
    else
      otherName=$(ps p ${openconnectPid} | grep -o "\/var\/run\/.\+\.pid" 2>/dev/null | cut -d"/" -f4 | cut -d"." -f1)
      if [ "$otherName" = "" ]; then
        otherName="Unknown Connection"
        printf "${redTXT}${otherName} is already connected!${resetTXT}\n"
        printf "A connection is open that is not managed by vpn-scripts.\n"
      else
        printf "${redTXT}${otherName} is already connected!${resetTXT}\n"
        printf "Run ${boldTXT}${myDir}/${otherName}.sh -d${noboldTXT} and try again.\n"
      fi
      exit 1
    fi
  fi
}

#}}}
# {{{ parseOpts()

parseOpts() {
  if [ $# -eq "0" ]; then
    showUsage
  else
    while getopts "cdsh" opt; do
      case $opt in
        c)
          vpnStatus
          printf "Connecting to ${boldTXT}${myName}${noboldTXT}...\n"
          vpnConnect
          passwordFileRemove
          ;;
        d)
          vpnDisconnect
          passwordFileRemove
          ;;
        s)
          vpnStatus
          printf "${yellowTXT}No active connections${resetTXT}\n"
          passwordFileRemove
          ;;
        h)
          showUsage
          ;;
        \?)
          showUsage
          ;;
      esac
    done
  fi
}

#}}}
