=ngac.cql========================================================================================================================
* Neo4j 3.3.4 is installed and running (through desktop or community)
* test database created
* apoc- and graph algorithms plugins are installed
* import files in root of import directory
* run Cypher Code 1 .. 10 in Browser to create Nodes and Relationships and set analytical properties
* run Cypher code 11 to create analytical report
* run Cypher code 12 to queyr for all permissions . This is a simulation of what the PDP with ask the PIP
=1====================================================================================================================================
// Define Indexes and Constraints
// User;UserAttribute;ObjectAttribute;PolicyClass;Object
CALL apoc.schema.assert({},{
 User:['name'],
 UserAttribute:['name'],
 ObjectAttribute:['name'],
 PolicyClass:['name'],
 Object:['name']
});
=2====================================================================================================================================
// Create Nodes
// Name;Labels;Data Source;Status
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///ngac_nodes.csv' AS line FIELDTERMINATOR ';'
//
MERGE (n { name: line.`Name`, labels: line.`Labels`, datasource: line.`Data Source`, status: line.`Status`})
with n,line
//
MATCH (n)
call apoc.create.addLabels([ id(n) ], [ n.labels ]) yield node
set n.uuid = apoc.create.uuid()
set n.created = apoc.date.currentTimestamp()
with node
remove node.labels
=3====================================================================================================================================
// Create Relationships
// From Node;Relationship Type;To Node;Permission;Data Source;Status;Weight
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///ngac_rels.csv' AS line FIELDTERMINATOR ';'
MATCH (n1 {name: line.`From Node`})
MATCH (n2 {name: line.`To Node`})
WITH line, n1,n2
//
CALL apoc.create.relationship(n1, line.`Relationship Type`, {}, n2) YIELD rel
WITH line, rel
SET rel.permission = line.`Permission`
SET rel.datasource = line.`Data Source`
set rel.uuid = apoc.create.uuid()
set rel.created = apoc.date.currentTimestamp()
set rel.status = line.`Status`
set rel.weight = line.`Weight`
=4====================================================================================================================================
// Set degree, indegree, outdegree properties on all nodes
MATCH (n)
WITH n,length((n)-->()) AS outdegrees, length((n)<--()) AS indegrees
SET n.indegree = indegrees, n.outdegree = outdegrees, n.degree = indegrees+outdegrees
set n.modified = apoc.date.currentTimestamp()
=5====================================================================================================================================
// Set pagerank property on all nodes
CALL algo.pageRank(null,null, {iterations:20, dampingFactor:0.85,
write: true,writeProperty:'pagerank', concurrency:4})
YIELD nodes, iterations, loadMillis, computeMillis, writeMillis, dampingFactor, write, writeProperty
MATCH (n)
SET n.modified = apoc.date.currentTimestamp()
=6====================================================================================================================================
// Set betweenness property on all nodes
CALL algo.betweenness(null, null, {direction:'out',write:true, writeProperty:'betweenness'})
YIELD nodes, minCentrality, maxCentrality, sumCentrality, loadMillis, computeMillis, writeMillis
MATCH (n)
SET n.modified = apoc.date.currentTimestamp()
=7====================================================================================================================================
// Set closeness property on all nodes
CALL algo.closeness(null, null , {write:true, writeProperty:'closeness'})
YIELD nodes,loadMillis, computeMillis, writeMillis
MATCH (n)
SET n.modified = apoc.date.currentTimestamp()
=8====================================================================================================================================
// Set component property on all nodes
CALL algo.unionFind(null, null, {write:true, partitionProperty:"component"})
YIELD nodes, setCount, loadMillis, computeMillis, writeMillis
MATCH (n)
SET n.modified = apoc.date.currentTimestamp()
=9====================================================================================================================================
// Set connected property on all nodes
CALL algo.scc(null, null, {write:true,partitionProperty:'connected'})
YIELD loadMillis, computeMillis, writeMillis, setCount, maxSetSize, minSetSize
MATCH (n)
SET n.modified = apoc.date.currentTimestamp()
=10===================================================================================================================================
// Label Propagation Report
CALL algo.labelPropagation()
YIELD nodes, iterations, didConverge, loadMillis, computeMillis, writeMillis, write, weightProperty, partitionProperty
//
match (n)
WITH n
ORDER BY n.pagerank DESC
//
WITH n.partition AS partition, count(*) AS clusterSize, COLLECT(n.name) AS pages
RETURN pages[0] AS mainPage, pages[1..999] AS otherPages, partition, clusterSize
ORDER BY clusterSize DESC
=11===================================================================================================================================
// Create Node Report
MATCH (n)
return labels(n) as Labels, n.name as Name, n.datasource as DataSource, n.pagerank as PageRank,
n.degree AS Degree, n.indegree as InDegree, n.outdegree as OutDegree,
n.closeness as CloseNess, n.betweenness as BetweenNess,
n.component as Component, n.connected as Connected
ORDER BY Labels, Name, Degree
=12===================================================================================================================================
// Query Permissions WITH Prohibitions 
MATCH (u:User)-[:ASSIGNED_TO*]->(ua:UserAttribute)-[r:ASSOCIATED_TO]->(oa:ObjectAttribute)
MATCH (oa)<-[:ASSIGNED_TO*]-(o:Object)
MATCH (o)-[:ASSIGNED_TO*]->(opc:PolicyClass)
MATCH (oa)-[:ASSIGNED_TO*]->(oapc:PolicyClass)
OPTIONAL MATCH (u)-[p:PROHIBITION_ON]->(o)
WITH
	u.name AS Users,
	o.name AS Objects,
    SPLIT(p.permission, ',') AS Prohibitions,
	SPLIT(r.permission, ',') AS Permissions,
	COLLECT(DISTINCT oa.name) AS ObjectAttributes,
	COLLECT(DISTINCT opc.name) AS ObjectPolicyClasses,
	COLLECT(DISTINCT oapc.name) AS ObjectAttributePolicyClasses
    WHERE ObjectPolicyClasses = ObjectAttributePolicyClasses AND ([item in Permissions WHERE NOT item in Prohibitions] OR Prohibitions IS NULL)
RETURN Users, Permissions, Objects, Prohibitions, [item in Permissions WHERE NOT item in Prohibitions] as SubSet,
    CASE WHEN Prohibitions IS NULL THEN Permissions 
         ELSE [item in Permissions WHERE NOT item in Prohibitions] END as ResultingPermission       
ORDER BY Users, Objects
=13===================================================================================================================================
// Stream data to Gephi
// In gephi add a stream on http://Server:7474 and start Server
MATCH path = (n)--(m)
WITH path
WITH collect(path) AS paths	
CALL apoc.gephi.add(null,'workspace1', paths) yield nodes, relationships	
RETURN nodes, relationships
=14===================================================================================================================================
// All path o4 - pc2
match path = (o:Object)-[:ASSIGNED_TO*]->(pc:PolicyClass) WHERE o.name = "o4" AND pc.name = "pc2" RETURN path
=15===================================================================================================================================
//ShortestPath o4 - pc2
match p = ShortestPath((o:Object)-[:ASSIGNED_TO*]->(pc:PolicyClass)) WHERE o.name = "o4" AND pc.name = "pc2"
RETURN p
=16===================================================================================================================================
// Dijkstra Weighted ShortestPath o4 - pc2
match (o:Object),(pc:PolicyClass) WHERE o.name = "o4" AND pc.name = "pc2"
CALL apoc.algo.dijkstra(o, pc, 'ASSIGNED_TO' , 'weight') YIELD path, weight
RETURN path, weight
=17===================================================================================================================================
// Delete All nodes and relationships
match (n) detach delete n
=18===================================================================================================================================
// Show All nodes and relationships
match path = (n)--(m) Return path
=19===================================================================================================================================
// Report Database Statistics
call dbms.queryJmx("org.neo4j:instance=kernel#0,name=Store file sizes") yield attributes
       with  keys(attributes) as k , attributes
       unwind k as row
       return "StoreSizes" as type,row,attributes[row]["value"]

union all

call dbms.queryJmx("org.neo4j:instance=kernel#0,name=Page cache") yield attributes
       with  keys(attributes) as k , attributes
       unwind k as row
       return "PageCache" as type,row,attributes[row]["value"]

union all

call dbms.queryJmx("org.neo4j:instance=kernel#0,name=Primitive count") yield attributes
       with  keys(attributes) as k , attributes
       unwind k as row
       return "ID Allocations" as type,row,attributes[row]["value"]

union all

call dbms.queryJmx("org.neo4j:instance=kernel#0,name=Transactions") yield attributes
       with  keys(attributes) as k , attributes
       unwind k as row
       return "Transactions" as type,row,attributes[row]["value"]

union all

call dbms.queryJmx("org.neo4j:instance=kernel#0,name=High Availability") yield attributes
       with  keys(attributes) as k , attributes
       unwind k as row
       return "High Availability" as type,row,attributes[row]["value"]

union all

call dbms.queryJmx("org.neo4j:instance=kernel#0,name=Causal Clustering") yield attributes
       with  keys(attributes) as k , attributes
       unwind k as row
       return "Causal Cluster" as type,row,attributes[row]["value"];