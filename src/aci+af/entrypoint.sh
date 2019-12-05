#start SQL Server, start the script to create the DB and import the data
/opt/mssql/bin/sqlservr & /sqlcode/attach-database.sh
while sleep $HEALTHCHECK_WAIT; do
  echo "Checking if SQL Server is alive..."
  ps aux |grep sqlservr |grep -q -v grep
  PROCESS_STATUS=$?
  # If the grep above finds anything, it exits with 0 status
  if [ $PROCESS_STATUS -ne 0 ]; then
    echo "SQL Server has exited."
    exit 1
  fi
done