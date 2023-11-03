FROM ubuntu:22.04


RUN     apt-get update && \
        apt-get -y install git wget curl

RUN	mkdir /app

COPY	./entrypoint.sh /app/entrypoint.sh

WORKDIR /app

RUN 	cd /app && \
	wget https://github.com/lightninglabs/lightning-terminal/releases/download/v0.12.0-alpha/lightning-terminal-linux-386-v0.12.0-alpha.tar.gz && \
	tar xzvf lightning-terminal-linux-386-v0.12.0-alpha.tar.gz && \
	mv lightning-terminal-linux-386-v0.12.0-alpha/* .


CMD [ "./entrypoint.sh" ]

