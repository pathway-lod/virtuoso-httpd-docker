#!/bin/bash
#
# Virtuoso Loader Script
#
# Usage: load [data_file] [graph_uri] [log_file] [virtuoso_password]

set -e

if [ "$#" -ne 4 ]; then
    echo "Wrong number of arguments. Correct usage:"
    echo "  load [data_file] [graph_uri] [log_file] [virtuoso_password]"
    exit 1
fi

VAD="/import"
DATA_FILE="$1"     # e.g. WP1.wp.ttl  (basename, not full path)
GRAPH_URI="$2"     # e.g. http://rdf.plantwiki.org/
LOGFILE="$3"       # e.g. /database/load.log
VIRT_PSWD="$4"     # e.g. dba

# Path to isql in the openlink/virtuoso-opensource-7 image
ISQL="/opt/virtuoso-opensource/bin/isql"

echo "Loading triples from ${VAD}/${DATA_FILE} into graph <${GRAPH_URI}>..."

# Send commands to Virtuoso and append all output to the logfile
"$ISQL" 1111 dba "$VIRT_PSWD" >> "$LOGFILE" 2>&1 <<EOF
grant execute on "DB.DBA.EXEC_AS"       to "SPARQL";
grant select  on "DB.DBA.SPARQL_SINV_2" to "SPARQL";
grant execute on "DB.DBA.SPARQL_SINV_IMP" to "SPARQL";
grant SPARQL_LOAD_SERVICE_DATA          to "SPARQL";
grant SPARQL_SPONGE                     to "SPARQL";

ld_dir('${VAD}', '${DATA_FILE}', '${GRAPH_URI}');
rdf_loader_run();
select ll_file, ll_graph, ll_state, ll_error
  from DB.DBA.load_list
 where ll_file like '%${VAD}%';
EXIT;
EOF

# Add a small summary of what was executed
{
  echo "----------"
  echo "ld_dir('${VAD}', '${DATA_FILE}', '${GRAPH_URI}');"
  echo "rdf_loader_run();"
  echo "select ll_file, ll_graph, ll_state, ll_error from DB.DBA.load_list where ll_file like '%${VAD}%';"
  echo "----------"
} >> "$LOGFILE"

# Show the log to the user
cat "$LOGFILE"

echo "Loading finished! Check ${LOGFILE} for details."
exit 0