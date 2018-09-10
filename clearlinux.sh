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
LABEL version="ver 0.2"

# Upgrade to Clear Linux version 24120
RUN swupd verify -fYb -m 24120 -F 25

# Install Clear Linux and os-utils developement bundle
# web-server-basic scm-server java-basic os-utils-gui-dev
# https://clearlinux.org/documentation/clear-linux/reference/bundles/available-bundles#available-bundles
#RUN swupd bundle-add mixer vim c-basic dev-utils-dev package-utils \\
#	&& pip3 install kconfiglib \\
#	&& swupd clean --all
RUN swupd bundle-add os-clr-on-clr
RUN swupd bundle-add os-utils-gui-dev
RUN swupd bundle-add scm-server
RUN swupd bundle-add java-basic
RUN pip3 install kconfiglib
RUN swupd clean --all

# Create lock file directory for processes to properly coordinate access to the shared device
# Generate TLS trust store
RUN mkdir -p /run/lock \\
     && clrtrust generate

# Change the baseurl in [local] and [debuginfo] in clear.cfg
RUN sed -i 's/current/releases\/24120\/clear/g' /usr/share/defaults/mock/clear.cfg

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

#date > build_log;
#docker build --no-cache --build-arg https_proxy=http://child-prc.intel.com:913 -t hv_acrn_dev -f Dockerfile . | tee >(ts "%d-%m-%y %H_%M_%S" >> build_log);
#date >> build_log
#If you're always meet with http timeout or other network issue, please use below command:
#docker build --build-arg https_proxy=http://child-prc.intel.com:913 -t hv_acrn_dev -f Dockerfile . | tee >(ts "%d-%m-%y %H_%M_%S" >> build_log);

#run docker
# 1) --privileged: resolve mount issue
# 2) --hostname: give hostname used to track whom build the image
# 3) set https_proxy: WA git clone issue
# 4) give localtime: WA time auto sync between docker & host
#
#    docker run -it --privileged -v $PWD:/home/ryoma/ACRN_REPO \
#    --hostname "changcheng"  \
#    --env https_proxy=http://child-prc.intel.com:913 \
#    --env /etc/localtime:/etc/localtime:ro \
#    hv_acrn_dev
