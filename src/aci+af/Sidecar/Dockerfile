FROM mcr.microsoft.com/mssql-tools

ENV AVAILABLE_WAIT=1m
ENV POLL_WAIT=15s
ENV SA_PASSWORD=

COPY watchdog.sh .
RUN chmod +x watchdog.sh
CMD [ "/bin/sh", "watchdog.sh" ]