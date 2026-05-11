FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    openvswitch-switch \
    openvswitch-common \
    iproute2 \
    iputils-ping \
    curl \
    kmod \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

COPY init-sdn.sh /init-sdn.sh

RUN chmod +x /init-sdn.sh

CMD ["/init-sdn.sh"]