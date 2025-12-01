#!/bin/bash
set -e

SNORQL_JS="/usr/local/apache2/htdocs/assets/js/snorql.js"
INDEX_HTML="/usr/local/apache2/htdocs/index.html"

# Defaults if env vars are not set
ENDPOINT="${SNORQL_ENDPOINT:-/sparql}"
EXAMPLES_REPO="${SNORQL_EXAMPLES_REPO:-https://github.com/pathway-lod/SPARQLQueries}"
DEFAULT_GRAPH_URI="${DEFAULT_GRAPH:-http://rdf.plantwiki.org/}"
TITLE="${SNORQL_TITLE:-Plant Pathways Wiki Snorql UI}"

echo "Configuring Snorql:"
echo "  endpoint      = ${ENDPOINT}"
echo "  examples repo = ${EXAMPLES_REPO}"
echo "  default graph = ${DEFAULT_GRAPH_URI}"
echo "  title         = ${TITLE}"

if [ -f "${SNORQL_JS}" ]; then
  # endpoint (matches double-quoted value)
  sed -i -E "s#var _endpoint = \".*\";#var _endpoint = \"${ENDPOINT}\";#" "${SNORQL_JS}"
  # examples repo
  sed -i -E "s#var _examples_repo = \".*\";#var _examples_repo = \"${EXAMPLES_REPO}\";#" "${SNORQL_JS}"
  # default graph
  sed -i -E "s#var _defaultGraph = \".*\";#var _defaultGraph = \"${DEFAULT_GRAPH_URI}\";#" "${SNORQL_JS}"
else
  echo "WARNING: ${SNORQL_JS} not found, skipping JS config"
fi

if [ -f "${INDEX_HTML}" ]; then
  sed -i -E "s#<title>.*</title>#<title>${TITLE}</title>#" "${INDEX_HTML}"
else
  echo "WARNING: ${INDEX_HTML} not found, skipping title config"
fi