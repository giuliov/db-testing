# Demo for "Use SQL Server for Linux and Docker to streamline your test and schema migration process"

####### FROM #######
FROM mcr.microsoft.com/mssql/server:2019-GA-ubuntu-16.04 AS build

ENV ACCEPT_EULA=Y
ENV SA_PASSWORD=Test@12345
ENV MSSQL_PID=Developer
ENV ATTACH_WAIT=10s

WORKDIR /sqlcode
# this works only for Linux containers
COPY pubs.bak /sqlbackup/
COPY clean-data.sql /sqlcode/
RUN (/opt/mssql/bin/sqlservr --accept-eula & ) \
    | grep -q "Service Broker manager has started" \
    && /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $SA_PASSWORD -Q "RESTORE DATABASE pubs FROM DISK='/sqlbackup/pubs.bak';"
RUN (/opt/mssql/bin/sqlservr --accept-eula & ) \
    | grep -q "Service Broker manager has started" \
    && /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $SA_PASSWORD -d pubs -i /sqlcode/clean-data.sql

####### FROM #######
FROM mcr.microsoft.com/mssql/server:2019-GA-ubuntu-16.04

ENV ATTACH_WAIT=30s

WORKDIR /sqlcode
# this works only for Linux containers
COPY --chown=mssql:root . /sqlcode/
RUN chmod +x /sqlcode/*.sh
COPY --chown=mssql:root --from=build /var/opt/mssql/data/pubs.mdf /sqldata/
COPY --chown=mssql:root --from=build /var/opt/mssql/data/pubs_log.ldf /sqldata/

CMD /bin/bash ./entrypoint.sh
