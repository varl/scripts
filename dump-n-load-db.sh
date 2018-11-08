#!/usr/bin/env bash
#PSQL=/usr/lib/postgresql/9.6/bin/psql
PSQL=psql
URL=https://github.com/dhis2/dhis2-demo-db/raw/master/sierra-leone/dev/dhis2-db-sierra-leone.sql.gz                          
#URL=https://github.com/dhis2/dhis2-demo-db/raw/6e4fbdb84ea07cd78aa386e44003b556edc5d74a/sierra-leone/dev/dhis2-db-sierra-leone.sql.gz
#URL=https://github.com/dhis2/dhis2-demo-db/raw/97efb91265d60009c27428683d12741d565af3be/sierra-leone/dev/dhis2-db-sierra-leone.sql.gz
#URL=https://github.com/dhis2/dhis2-demo-db/raw/97efb91265d60009c27428683d12741d565af3be/sierra-leone/2.30/dhis2-db-sierra-leone.sql.gz

curl -L -o demo.sql.gz "$URL" -o demo.sql.gz
gunzip demo.sql.gz
chmod 777 demo.sql
#sudo -u dhis sh /opt/dhis2/tcs/dev/bin/shutdown.sh
sudo -u postgres "$PSQL" -c "drop database dhis2_dev;"
sudo -u postgres "$PSQL" -c 'create database "dhis2_dev";'
sudo -u postgres "$PSQL" -c 'grant all privileges on database "dhis2_dev" to dhis;'
sudo -u postgres "$PSQL" -d dhis2_dev -f demo.sql -v ON_ERROR_STOP=1                                                         
rm demo.sql
