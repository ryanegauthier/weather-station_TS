#!/bin/bash
set -e

POSTGRES="psql --username postgres"

echo "Creating database role: grafana"

$POSTGRES <<-EOSQL
CREATE USER grafana WITH CREATEDB PASSWORD 'p0stgr3s';
EOSQL