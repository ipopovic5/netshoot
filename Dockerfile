FROM debian:stable-slim as fetcher
COPY build/fetch_binaries.sh /tmp/fetch_binaries.sh

RUN apt-get update && apt-get install -y \
  curl \
  wget \
  && curl -sSL -o grpcurl.tar.gz https://github.com/fullstorydev/grpcurl/releases/download/v1.8.6/grpcurl_1.8.6_linux_x86_64.tar.gz \
  && tar xzf grpcurl.tar.gz \
  && mv grpcurl /tmp/grpcurl \
  && curl -sSL -o cmctl.tar.gz https://github.com/cert-manager/cert-manager/releases/download/v1.8.1/cmctl-linux-amd64.tar.gz \
  && tar xzf cmctl.tar.gz \
  && mv cmctl /tmp/cmctl

RUN /tmp/fetch_binaries.sh

FROM alpine:3.16.0

RUN set -ex \
  && echo "http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories \
  && echo "http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
  && echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories \
  && apk update \
  && apk upgrade \
  && apk add --no-cache \
  apache2-utils \
  bash \
  bind-tools \
  bird \
  bridge-utils \
  busybox-extras \
  conntrack-tools \
  curl \
  dhcping \
  drill \
  ethtool \
  file\
  fping \
  iftop \
  iperf \
  iperf3 \
  iproute2 \
  ipset \
  iptables \
  iptraf-ng \
  iputils \
  ipvsadm \
  jq \
  libc6-compat \
  liboping \
  mtr \
  net-snmp-tools \
  netcat-openbsd \
  nftables \
  ngrep \
  nmap \
  nmap-nping \
  nmap-scripts \
  openssl \
  py3-pip \
  py3-setuptools \
  scapy \
  socat \
  speedtest-cli \
  openssh \
  strace \
  tcpdump \
  tcptraceroute \
  tshark \
  util-linux \
  vim \
  git \
  zsh \
  websocat \
  swaks

# Installing httpie ( https://httpie.io/docs#installation)
RUN pip3 install --upgrade httpie

# Installing ctop - top-like container monitor
COPY --from=fetcher /tmp/ctop /usr/local/bin/ctop

# Installing calicoctl
COPY --from=fetcher /tmp/calicoctl /usr/local/bin/calicoctl

# Installing termshark
COPY --from=fetcher /tmp/termshark /usr/local/bin/termshark

# Install cert-manager cli
COPY --from=fetcher /tmp/cmctl /usr/local/bin/cmctl

# Install grpcurl
COPY --from=fetcher /tmp/grpcurl /usr/local/bin/grpcurl

# Setting User and Home
USER root
WORKDIR /root
ENV HOSTNAME netshoot

# ZSH Themes
RUN wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh || true
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
RUN git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
COPY zshrc .zshrc
COPY motd motd

# Fix permissions for OpenShift and tshark
RUN chmod -R g=u /root
RUN chown root:root /usr/bin/dumpcap

# Running ZSH
CMD ["zsh"]
