CREATE DATABASE pubs ON (
    NAME=pubs_data,FILENAME='/sqldata/pubs.mdf'
    ) LOG ON (
    NAME=pubs_log,FILENAME='/sqldata/pubs_log.ldf'
    ) FOR ATTACH;
GO
