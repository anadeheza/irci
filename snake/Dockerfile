FROM ubuntu:22.04
RUN apt-get update -qq && apt-get install -y -qq socat python3 && rm -rf /var/lib/apt/lists/*
COPY rtm32 /rtm32
RUN chmod +x /rtm32
COPY rtm32.asm-1.1.0/snake.mdbg /snake.mdbg
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
EXPOSE 4444 5555
CMD ["/docker-entrypoint.sh"]
