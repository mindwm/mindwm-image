FROM alpine:latest AS builder
RUN apk update && \
	apk add unzip 

WORKDIR /tmp
ADD https://github.com/nats-io/natscli/releases/download/v0.1.4/nats-0.1.4-linux-amd64.zip .
RUN unzip nats-0.1.4-linux-amd64.zip && chmod +x nats-0.1.4-linux-amd64
ADD https://dist.neo4j.org/cypher-shell/cypher-shell-5.20.0.zip .
RUN unzip cypher-shell-5.20.0.zip


FROM alpine:latest

RUN apk update && \
 	apk add py3-pip tmux kubectl helm openjdk21-jre-headless
    
WORKDIR /tmp
ADD ./requirements.txt .
RUN pip3 install --break-system-packages -r ./requirements.txt
COPY --from=builder /tmp/nats-0.1.4-linux-amd64/nats /usr/local/bin/nats
COPY --from=builder /tmp/cypher-shell-5.20.0/ /usr/local/cypher-shell

ENV PATH="/usr/local/cypher-shell/bin/:$PATH" 
