#!/bin/bash
#
rm -rf host_src
mkdir -p host_src
[ -d $HOME/.ssh ] && cp -frL $HOME/.ssh host_src
[ -e $HOME/.gitconfig ] && cp -frL $HOME/.gitconfig host_src
[ -d $HOME/bin ] && cp -frL $HOME/bin host_src

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
# Build from Clear Linux latest sdk image
FROM clearlinux/clr-sdk:latest

MAINTAINER Liu Changcheng <changcheng.liu@intel.com>
LABEL version="ver 0.2"

ENV DEBUG_KEY_PATH=https://download.clearlinux.org/secureboot/DefaultIASSigningPrivateKey.pem

# Install Clear Linux and os-utils developement bundle
# https://clearlinux.org/documentation/clear-linux/reference/bundles/available-bundles#available-bundles
RUN swupd bundle-add iasimage
RUN swupd bundle-add service-os

# Create lock file directory for processes to properly coordinate access to the shared device
# Generate TLS trust store
RUN mkdir -p /run/lock && rm -rf /run/lock/clrtrust.lock && clrtrust generate

RUN groupadd --gid $gid $username \\
	&& useradd --gid $gid --uid $uid $username \\
   	&& usermod -G wheel -a $username \\
	&& echo -e '$root_passwd' > /etc/shadow \\
	&& echo -e '$user_passwd' >> /etc/shadow \\
	&& chmod 000 /etc/shadow \\
	&& mkdir -p /etc/sudoers.d \\
	&& echo "%root    ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/$username \\
	&& chown $username:$username -R /home/$username

#adding user to mock group for access to running mock
RUN usermod -a -G mock,wheelnopw $username

RUN echo "export PS1=\"[\u@\h:\W]\\\\\$ \"" >> /home/$username/.bashrc \\
	&& echo "export PATH=~/bin:\$PATH" >> /home/$username/.bashrc

COPY host_src /home/$username/

WORKDIR /home/$username/mix
USER $username

# WA problems:
#  clearlinux force users to use /usr/bin/setup.py as the entrypoint of docker image.
#  There're some problems:
#     1. it's buggy as programmer write that kind of script, such as
#			1 #!/usr/bin/python3
#			2 +-- 50 lines: import argparse------------------
#			52                          
#			53 user = "clr"
#			54 
#			55 # Create the group and user
#			56 +-- 21 lines: try:---------------------------
#			77 user = "clr"
#			78 
#			79 # Create the group and user
#     2. It can't track who build the images
#
#  So, we define another entrypoint to overried /usr/bin/setup.py
ENTRYPOINT ["/bin/bash"]

EOF

#date > build_log;
#docker build --no-cache --build-arg https_proxy=http://child-prc.intel.com:913 -t sos_clr_sdk -f Dockerfile . | tee >(ts "%d-%m-%y %H_%M_%S" >> build_log);
#date >> build_log
#If you're always meet with http timeout or other network issue, please use below command:
#docker build --build-arg https_proxy=http://child-prc.intel.com:913 -t sos_clr_sdk -f Dockerfile . | tee >(ts "%d-%m-%y %H_%M_%S" >> build_log);

#run docker
# 1) --privileged: resolve mount issue
# 2) --hostname: give hostname used to track whom build the image
# 3) set https_proxy: WA git clone issue
# 4) give localtime: WA time auto sync between docker & host
#
#    docker run -it --privileged -w $PWD -v $PWD:$PWD \
#    --hostname $(hostname)  -v /dev:/dev -v /tmp:/tmp -v /var:/var \
#    --env https_proxy=http://child-prc.intel.com:913 --env http_proxy=http://child-prc.intel.com:913 \
#    --env /etc/localtime:/etc/localtime:ro \
#    sos_clr_sdk --mixdir=$PWD
