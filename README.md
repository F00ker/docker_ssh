# docker_ssh

Docker-ssh: Ruby script for run a ssh connexion in a docker environment
============================

## Requirement 

This script require :
  * Openssh server
  * Sudo package (for auto install >= 1.8.2)
  * Ruby enrionment >= 1.9

## Install

### Manualy

Create the docker-ssh environment (directory, group, binary)

```bash
-> root@test ~ mkdir -p /etc/docker-ssh/{containers,extra} && touch /etc/docker-ssh/docker-ssh.passwd

-> root@test ~ cp docker-ssh.rb /usr/local/bin/docker-ssh && chmod 700 /usr/local/bin/docker-ssh && chown root:root /usr/local/bin/docker-ssh

-> root@test ~ groupadd docker-ssh
```

Add in your ssh configuration the group match and forcecommand :

```bash
Match Group docker-ssh
   ForceCommand sudo /usr/local/bin/docker-ssh "${SSH_CONNECTION}" "${SSH_ORIGINAL_COMMAND}" "${USER}" "${HOME}"
   AllowAgentForwarding no
   AllowTcpForwarding no
   PermitTunnel no
   X11Forwarding no
```

Add the sudo config for docker-ssh group :
```bash
%docker-ssh ALL= NOPASSWD: /usr/local/bin/docker-ssh

```
If you're multi multi ruby environment, please defined the path of ruby version in the binary. Example for Debian 7 :

```bash
-> root@test ~ head -n 1 /usr/local/bin/docker-ssh
#!/usr/bin/ruby1.9.1 
```

### Automaticly

Run the script install.sh (validate on Debian 7 && 8). If you're have problem with another distribution, check manualy install for validate install.

## Add a conainer

For add a container, define the configuration on */etc/docker-ssh/containers/<image_name>/properties.conf*. The directory name is the name of the Docker image. Example for image default-ssh :

```bash 
docker images               
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
default-ssh         ssh                 7f94494afd9a        5 days ago          243.2 MB
debian              8                   47af6ca8a14a        3 weeks ago         125.1 MB

cat /etc/docker-ssh/containers/default-ssh/properties.conf
unix_uid = 1001
unix_gid = 33
container_user = deployuser_ssh-test

```

properties.conf options on :

  * unix_uid, the real user or uid on the server (define on the Dockerfile : RUN useradd -u <this_uid> -g 33 -m deployuser_ssh-test)

  * unix_gid, the real group or gid on the server (define on the Dockerfile : RUN useradd -u 1001 -g <this_gid> -m deployuser_ssh-test)

  * container_user, the name on the docker container (define on the Dockerfile : RUN useradd -u 1001 -g 33 -m <this_user>)


## Add user

Users was defined on */etc/docker-ssh/docker-ssh.passwd* :

```bash
user:home:container:dir
```

Options on :

  * user, name of the user

  * home, optional option, this is the directory was forwad for home user. Default value is ~/docker-ssh_<user>

  * container, the name of the Docker images name

  * dir, the name of the directory was forward on the Docker. If you've multi directory, split with , (ex : /var/log,/var/www/)

## Example

With bob user :

```bash
-> root@test ~ ruby -v
ruby 2.1.5p273 (2014-11-13) [x86_64-linux-gnu]

-> root@test ~ git clone https://github.com/fe80/docker_ssh.git /root/docker_ssh
Clonage dans '/root/docker_ssh'...
remote: Counting objects: 94, done.
remote: Compressing objects: 100% (47/47), done.
remote: Total 94 (delta 27), reused 0 (delta 0), pack-reused 47
Dépaquetage des objets: 100% (94/94), fait.
Vérification de la connectivité... fait.

-> root@test ~ cd /root/docker_ssh                                              

-> root@test ~/docker_ssh ./install.sh 
[info] Start install.. 
[warning] This script modify sudoers.conf, can you validate ? [Y/n] : Y
[warning] This script modify sshd_config and reload ssh deamon, can you validate ? [Y/n] : Y
.. Installation [OK] 
[warning] Please remove source code in /root/docker_ssh.

-> root@test ~/docker_ssh cd ../

-> root@test ~ rm -rf docker_ssh 

-> root@test ~ mkdir /etc/docker-ssh/containers/default-ssh

-> root@test ~ cd /etc/docker-ssh/containers/default-ssh

-> root@test /etc/docker-ssh/containers/default-ssh cat properties.conf 
unix_uid = 1001
unix_gid = 33
container_user = deployuser_ssh-test

-> root@test /etc/docker-ssh/containers/default-ssh fgrep -i deployuser /etc/passwd
deployuser:x:1001:1002::/home/deployuser:/bin/sh

-> root@test /etc/docker-ssh/containers/default-ssh fgrep -i 33 /etc/group
www-data:x:33:

-> root@test /etc/docker-ssh/containers/default-ssh docker pull debian:8
8: Pulling from library/debian
efd26ecc9548: Pull complete 
a3ed95caeb02: Pull complete 
Digest: sha256:9b61122861071cc62760b248bea19f3d4608e6e620662c1e2f4de51f0d720149
Status: Downloaded newer image for debian:8

-> root@test /etc/docker-ssh/containers/default-ssh cat Dockerfile                   
# Image based on a minimal Debian install
# We add some tools needed by developpers
# Also, we set a specific user used when running a container

FROM debian:8

MAINTAINER fe80 <steffyfort@gmail.com>

RUN useradd -u 1001 -g 33 -m deployuser_ssh-test

RUN apt-get update && apt-get install -y telnet \
    vim \
    mysql-client

ENV TMOUT 21600

USER deployuser_ssh-test

WORKDIR /home/deployuser_ssh-test

-> root@test /etc/docker-ssh/containers/default-ssh docker build -t default-ssh:ssh .

-> root@test /etc/docker-ssh/containers/default-ssh docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
default-ssh         ssh                 7f94494afd9a        4 seconds ago       243.2 MB
debian              8                   47af6ca8a14a        2 weeks ago         125.1 MB

-> root@test /etc/docker-ssh/containers/default-ssh adduser bob       
Ajout de l'utilisateur « bob » ...
Ajout du nouveau groupe « bob » (1003) ...
Ajout du nouvel utilisateur « bob » (1002) avec le groupe « bob » ...
Création du répertoire personnel « /home/bob »...
Copie des fichiers depuis « /etc/skel »...
Entrez le nouveau mot de passe UNIX : 
Retapez le nouveau mot de passe UNIX : 
passwd : le mot de passe a été mis à jour avec succès
Modification des informations relatives à l'utilisateur bob
Entrez la nouvelle valeur ou « Entrée » pour conserver la valeur proposée
  Nom complet []: 
  N° de bureau []: 
  Téléphone professionnel []: 
  Téléphone personnel []: 
  Autre []: 
Cette information est-elle correcte ? [O/n]

-> root@test /etc/docker-ssh/containers/default-ssh usermod -G docker-ssh bob

-> root@test /etc/docker-ssh/containers/default-ssh cd /etc/docker-ssh

-> root@test /etc/docker-ssh cat docker-ssh.passwd
# Example
bob::default-ssh:/var/log,/var/www/


# Client connexion :

ssh bob@test

deployuser_ssh-test@test:~$ ls -la
total 24
drwxrwxr-x 3 deployuser_ssh-test www-data 4096 Apr 27 13:51 .
drwxr-xr-x 3 root                root     4096 Apr 22 13:53 ..
-rw------- 1 deployuser_ssh-test www-data  594 Apr 27 13:42 .bash_history
-rw-r--r-- 1 deployuser_ssh-test www-data  194 Apr 22 14:32 .bash_profile
-rw-r--r-- 1 deployuser_ssh-test www-data  633 Apr 22 14:32 .bashrc
drwxr-xr-x 2 deployuser_ssh-test www-data 4096 Apr 25 16:57 .ssh

deployuser_ssh-test@test:~$ touch toto_home && ls -l toto_home
-rw-r--r-- 1 deployuser_ssh-test www-data 0 Apr 27 13:51 toto_home

deployuser_ssh-test@test:~$ cd /var/www/project0 && touch index.html && ls -l index.html
-rw-r--r-- 1 deployuser_ssh-test www-data 0 Apr 27 13:53 index.html

# On server
-> root@test ~ ls -l /home/bob/docker-ssh_bob/toto_home /var/www/project0/index.html 
-rw-r--r-- 1 deployuser www-data 0 avril 27 15:51 /home/bob/docker-ssh_bob/toto_home
-rw-r--r-- 1 deployuser www-data 0 avril 27 15:53 /var/www/project0/index.html
```

## Todo list

* Crontab

* Ssh home configuration

* Add/change/del container, user conf on script
