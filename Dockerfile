
FROM ubuntu:18.04

RUN apt-get update && apt-get install -y openconnect net-tools openssh-client dante-server && apt-get clean && rm -rf /var/lib/apt/lists/*
ADD privoxy-start.sh /usr/local/bin/
ADD config /etc/privoxy/
RUN chmod +r /etc/privoxy/config && chmod +x /usr/local/bin/privoxy-start.sh

ADD danted.conf /etc/danted.conf
ADD .cisco /root/.cisco

EXPOSE 1081 3389

CMD ["privoxy-start.sh"]

