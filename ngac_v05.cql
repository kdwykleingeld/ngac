=====================================================================================================================================
// Create Indexes and Constraints
// User;UserAttribute;ObjectAttribute;PolicyClass;Object
CALL apoc.schema.assert({},{
 User:['name'],
 UserAttribute:['name'],
 ObjectAttribute:['name'],
 PolicyClass:['name'],
 Object:['name']
});
=====================================================================================================================================
// Create Nodes
// Name;Labels;Data Source;Status;Protected Resource;Empoyee Number;Screening Level;Email Address;Phone Number;latitude;longitude;height
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///ngac_nodes_v05.csv' AS line FIELDTERMINATOR ';'
//
MERGE (n { name: line.`Name`, labels: line.`Labels`})
with n,line
//
MATCH (n)
call apoc.create.addLabels([ id(n) ], [ n.labels ]) yield node
set n.uuid = apoc.create.uuid()
set n.created = apoc.date.currentTimestamp()
set n.datasource = line.`Data Source`
set n.status = line.`Status`
set n.resource = line.`Protected Resource`
set n.empno = line.`Employee Number`
set n.screening = line.`Screening Level`
set n.email = line.`Email Address`
set n.phone = line.`Phone Number`
set n.latitude = line.`Latitide`
set n.longitude = line.`Longitude`
set n.height = line.`Height`
with node
remove node.labels
=====================================================================================================================================
// Create Relationships
// From Node;Relationship Type;To Node;Permission;Data Source;Status;Weight
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM 'file:///ngac_rels_v05.csv' AS line FIELDTERMINATOR ';'
//
MATCH (n1 {name: line.`From Node`})
MATCH (n2 {name: line.`To Node`})
WITH line, n1,n2
//
CALL apoc.create.relationship(n1, line.`Relationship Type`, {}, n2) YIELD rel
WITH line, rel
SET rel.permission = line.`Permission`
SET rel.datasource = line.`Data Source`
SET rel.uuid = apoc.create.uuid()
SET rel.created = apoc.date.currentTimestamp()
SET rel.status = line.`Status`
SET rel.weight = line.`Weight`
=====================================================================================================================================
// Set degree, indegree, outdegree properties on all nodes
MATCH (n)
WITH n,length((n)-->()) AS outdegrees, length((n)<--()) AS indegrees
SET n.indegree = indegrees, n.outdegree = outdegrees, n.degree = indegrees+outdegrees
set n.modified = apoc.date.currentTimestamp()
=====================================================================================================================================
// Set pagerank property on all nodes
CALL algo.pageRank(null,null, {iterations:20, dampingFactor:0.85,
write: true,writeProperty:'pagerank', concurrency:4})
YIELD nodes, iterations, loadMillis, computeMillis, writeMillis, dampingFactor, write, writeProperty
MATCH (n)
SET n.modified = apoc.date.currentTimestamp()
=====================================================================================================================================
// Set betweenness property on all nodes
CALL algo.betweenness(null, null, {direction:'out',write:true, writeProperty:'betweenness'})
YIELD nodes, minCentrality, maxCentrality, sumCentrality, loadMillis, computeMillis, writeMillis
MATCH (n)
SET n.modified = apoc.date.currentTimestamp()
=====================================================================================================================================
// Set closeness property on all nodes
CALL algo.closeness(null, null , {write:true, writeProperty:'closeness'})
YIELD nodes,loadMillis, computeMillis, writeMillis
MATCH (n)
SET n.modified = apoc.date.currentTimestamp()
=====================================================================================================================================
// Set component property on all nodes
CALL algo.unionFind(null, null, {write:true, partitionProperty:"component"})
YIELD nodes, setCount, loadMillis, computeMillis, writeMillis
MATCH (n)
SET n.modified = apoc.date.currentTimestamp()
=====================================================================================================================================
// Set connected property on all nodes
CALL algo.scc(null, null, {write:true,partitionProperty:'connected'})
YIELD loadMillis, computeMillis, writeMillis, setCount, maxSetSize, minSetSize
MATCH (n)
SET n.modified = apoc.date.currentTimestamp()
=====================================================================================================================================
// Create Label Propagation Report
CALL algo.labelPropagation()
YIELD nodes, iterations, didConverge, loadMillis, computeMillis, writeMillis, write, weightProperty, partitionProperty
//
MATCH (n)
WITH n
ORDER BY n.pagerank DESC
//
WITH n.partition AS partition, count(*) AS clusterSize, COLLECT(n.name) AS pages
RETURN pages[0] AS mainPage, pages[1..999] AS otherPages, partition, clusterSize
ORDER BY clusterSize DESC
=====================================================================================================================================
// Create Node Report
MATCH (n)
RETURN labels(n) AS Labels, n.name AS Name, n.datasource AS DataSource, round(100 * n.pagerank) / 100 AS PageRank,
n.degree AS Degree, n.indegree as InDegree, n.outdegree AS OutDegree,
round(100 * n.closeness) / 100 AS Closeness, round(100 * n.betweenness) / 100 AS Betweenness,
n.component AS Component, n.connected AS Connected
ORDER BY PageRank DESC, Labels, Name, Degree
=====================================================================================================================================
// Create Database Statistics Report
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
=====================================================================================================================================
// Query NGAC Permissions WITH Prohibitions 
MATCH (u:User)-[:ASSIGNED_TO*]->(ua:UserAttribute)-[r:ASSOCIATED_TO]->(oa:ObjectAttribute)
MATCH (oa)<-[:ASSIGNED_TO*]-(o:Object)
MATCH (o)-[:ASSIGNED_TO*]->(opc:PolicyClass)
MATCH (oa)-[:ASSIGNED_TO*]->(oapc:PolicyClass)
OPTIONAL MATCH (u)-[:ASSIGNED_TO*]->(:UserAttribute)-[p1:PROHIBITION_ON]->(:ObjectAttribute)<-[:ASSIGNED_TO*]-(o)
OPTIONAL MATCH (u)-[p2:PROHIBITION_ON]->(:ObjectAttribute)<-[:ASSIGNED_TO*]-(o)
OPTIONAL MATCH (u)-[p3:PROHIBITION_ON]->(o)
OPTIONAL MATCH (u)-[:ASSIGNED_TO*]->(:UserAttribute)-[p4:PROHIBITION_ON]->(o)
//
WITH 	
    u.name AS Users,
	o.name AS Objects,
    COLLECT(DISTINCT SPLIT(apoc.text.join([p1.permission,p2.permission,p3.permission,p4.permission],","), ',')) AS Prohibitions,
	COLLECT(DISTINCT SPLIT(r.permission, ',')) AS Permissions,
	COLLECT(DISTINCT oa.name) AS ObjectAttributes,
	COLLECT(DISTINCT opc.name) AS ObjectPolicyClasses,
	COLLECT(DISTINCT oapc.name) AS ObjectAttributePolicyClasses
    WHERE ObjectPolicyClasses = ObjectAttributePolicyClasses AND ([item in Permissions WHERE NOT item in Prohibitions] OR Prohibitions IS NULL)
//
WITH
    Users,
    Objects,
    reduce(result=HEAD(Permissions),  s in TAIL(Permissions) | result+s) as CombinedPermissions,
	reduce(result1=HEAD(Prohibitions),  s in TAIL(Prohibitions) | result1+s) as CombinedProhibitions
//
RETURN Users,
    apoc.coll.toSet(CombinedPermissions) AS Permission,
    Objects, apoc.coll.toSet(CombinedProhibitions) AS Prohibition,
    CASE WHEN CombinedProhibitions IS NULL
        THEN apoc.coll.toSet(CombinedPermissions)
        ELSE [item in apoc.coll.toSet(CombinedPermissions) WHERE NOT item IN apoc.coll.toSet(CombinedProhibitions)] END AS ResultingPermission       
    ORDER BY Users, Objects
=====================================================================================================================================
// Stream data to Gephi
// In gephi add a stream on http://Server:7474 and start Server
MATCH path = (n)--(m)
WITH path
WITH COLLECT(path) AS paths	
CALL apoc.gephi.add(null,'workspace1', paths) YIELD nodes, relationships	
RETURN nodes, relationships
=====================================================================================================================================
// All path o4 - pc2
MATCH path = (o:Object)-[:ASSIGNED_TO*]->(pc:PolicyClass) WHERE o.name = "o4" AND pc.name = "pc2" RETURN path
=====================================================================================================================================
//ShortestPath o4 - pc2
MATCH p = ShortestPath((o:Object)-[:ASSIGNED_TO*]->(pc:PolicyClass)) WHERE o.name = "o4" AND pc.name = "pc2"
RETURN p
=====================================================================================================================================
// Dijkstra Weighted ShortestPath o4 - pc2
MATCH (o:Object),(pc:PolicyClass) WHERE o.name = "o4" AND pc.name = "pc2"
CALL apoc.algo.dijkstra(o, pc, 'ASSIGNED_TO' , 'weight') YIELD path, weight
RETURN path, weight
=====================================================================================================================================
// Delete All nodes and relationships
MATCH (n) DETACH DELETE n
=====================================================================================================================================
// Show All nodes and relationships
PATCH path = (n)--(m) RETURN path
=====================================================================================================================================
// Query User - ObjectAtttribute Path 
MATCH path=(u:User)-[:ASSIGNED_TO*]->(ua:UserAttribute)-[r:ASSOCIATED_TO*]->(oa:ObjectAttribute)
WITH path, COLLECT(r) AS Permissions
RETURN path, Permissions
=====================================================================================================================================
// Show rule 1
MATCH path=(n)-[r]->(m) WHERE r.rule = "1" RETURN path
=====================================================================================================================================
// Event Pattrn Grammar
MATCH (n:EventGrammar)
RETURN n.name AS Name,n.lr AS LR,n.assignment AS Assignment,n.rr AS RR ORDER BY n.name ASC
=====================================================================================================================================

