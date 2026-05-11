FROM python:3.8-slim-bookworm

ENV PYTHONDONTWRITEBYTECODE=1 \
	PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y --no-install-recommends \
	gcc \
	libffi-dev \
	libssl-dev \
	curl \
	&& rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir \
	eventlet==0.30.2 \
	ryu==4.34 \
	netaddr \
	routes \
	webob==1.8.5

EXPOSE 6653 8080

CMD ["ryu-manager", "--ofp-tcp-listen-port", "6653", "--wsapi-port", "8080", "ryu.app.simple_switch_13", "ryu.app.ofctl_rest"]