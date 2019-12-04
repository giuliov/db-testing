CREATE DATABASE pubs ON (
    NAME=pubs_data,FILENAME='/var/opt/mssql/data/pubs.mdf'
    ) LOG ON (
    NAME=pubs_log,FILENAME='/var/opt/mssql/data/pubs_log.ldf'
    ) FOR ATTACH;
GO
