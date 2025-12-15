# 🌱 PlantMetWiki – Virtuoso + Apache + SNORQL Docker Image

This repository builds a Docker image that runs Virtuoso OpenSource and an Apache web server in the same container.
It also includes:
	•	A data loader for RDF files (load.sh)
	•	The SNORQL UI for browsing/querying the knowledge graph
	•	A simple reverse proxy that allows the UI to query the Virtuoso SPARQL endpoint

This setup powers the PlantMetWiki knowledge graph project.

## 🚀 1. Clone This Repository

```bash
# forked repository 
git clone git@github.com:pathway-lod/virtuoso-httpd-docker.git
cd virtuoso-httpd-docker
```



## 🏗 2. Build the Docker Image

```bash
docker build --no-cache -t wikipathways-virtuoso-httpd .
```

Stop + remove container if there was already a running one:
```bash 
docker stop wikipathways-virtuoso-httpd && docker rm wikipathways-virtuoso-httpd
```

## 📦 3. Prepare Local Folders

Create two directories:

Folder
Purpose
Mounted inside container
PATH_TO_VIRTUOSO_DATA_FOLDER
Stores Virtuoso DB files (persistent)
/data
PATH_TO_VIRTUOSO_IMPORT_FOLDER
Contains .ttl RDF files to be imported
/import

```bash 
mkdir -p /local/data/plantwiki/plantwikifiles/data
mkdir -p /local/data/plantwiki/plantwikifiles/import
```

## ▶️ 4. Run the Container

  Important:
  The first time you run Virtuoso, the password is dba.
  You can change it later at http://localhost:8900/conductor > Systen Admin > User Accounts > dba user 

If you don't know the default graph URI, don't include it in your run command. Otherwise, the queries will not work against the endpoint.

```bash

docker run --name wikipathways-virtuoso-httpd \
  -p 8900:8890 \
  -p 1911:1111 \
  -p 8088:80 \
  -p 8449:443 \
  -e DBA_PASSWORD=dba \
  -e SPARQL_UPDATE=true \
  -e SNORQL_ENDPOINT=https://plantmetwiki.bioinformatics.nl/sparql \
  -e SNORQL_EXAMPLES_REPO=https://github.com/pathway-lod/SPARQLQueries \
  -e SNORQL_TITLE="Plant Pathways Wiki Snorql UI" \
  -e DEFAULT_GRAPH="http://plantmetwiki.bioinformatics.nl" \
  -v /local/data/plantwiki/plantwikifiles/import:/import \
  -v /local/data/plantwiki/plantwikifiles/data:/database \
  -d wikipathways-virtuoso-httpd

```

Port summary:
```
8900 → Virtuoso UI + SPARQL       (http://localhost:8900/sparql)
1911 → ISQL interactive console
8088 → SNORQL user interface      (http://localhost:8088/)
8449 → HTTPS if configured
```

Check if container is running: 
```bash 
docker ps -a | grep virtuoso-httpd 
# view logs and errors 
docker logs wikipathways-virtuoso-httpd
``` 

Tip: if the UI is not updated, clear the cache with Cmd+Shift+R on Chrome on Mac. 

Backup + reset database:
```bash 
cd /local/data/plantwiki/plantwikifiles/data
DATE=$(date +%Y%m%d_%H%M)
mkdir -p dumps/backup_$DATE

shopt -s extglob
mv !(dumps) dumps/backup_$DATE/
shopt -u extglob
```

Visit `http://localhost:8088/` to check if it is working (Use Forward Port when working on a remote server). 

## 📥 5. Loading Data (RDF / TTL files)

If you need to import RDF data into Virtuoso, just make sure the RDF file is in the directory you already mapped to /import in the run command (Step 4). Then run the following command from terminal (make sure to change to file name and the graph IRI where you want to load the data under in Virtuoso). 

Place .ttl files into: 
```bash
/local/data/plantwiki/plantwikifiles/import
```

Note: IRI: Internal Resource Identifier 

Inside your Docker image, the load script works like this:
`/load.sh <file_or_pattern> <graph IRI> <logfile> <DBA password>`

Then load the data: 

```bash
# created directory data in the docker 
docker exec -it wikipathways-virtuoso-httpd mkdir -p /data

# run all the TTL files 
# Change the password! 
docker exec -it wikipathways-virtuoso-httpd bash -c '
for f in /import/*.ttl; do
  bn=$(basename "$f")
  echo "Loading $bn ..."
  /load.sh "$bn" "http://plantmetwiki.bioinformatics.nl/" "/data/load.log" "dba"
done
'
```

Check load status:
(Change the password!)
```bash 
docker exec -i wikipathways-virtuoso-httpd isql 1111 dba dba <<'EOF'
SELECT ll_file, ll_graph, ll_state, ll_error FROM DB.DBA.load_list;
EXIT;
EOF
```

## 🔍 6. Querying the Data

Visit SNORQL UI at:
 `http://localhost:8088/` 

Set the endpoint to: 
 `http://localhost:8900/sparql` 


Then run: 

List graphs
```sparql
SELECT DISTINCT ?g WHERE {
  GRAPH ?g { ?s ?p ?o }
}
```

To count all the triples 
```sparql
SELECT ?g (COUNT(*) AS ?triples)
WHERE {
  GRAPH ?g { ?s ?p ?o }
}
GROUP BY ?g
ORDER BY DESC(?triples)
LIMIT 50
```

Look inside the PlantMetWiki graph
```sparql
SELECT ?s ?p ?o
FROM <http://plantmetwiki.bioinformatics.nl/>
WHERE {
  ?s ?p ?o .
}
LIMIT 20
```

## 🌐 7. Deploying Production Hostnames (optional)

Public UI:
`https://plantmetwiki.bioinformatics.nl` → container port 8088

Public SPARQL endpoint:
`https://sparql-plantmetwiki.bioinformatics.nl/sparql` → container port 8900


## 🛠 Troubleshooting 

Restart Virtuoso: 
```
docker restart wikipathways-virtuoso-httpd
```

If you want to make changes to the Snorql-UI, you have to remove and rebuild the container from the beginning. 

If container fails after deleting /data manually

Fix: stop container → empty data folder → restart → reload RDF.

If the RDF is not working correctly, try reloading the data or data of the previous month using the documentation at [https://github.com/marvinm2/WikiPathwaysLoader](https://github.com/marvinm2/WikiPathwaysLoader)

To debug with OpenLink Virtuoso Interactive SQL, run in the image from the command line: 
```
docker exec -it wikipathways-virtuoso-httpd isql 1111 [account: dba] [password: pw for dba]

-- How many triples are in that graph?
SPARQL
  SELECT (COUNT(*) AS ?triples)
  WHERE { GRAPH <https://plantmetwiki.bioinformatics.nl/> { ?s ?p ?o } };
;
```

## 🧬 Notes for PlantMetWiki Development

- Default graph: `http://rdf.plantwiki.org/`
- Works with pathway RDF converted from GPML/WP
- SNORQL UI auto-configures via SNORQL_ENDPOINT env var
- The system uses a lightweight Apache reverse proxy to avoid CORS issues
- To access Conductor: http://localhost:8900/conductor/


 
## LICENSE 
Available at [LICENSE](LICENSE)