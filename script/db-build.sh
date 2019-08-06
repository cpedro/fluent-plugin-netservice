#!/bin/sh

dir="lib/fluent/plugin"

set -e

[ "${PWD##*/}" == "fluent-plugin-port-to-service" ] || exit 1
[ -f /etc/services ] || exit 1

[ -f ${dir}/port_to_service.db ] && rm -f ${dir}/port_to_service.db

echo "CREATE TABLE services(id INTEGER PRIMARY KEY, port INTEGER, protocol TEXT, service TEXT);" > ${dir}/port_to_service.sql
grep -Ev '^\s*$|^\s|^#' /etc/services | awk '{print $1 " " $2}' | sed 's/\// /g' | awk '{print "INSERT INTO services(port, protocol, service) VALUES (" $2 ", \"" $3 "\", \"" $1 "\");"}' >> ${dir}/port_to_service.sql
sqlite3 ${dir}/port_to_service.db < ${dir}/port_to_service.sql
