all: graph.db

clean:
	rm -fr graph.db graph.json csv/edges.csv csv/nodes.csv

graph.json:
	@echo "# download graph"
	wget -q http://patriaindipendente.it/progetto-facebook/data.json.zip
	unzip data.json.zip
	jq . < data.json > graph.json
	rm data.json*

nodes.csv: graph.json
	@echo "# extract nodes.csv"
	jq .nodes graph.json | in2csv -f json > csv/nodes.csv
	gsed -i '1 s/id/Node:ID/' csv/nodes.csv 

edges.csv: graph.json
	@echo "# extract edges.csv"
	jq .edges graph.json | in2csv -f json | csvcut -c 1,3 | awk '{print $$1",LIKE"}' > csv/edges.csv
	gsed -i 1d csv/edges.csv
	gsed -i '1i:END_ID,:START_ID,:TYPE' csv/edges.csv

graph.db: nodes.csv edges.csv
	# neo4j-admin import --database=facebook.db --nodes:Node=nodes.csv  --relationships:LIKE=edges.csv
	neo4j-import --into graph.db --nodes:Node csv/nodes.csv  --relationships:LIKE csv/edges.csv
	# docker run --rm -it -v $(pwd)/data:/data neo4j -v $(pwd)/csv:/csv "bin/neo4j-import --into /data/databases/graph.db --nodes:Node /csv/nodes.csv  --relationships:LIKE /csv/edges.csv"