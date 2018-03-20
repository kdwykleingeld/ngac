=ngac_v03.cql========================================================================================================================
* Neo4j Desktop 3.3.0 is installed
* database created
* apoc- and graph algorithms plugins are installed
* import files in import directory
======================================================================================================================================
// Define Indexes and Constraints
CALL apoc.schema.assert({},{
 User:['name'],
 UserAttribute:['name'],
 ObjectAttribute:['name'],
 PolicyClass:['name'],
 Object:['name']
});
======================================================================================================================================
// Nodes - Name;Labels;Data Source;Status
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
======================================================================================================================================
// Relationships - From Node;Relationship Type;To Node;Permission;Data Source;Status;Weight
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
======================================================================================================================================
// Set degree, indegree, outdegree properties on all nodes
MATCH (n)
WITH n,length((n)-->()) AS outdegrees, length((n)<--()) AS indegrees
SET n.indegree = indegrees, n.outdegree = outdegrees, n.degree = indegrees+outdegrees
set n.modified = apoc.date.currentTimestamp()
======================================================================================================================================
// Set pagerank property on all nodes
CALL algo.pageRank(null,null, {iterations:20, dampingFactor:0.85,
write: true,writeProperty:'pagerank', concurrency:4})
YIELD nodes, iterations, loadMillis, computeMillis, writeMillis, dampingFactor, write, writeProperty
MATCH (n)
SET n.modified = apoc.date.currentTimestamp()
======================================================================================================================================
// Set betweenness property on all nodes
CALL algo.betweenness(null, null, {direction:'out',write:true, writeProperty:'betweenness'})
YIELD nodes, minCentrality, maxCentrality, sumCentrality, loadMillis, computeMillis, writeMillis
MATCH (n)
SET n.modified = apoc.date.currentTimestamp()
======================================================================================================================================
// Set closeness property on all nodes
CALL algo.closeness(null, null , {write:true, writeProperty:'closeness'})
YIELD nodes,loadMillis, computeMillis, writeMillis
MATCH (n)
SET n.modified = apoc.date.currentTimestamp()
======================================================================================================================================
// Set component property on all nodes
CALL algo.unionFind(null, null, {write:true, partitionProperty:"component"})
YIELD nodes, setCount, loadMillis, computeMillis, writeMillis
MATCH (n)
SET n.modified = apoc.date.currentTimestamp()
======================================================================================================================================
// Set connected property on all nodes
CALL algo.scc(null, null, {write:true,partitionProperty:'connected'})
YIELD loadMillis, computeMillis, writeMillis, setCount, maxSetSize, minSetSize
MATCH (n)
SET n.modified = apoc.date.currentTimestamp()
======================================================================================================================================
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
======================================================================================================================================
// List all Procedures
CALL dbms.procedures()
======================================================================================================================================
// List all Functions
CALL dbms.functions()
======================================================================================================================================
// Create Node Report
MATCH (n)
return labels(n) as Labels, n.name as Name, n.datasource as DataSource, n.pagerank as PageRank,
n.degree AS Degree, n.indegree as InDegree, n.outdegree as OutDegree,
n.closeness as CloseNess, n.betweenness as BetweenNess,
n.component as Component, n.connected as Connected
ORDER BY Labels, Name, Degree
======================================================================================================================================
// Delete All nodes and relationships
match (n) detach delete n
======================================================================================================================================
// Show All nodes and relationships
match path = (n)--(m) Return path
======================================================================================================================================
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
======================================================================================================================================
// Stream data to Gephi
// In gephi add a stream on http://Server:7474 and start Server
MATCH path = (n)--(m)
WITH path
WITH collect(path) AS paths	
CALL apoc.gephi.add(null,'workspace1', paths) yield nodes, relationships	
RETURN nodes, relationships
======================================================================================================================================
// Set Permisison on Object Attributes
MATCH (ua:Attribute)-[r:ASSOCIATED_TO]->(oa:Attribute)
SET oa.permission = r.permission
======================================================================================================================================
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
======================================================================================================================================
// All path o4 - pc2
match path = (o:Object)-[:ASSIGNED_TO*]->(pc:PolicyClass) WHERE o.name = "o4" AND pc.name = "pc2" RETURN path
======================================================================================================================================
//ShortestPath o4 - pc2
match p = ShortestPath((o:Object)-[:ASSIGNED_TO*]->(pc:PolicyClass)) WHERE o.name = "o4" AND pc.name = "pc2"
RETURN p
======================================================================================================================================
// Dijkstra Weighted ShortestPath o4 - pc2
match (o:Object),(pc:PolicyClass) WHERE o.name = "o4" AND pc.name = "pc2"
CALL apoc.algo.dijkstra(o, pc, 'ASSIGNED_TO' , 'weight') YIELD path, weight
RETURN path, weight
======================================================================================================================================
// All Shortest PAth path o > pc
match path = allshortestpaths((o:Object)-[*]->(pc:PolicyClass)) Where o <> pc RETURN path
======================================================================================================================================	
WITH ['a','b','c'] AS set1,  ['b'] AS set2
RETURN set1, set2, apoc.coll.disjunction(set1, set2), [item in set1 WHERE NOT item in set2] as set3, apoc.coll.subtract(set1, set2) as set4
======================================================================================================================================
WITH [1, 1, 2, 2] AS coll
UNWIND coll AS x
WITH DISTINCT x
RETURN collect(x) AS SET
======================================================================================================================================
MATCH (n:Attribute {name: "a2"})
MATCH (m:Attribute {name: "a10"})
MERGE (n)-[:ASSIGNED_TO {permission: "r,w,e"}]->(m)
RETURN n
======================================================================================================================================

// Query User Permissions
MATCH (u:User)-[:ASSIGNED_TO*]->(ua:UserAttribute)-[:ASSOCIATED_TO]->(oa:ObjectAttribute)<-[:ASSIGNED_TO*]-(o:Object) WHERE u.name = "u1"
WITH u, COLLECT(oa) AS ObjectAttributes, COLLECT(o) AS Objects
MATCH (pc:PolicyClass) WHERE 
ANY( x IN ObjectAttributes WHERE (x)-[*]->(pc) ) AND ANY( y IN Objects WHERE (y)-[*]->(pc) )
WITH u, Collect(pc) AS PolicyClasses, Objects, ObjectAttributes
RETURN u, ObjectAttributes, PolicyClasses, Objects
======================================================================================================================================
START n=node:nodename("nodename:PE*")
MATCH p=n-[r:IS_MEMBER_OF*]->x WHERE x.nodetype="AGR"
WITH n,collect(DISTINCT x.nodename) as soll,count(p) as sollpaths,collect(distinct length(p)) as sollpathlen,REDUCE(i = 0,j IN r | i+j.Weight) as sollweight
MATCH p=n<-[*]-x WHERE  x.nodetype="AGR"
WITH sollweight,p,n,soll,collect(DISTINCT x.nodename) as ist,sollpaths,sollpathlen
RETURN sollweight,n.nodename,ist,soll,sollpaths,sollpathlen,length(ist)=length(soll) AND ALL(x IN soll where x IN ist)
order by n.nodename;
======================================================================================================================================
FOREACH(i IN RANGE(0, size(directorygroups)-1) |
MERGE (directorygroup:Group:DirectoryGroup { name: fullType[1]+'.'+directorygroups[i] })
SET directorygroup.GroupName = directorygroups[i]
MERGE (directory:Directory { name: fullType[1] })
MERGE (directoryaccount)-[r1:MEMBER_OF]->(directorygroup)
SET r1.accountCategory = line.`Account Category`
MERGE (owner:Owner { name: line.`Account Description` })
MERGE (owner)-[:OWNER_OF]->(directoryaccount)
MERGE (directorygroup)-[:ON_DIRECTORY]->(directory)
MERGE (directoryaccount)-[:ON_DIRECTORY]->(directory))
======================================================================================================================================
SPLIT(line.`Machine Name`,'.') AS hostname,
======================================================================================================================================
MATCH (owner:Owner)
//
WITH owner, SPLIT(owner.name,'/') AS parts
call apoc.do.case([
	size(parts) = 4, "SET owner.ad1 = parts[0], owner.ad2 = parts[1], owner.ad3 = parts[2], owner.ad4 = parts[3]",
	size(parts) = 5, "SET owner.ad1 = parts[0], owner.ad2 = parts[1], owner.ad3 = parts[2], owner.ad4 = parts[3], owner.ad5 = parts[4]",
	size(parts) = 6, "SET owner.ad1 = parts[0], owner.ad2 = parts[1], owner.ad3 = parts[2], owner.ad4 = parts[3], owner.ad5 = parts[4], owner.ad6 = parts[5]"],
	"SET owner.ad1 = parts[0]", {owner:owner,parts:parts})
	YIELD value RETURN owner