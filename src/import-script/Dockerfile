# Demo for "Use SQL Server for Linux and Docker to streamline your test and schema migration process"

FROM mcr.microsoft.com/mssql/server:2019-GA-ubuntu-16.04

WORKDIR /sqlcode
# this works only for Linux containers
COPY --chown=mssql:root . /sqlcode
RUN chmod +x /sqlcode/*.sh

CMD /bin/bash ./entrypoint.sh
