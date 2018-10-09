# Install docker-ce on ubuntu 16.04
## Uninstall old docker
sudo apt-get remove docker docker-engine docker.io  

## Install docker-ce
### setup the docker repository
sudo apt-get install apt-transport-https ca-certificates curl  
sudo apt-get install software-properties-common  
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -  
sudo apt-key fingerprint 0EBFCD88  
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"  
sudo apt-get update  

### install docker-ce package
apt-cache madison docker-ce  
sudo apt-get install docker-ce=18.06.1\~ce\~3-0\~ubuntu  
sudo groupadd docker  
sudo usermod -aG docker $USER  
reboot  

#### check docker version
docker version | grep 'Version\|API'  

## Configure Docker
Only for Shanghai SHZ site
### Configure local host docker image location
sudo vim /etc/docker/daemon.json  
&nbsp;&nbsp;&nbsp;&nbsp;{    
&nbsp;&nbsp;&nbsp;&nbsp;"data-root": "home/GP20/LINUX/docker/image",   
&nbsp;&nbsp;&nbsp;&nbsp;"registry-mirrors": [  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"https://registry.docker-cn.com",  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"https://docker.mirrors.ustc.edu.cn",  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;"https://hub.docker.com"]   
&nbsp;&nbsp;&nbsp;&nbsp;}  
### Configure docker server proxy
#### http proxy
sudo mkdir -p /etc/systemd/system/docker.service.d  
sudo cat > /etc/systemd/system/docker.service.d/http-proxy.conf << EOF  
[Service]  
Environment="HTTP_PROXY=http://child-prc.intel.com:913/"  
Environment="NO_PROXY=localhost,127.0.0.0/8,docker-registry.intel.com"  
EOF  
  
#### https proxy
sudo cat > /etc/systemd/system/docker.service.d/https-proxy.conf << EOF  
[Service]  
Environment="HTTPS_PROXY=http://child-prc.intel.com:913/"  
Environment="NO_PROXY=localhost,127.0.0.0/8,docker-registry.intel.com"  
EOF  
  
### Configure docker server running mode
sudo cat > /etc/systemd/system/docker.service.d/docker-containers.conf  << EOF  
[Service]  
EnvironmentFile=-/etc/default/docker  
ExecStart=  
ExecStart=/usr/bin/dockerd -D $DOCKER_OPTS --default-runtime=runc  
EOF  
  
### Resolve docker server dns problem in SHZ site
#### disable dnsmasq on ubuntu 16.04 and restart network manager
cat /etc/NetworkManager/NetworkManager.conf  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[main]  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;plugins=ifupdown,keyfile,   
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;#dns=dnsmasq  
  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;[ifupdown]    
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;managed=false   
  
sudo service network-manager restart  
  
### Add Google dns in docker server daemon
 zhonghua@zhonghua-workstation:~$ nmcli dev show | grep DNS | awk '{print $2}'  
 10.248.2.5  
 10.239.27.228  
 172.17.6.9  
  
 zhonghua@zhonghua-workstation:~$ cat /etc/default/docker  | grep DOCKER_OPTS  
 # Use DOCKER_OPTS to modify the daemon startup options.
 DOCKER_OPTS="--dns 8.8.8.8 --dns 8.8.4.4 --dns 10.248.2.5 --dns 10.239.27.228 --dns 172.17.6.9"  
  
## Reload systemd daemon and restart docker service
sudo systemctl daemon-reload  
sudo systemctl restart docker  
