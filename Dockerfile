FROM alpine:latest AS builder
RUN apk update && \
	apk add unzip git

WORKDIR /tmp
ADD https://github.com/nats-io/natscli/releases/download/v0.1.4/nats-0.1.4-linux-amd64.zip .
RUN unzip nats-0.1.4-linux-amd64.zip && chmod +x nats-0.1.4-linux-amd64
ADD https://dist.neo4j.org/cypher-shell/cypher-shell-5.20.0.zip .
RUN unzip cypher-shell-5.20.0.zip
ADD https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.i686 .
RUN chmod +x ./ttyd.i686
RUN git clone -b dev --depth 1 https://github.com/mindwm/poc-mindwm-dev 

FROM alpine:latest

RUN apk update && \
 	apk add py3-pip tmux kubectl helm openjdk21-jre-headless asciinema uuidgen \
	bash shadow
    
RUN chsh -s /bin/bash root
WORKDIR /tmp
ADD ./requirements.txt .
RUN pip3 install --break-system-packages -r ./requirements.txt
COPY --from=builder /tmp/nats-0.1.4-linux-amd64/nats /usr/local/bin/nats
COPY --from=builder /tmp/cypher-shell-5.20.0/ /usr/local/cypher-shell
COPY --from=builder /tmp/ttyd.i686 /usr/local/bin/ttyd
COPY --from=builder /tmp/poc-mindwm-dev/mindwm-manager/src/ /usr/local/mindwm-manager
COPY ./entrypoint.yaml /root/.tmuxp/entrypoint.yaml

ENV PATH="/usr/local/cypher-shell/bin/:$PATH" 
# workaround for https://github.com/tmux-python/libtmux/issues/265
ENV LANG=C 
ENV PORT=80
# workaround for PS1
# for some reason ENV PS1=\u@\h:~\W doesn't work
RUN echo 'export PS1="\u@\h:~\W $ "' >> /etc/bash/bashrc # alpine specific path 
#ENV SHELL=/bin/bash

ENTRYPOINT ["/bin/bash", "-c", "export MINDWM_UUID=`uuidgen`; tmuxp load -d ~/.tmuxp/entrypoint.yaml && sleep 5 && tmux ls && ttyd -W -p${PORT} tmux attach" ]
