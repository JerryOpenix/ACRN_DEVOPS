#!/bin/bash
#
rm -rf host_src
mkdir -p host_src
[ -d $HOME/.ssh ] && cp -frL $HOME/.ssh host_src
[ -e $HOME/.gitconfig ] && cp -frL $HOME/.gitconfig host_src
[ -d $HOME/bin ] && cp -frL $HOME/bin host_src

################Generate dockerfile#######################
cat > Dockerfile << EOF
# Build based on Centos
FROM centos:7.4.1708

MAINTAINER Liu Changcheng <changcheng.liu@intel.com>
LABEL version="ver 0.1"

RUN sed -i '/^minrate=/d; /^timeout=/d; /^assumeyes=/d; /^debuglevel=/d; /^\[main\]$/a minrate=500\ntimeout=60\nassumeyes=1\ndebuglevel=7' /etc/yum.conf
RUN sed -i 's/enabled=1/enabled=0/' /etc/yum/pluginconf.d/fastestmirror.conf
RUN yum clean all
RUN yum update

RUN yum install epel-release deltarpm

RUN yum install sudo vim-enhanced net-tools git \
	/usr/bin/yumdownloader rpm-build rpm-sign wget bind bind-utils 

RUN yum --enablerepo epel install moreutils

RUN rm /etc/yum.repos.d/CentOS-Sources.repo /etc/yum.repos.d/epel.repo
EOF

if [ ! -d stx-tools ]; then
git clone https://git.starlingx.io/stx-tools
fi

cat >> Dockerfile << EOF
COPY stx-tools/centos-mirror-tools/yum.repos.d/* /etc/yum.repos.d/
COPY stx-tools/centos-mirror-tools/rpm-gpg-keys/* /etc/pki/rpm-gpg/
EOF

cat >> Dockerfile << EOF
RUN rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY*

RUN yum update
RUN sed -i 's/enabled=0/enabled=1/' /etc/yum/pluginconf.d/fastestmirror.conf

RUN echo "export PS1=\"[\u@\h:docker \W]\\\\\$ \"" >> /root/.bashrc \\
	&& echo "export PATH=~/bin:\$PATH" >> /root/.bashrc
 
COPY host_src /root/

WORKDIR /localdisk

USER root

ENTRYPOINT ["/bin/bash"]
EOF
################End Generate dockerfile#######################
