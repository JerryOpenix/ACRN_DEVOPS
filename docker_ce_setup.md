# Install docker-ce on ubuntu 18.04.03
Note: Install docker-ce on ubuntu 18.04(LTS 10 years) is better choice.
## Uninstall old docker
sudo apt-get remove docker docker-engine docker.io  

## Install docker-ce
### setup the docker repository
```
sudo apt-get install apt-transport-https ca-certificates curl
sudo apt-get install software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
```

### install docker-ce package
```
apt-cache madison docker-ce
sudo apt-get install docker-ce=18.06.3\~ce\~3-0\~ubuntu
sudo groupadd docker
sudo usermod -aG docker $USER
reboot
```

#### check docker version
```
docker version | grep 'Version\|API'
```

## Configure Docker
Only for Shanghai SHZ site
### Configure local host docker image location
```
sudo vim /etc/docker/daemon.json
{
"data-root": "/home/nstcc3/work/docker_images",
"registry-mirrors": [
      "https://registry.docker-cn.com",
      "https://docker.mirrors.ustc.edu.cn",
      "https://hub.docker.com"]
}
```
### Configure docker server proxy
#### http proxy
```
sudo mkdir -p /etc/systemd/system/docker.service.d
sudo cat > /etc/systemd/system/docker.service.d/http-proxy.conf << EOF
[Service]
Environment="HTTP_PROXY=http://child-prc.intel.com:913/"
Environment="NO_PROXY=localhost,127.0.0.0/8,docker-registry.intel.com"
EOF
```
  
#### https proxy
```
sudo cat > /etc/systemd/system/docker.service.d/https-proxy.conf << EOF
[Service]
Environment="HTTPS_PROXY=http://child-prc.intel.com:913/"
Environment="NO_PROXY=localhost,127.0.0.0/8,docker-registry.intel.com"
EOF
```

### docker run proxy
```
cat .docker/config.json
{
    "proxies":
    {
          "default":
          {
                "httpProxy": "http://child-prc.intel.com:913",
                "httpsProxy": "http://child-prc.intel.com:913",
                "ftpProxy": "ftp://child-prc.intel.com:913"
          }
    }
}
```
  
### Configure docker server running mode
```
/lib/systemd/system/docker.service
10 # the default is not to use systemd for cgroups because the delegate issues still
11 # exists and systemd currently does not support the cgroup feature set required
12 # for containers run by docker
13 #######ExecStart=/usr/bin/dockerd -H fd://
14 EnvironmentFile=-/etc/default/docker
15 ExecStart=/usr/bin/dockerd -D $DOCKER_OPTS --default-runtime=runc
16 ExecReload=/bin/kill -s HUP $MAINPID
17 LimitNOFILE=1048576
```
### Add Google dns in docker server daemon
```
 zhonghua@zhonghua-workstation:~$ nmcli dev show | grep DNS | awk '{print $2}'
 10.248.2.5
 10.239.27.228
 172.17.6.9
 zhonghua@zhonghua-workstation:~$ cat /etc/default/docker  | grep DOCKER_OPTS
 # Use DOCKER_OPTS to modify the daemon startup options.
 DOCKER_OPTS="--dns 8.8.8.8 --dns 8.8.4.4 --dns 10.248.2.5 --dns 10.239.27.228 --dns 172.17.6.9"
```
  
## Reload systemd daemon and restart docker service
```
sudo systemctl daemon-reload
sudo systemctl restart docker
```
