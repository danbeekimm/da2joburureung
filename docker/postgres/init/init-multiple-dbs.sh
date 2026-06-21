#!/bin/bash
set -e

echo ">>> initializing multiple databases"

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres <<-EOSQL
    CREATE DATABASE "${USER_DB}";
    CREATE DATABASE "${NOTIFICATION_DB}";
    CREATE DATABASE "${DELIVERY_DB}";
    CREATE DATABASE "${COMPANY_DB}";
    CREATE DATABASE "${HUB_DB}";
    CREATE DATABASE "${PRODUCT_DB}";
    CREATE DATABASE "${ORDER_DB}";
    CREATE DATABASE "${AI_DB}";
EOSQL

echo ">>> multiple databases created"