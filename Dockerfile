FROM debian:12.6-slim
#FROM ubuntu:22.04


ARG version="v0.15.0-alpha"


RUN     apt-get update && \
        apt-get -y install git wget curl

RUN	mkdir /app

COPY	./entrypoint.sh /app/entrypoint.sh

WORKDIR /app

RUN 	cd /app && \
	wget https://github.com/lightninglabs/lightning-terminal/releases/download/$version/lightning-terminal-linux-386-$version.tar.gz && \
	tar xzvf lightning-terminal-linux-386-$version.tar.gz && \
	mv lightning-terminal-linux-386-$version/* .

EXPOSE 8443 10009 9735

VOLUME /root/.lnd


CMD [ "./entrypoint.sh" ]

