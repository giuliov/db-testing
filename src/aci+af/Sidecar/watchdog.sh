#wait for the SQL Server to come up
sleep $AVAILABLE_WAIT
#start SQL Server, start the script to create the DB and import the data
while sleep $POLL_WAIT; do
  echo "Querying SQL Server..."
  /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $SA_PASSWORD -d pubs -Q "SELECT TOP 10 * FROM employee"
done