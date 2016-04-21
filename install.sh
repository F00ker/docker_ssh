#!/bin/bash
# Author Steffy FORT

# Defintion info, warning, error
cyan='\e[0;36m'
orange='\e[0;33m'
red='\e[0;31m'
reset='\e[0m'
info="[${cyan}info${reset}]"
warning="[${orange}warning${reset}]"
error="[${red}error${reset}]"

# Variables
root_dir='/etc/docker-ssh'
binary='docker-ssh.rb'
binary_dest='/usr/local/bin/docker-ssh'
sudoers='/etc/sudoers'
source_script=$(dirname "${BASH_SOURCE[0]}")
source_dir=$(readlink -f ${source_script})

# Definition

sudoers_config() {
  read sudoers_validate

  case ${sudoers_validate} in
    y|Y|yes|Yes|^$)
      if [[ -f ${sudoers} ]]
        then
        sed -i 's/#includedir \/etc\/sudoers\.d/includedir \/etc\/sudoers.d'
          if [[ ! -d ${sudoers}.d ]]
          then
            mkdir -p ${sudoers}.d
            printf '%docker-ssh ALL= NOPASSWD: /usr/local/bin/docker-ssh' > ${sudoers}.d/docker-ssh
          fi
      else
        printf ".. ${error} sudoers file was not found, please add in your sudoers config : %docker-ssh ALL= NOPASSWD: /usr/local/bin/docker-ssh .."
      fi
    ;;
    
    n|N|no|No)
    ;;

    *)
      printf "${error} Please reply Yes or No : "
      sudoers_config
  esac
}

ssh_config() {

  read ssh_validate

  case ${ssh_validate} in
    y|Y|yes|Yes|^$)
      cat <<EOF >> /etc/ssh/sshd_config
Match Group docker-ssh
   ForceCommand sudo /usr/local/bin/docker-ssh "\${SSH_CONNECTION}" "\${SSH_ORIGINAL_COMMAND}" "\${USER}" "\${HOME}""
   AllowAgentForwarding no
   AllowTcpForwarding no
   PermitTunnel no
   X11Forwarding no
EOF

      service ssh reload
    ;;

    n|N|no|No)
    ;;

    *)
      printf "${error} Please reply Yes or No : "
      ssh_config
  esac
}


# Main program

printf "${info} Start install.. \n"


# Create config

if [[ ! -d ${root_dir} ]]
  then
  mkdir -p ${root_dir}/{containers,extra}
  chmod 0750 ${root_dir}
  chown -R root:root ${root_dir}

  printf '# Example\n# bob::ssh-container:/var/log,/var/www/' > ${root_dir}/docker-ssh.passwd

  for i in bashrc_default bash_profile_default
    do
    if [[ -f ${i} ]]
      then
      cp ${i} ${root_dir}/extra/${i}
    else
      printf "${warning} ${i} doesn't exist, please create ${root_dir}/extra/${i} \n"
    fi
  done

else
  printf "${info} Conf directory ${root_dir} already existing. No change made. \n"
fi



# Copy binary

if [[ -f ${binary} ]]
  then
  cp ${binary} ${binary_dest}
  chmod 0700 ${binary}
  chown -R root:root ${binary}
fi


# Check if Debian 7

if [[ -f /etc/debian_version ]]
  then
  if [[ $(cat /etc/debian_version) =~ ^7.* ]]
    then
    for ruby_ver in /usr/bin/ruby*
      do
      version=$(basename ${ruby_ver})
        if [[ version =~ ^ruby1.9.* ]]
          then
          sed -i "1 s/.*/\#\!${ruby_ver}/" ${binary_dest}
        fi
    done
  fi
fi


# Add docker-ssh group

groupadd docker-ssh


# Check sudoers conf

printf "${warning} This script modify sudoers.conf, can you validate ? [Y/n] : "
sudoers_config


# Add ssh config

printf "${warning} This script modify sshd_config and reload ssh deamon, can you validate ? [Y/n] : "
ssh_config

printf ".. Installation [${cyan}OK${reset}] \n"
printf "${warning} Please remove source code in ${source_dir}.\n"
