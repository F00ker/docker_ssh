#!/bin/bash
# Author Steffy FORT

# Defintion info, warning, error
cyan='\e[0;36m'
orange='\e[0;33m'
red='\e[0;31m'
reset='\e[0m'
info="[${cyan}info${reset}]"
warning="[${oragen}warning${reset}]"
error="[${red}error${reset}]"

# Variables
root_dir = '/etc/docker-ssh'
binary = 'docker-ssh.rb'
sudoers = '/etc/sudoers'


# Main program

printf "${info} Start install.. "


# Create config

if [[ ! -d ${root_dir} ]]
  mkdir -i ${root_dir}/{containers,extra}
  chmod 0750 ${root_dir}
  chown -R root:root ${root_dir}

  printf '# Example\n# bob::ssh-container:/var/log,/var/www/' > ${root_dir}/docker-ssh.passwd

  for i in bashrc_default bash_profile_default
    do
    if [[ -f ${i} ]]
       cp ${i} ${root_dir}/extra
    else
      printf "${warning} ${i} doesn't exist, please create ${root_dir}/extra/${i}\n"
    fi
  done

else
  printf "${info} Conf directory ${root_dir} already existing. No change made."
fi



# Copy binary

if [[ -f ${binary} ]]
  cp ${binary} /usr/local/bin/docker-ssh
  chmod 0700 ${binary}
  chown -R root:root ${binary}
fi


# Add docker-ssh group

groupadd docker-ssh


# Check sudoers conf

if [[ -f ${sudoers} ]]
  sed -i 's/#includedir \/etc\/sudoers\.d/includedir \/etc\/sudoers.d'
  if [[ ! -d ${sudoers}.d ]]
    mkdir -p ${sudoers}.d
    printf '%docker-ssh ALL= NOPASSWD: /usr/local/bin/docker-ssh' > ${sudoers}.d/docker-ssh
  fi
else
  printf ".. ${error} sudoers file was not found, please add in your sudoers config : %docker-ssh ALL= NOPASSWD: /usr/local/bin/docker-ssh .."
fi


# Add ssh config

cat <<EOF >> /etc/ssh/sshd_config
Match Group docker-ssh
   ForceCommand sudo /usr/local/bin/docker-ssh "${SSH_CONNECTION}" "${SSH_ORIGINAL_COMMAND}" "${USER}" "${HOME}""
   AllowAgentForwarding no
   AllowTcpForwarding no
   PermitTunnel no
   X11Forwarding no
EOF

service ssh reload

printf ".. [${cyan}OK${reset}\n ]"
printf "${warning} Please remove source code in $(pwd).\n"
