# Build from Clear Linux base image
# start container: docker run -it --env https_proxy=http://child-prc.intel.com:913 clear_linux_docker_image
FROM clearlinux:base

# Create lock file directory for processes to properly coordinate access to the shared device
RUN mkdir -p /run/lock

# Generate TLS trust store
RUN clrtrust generate

# Upgrade to Clear Linux version 20910
RUN swupd verify -f -m 20910 --force

# Install Clear Linux and os-utils-gui development bundle
RUN swupd bundle-add os-clr-on-clr os-utils-gui-dev

# Change the baseurl in [local] and [debuginfo] in clear.cfg
RUN sed -i 's/current/releases\/20910\/clear/g' /usr/share/defaults/mock/clear.cfg

# Entrypoint script to allow user account to be created dynamically
RUN mkdir -p /usr/local/bin
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
