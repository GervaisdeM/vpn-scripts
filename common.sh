# Default values for scripts in this directory

# Colors
if [ -t 1 ]; then
  boldTXT="\e[1m"
  noBoldTXT="\e[0m"
  resetTXT="\e[39m"
  greenTXT="\e[32m"
  redTXT="\e[31m"
  yellowTXT="\x1B[33m"
fi

# {{{ sanityCheck()

sanityCheck() {
  # Set up password
  if [ ! -f ~/.${myName}-password ]; then
    echo "Please put your password in ~/.${myName}-password"
    exit 1
  fi

  # Set up connection
  if [ ! -f ${myDir}/${myName}-env ]; then
    echo -e "${yellowTXT}${myName}-env not found${resetTXT}"
    echo "Please put connection params in ${myDir}/${myName}-env"
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
    echo -e "${boldTXT}${yellowTXT}Disconnected${resetTXT}${noBoldTXT}"
  else
    $0 -s
  fi
}

#}}}
#{{{ vpnStatus()

vpnStatus() {
  openconnectPid=$(ps aux | pgrep openconnect)
  if [ $? -eq 0 ]; then
    if [ -f ${pidFile} ]; then
      ps p $(cat $pidFile) | grep ${myName} > /dev/null
      if [ $? -eq 0 ]; then
        echo -e "${greenTXT}VPN ${myName} connected.${resetTXT}"
        exit 0
      fi
    else
      otherName=$(ps p ${openconnectPid} | grep -o "\/var\/run\/.\+\.pid" | cut -d"/" -f4 | cut -d"." -f1)
      echo -e "${redTXT}${otherName} is already connected!${resetTXT}"
      echo -e "Run ${boldTXT}${myDir}/${otherName}.sh -d${noboldTXT} and try again."
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
          echo -e "Connecting to ${boldTXT}${myName}${noboldTXT}..."
          vpnConnect
          ;;
        d)
          vpnDisconnect
          ;;
        s)
          vpnStatus
          echo -e "${yellowTXT}No active connections${resetTXT}"
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
