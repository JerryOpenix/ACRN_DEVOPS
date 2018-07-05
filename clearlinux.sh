#!/bin/bash
#
rm -rf host_src
mkdir -p host_src
cp -frL ~/.ssh host_src
cp -frL ~/.gitconfig host_src
cp -frL ~/bin host_src

username=`whoami`
if [ "$username" == "root" ];then
	username=$SUDO_USER
fi
uid=`id -u $username`
gid=`id -g $username`
user_passwd=`sudo grep "$username:" /etc/shadow`
root_passwd=`sudo grep "root:" /etc/shadow`

################Generate dockerfile#######################
cat > Dockerfile << EOF
# Build from Clear Linux base image
FROM clearlinux:base

MAINTAINER Liu Changcheng <changcheng.liu@intel.com>
LABEL version="ver 0.1"

# Create lock file directory for processes to properly coordinate access to the shared device
# Generate TLS trust store
RUN mkdir -p /run/lock \\
     && clrtrust generate

# Upgrade to Clear Linux version 22780
RUN swupd verify -fYb -m 22780 -F 25

# Install Clear Linux and os-utils developement bundle
# https://clearlinux.org/documentation/clear-linux/reference/bundles/available-bundles#available-bundles
RUN swupd bundle-add mixer vim c-basic dev-utils-dev package-utils \\
	&& pip3 install kconfiglib \\
	&& swupd clean --all

# Change the baseurl in [local] and [debuginfo] in clear.cfg
RUN sed -i 's/current/releases\/22780\/clear/g' /usr/share/defaults/mock/clear.cfg

RUN groupadd --gid $gid $username \\
	&& useradd --gid $gid --uid $uid $username \\
   	&& usermod -G wheel -a $username \\
	&& echo -e '$root_passwd' > /etc/shadow \\
	&& echo -e '$user_passwd' >> /etc/shadow \\
	&& chmod 000 /etc/shadow \\
	&& mkdir -p /etc/sudoers.d \\
	&& echo "%root    ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/$username \\
	&& chown $username:$username -R /home/$username

RUN echo "export PS1=\"[\u@\h:\W]\\\\\$ \"" >> /home/$username/.bashrc \\
	&& echo "export PATH=~/bin:\$PATH" >> /home/$username/.bashrc

COPY host_src /home/$username/

WORKDIR /home/$username/ACRN_REPO
USER $username

CMD ["bash"]
EOF

#docker build -t acrn_clrdev:22780 -f Dockerfile .
