FROM ubuntu:18.04

RUN apt-get update && \
		apt-get install -y openconnect net-tools openssh-client dante-server wget && \
		apt-get clean && \
		rm -rf /var/lib/apt/lists/*

ADD danted.conf /etc/danted.conf
ADD .cisco /root/.cisco
ADD oc.sh /bin
EXPOSE 1081
ENTRYPOINT ["oc.sh"]

