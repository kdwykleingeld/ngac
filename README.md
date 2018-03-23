# NGAC - Next Generation Access Control - Policy Information Point (PIP)

This is the readme file for a small prototype for a Policy Information Point (PIP) for Next Generation Access Control (NGAC). NGAC is a Attribute Based Access Control (ABAC) standard described by INCITS (499 - Functional Architecture).

This prototype is based on Neo4j to implement the directed Property Graph and the Cypher Query Language to load data and perform some analytics and authorization permission queries.

NGAC is based on Attribute Based Access Control (ABAC) Principles and part of the Identity & Access Management (IAM) Security Domain implementing support for Fine-Grained Authorization Services.

This prototype is based on Neo4j 3.3.4 and makes use of Neo4j APOC and Graph Alogroritms plugin Libraries. Data can be streamed to Gephi for visualization purpose.

Implemented node types and properties:
- User
- UserAttribute
- Object
- ObjectAttribute
- PolicyClass

Implemented relationship types:
- ASSIGNED_TO
- ASSOCIATED_TO
- PROHIBITION_ON

Files:

- ngac.xcl file:  contains Cypher Commands to create indices, nodes , relationships, analytical data and authorization quieries
- ngac_nodes.csv: contains nodes to be imported
- ngac_rels:      containes relationships to be imported
- datamodel.jpg:  the datamodel
- testdata.jpg:   visual overview of the data

Installation:
1) install neo4j 3.3.4
2) create database
3) install apoc and graph algorithms plugins
4) place ngac_nodes.csv and ngac_rels.csv in the Neo4j import directory
5) start neo4j and open browser
6) run the cypher code snippits from the ngac.cql file   (one part at the time) through the browser to create indices, import data, set analytical properties and run some permission queries

Create Indices:

    // Define Indexes and Constraints
    // User;UserAttribute;ObjectAttribute;PolicyClass;Object
    CALL apoc.schema.assert({},{
     User:['name'],
     UserAttribute:['name'],
     ObjectAttribute:['name'],
     PolicyClass:['name'],
     Object:['name']
    });
    
Import nodes:

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

Import relationships:

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
    SET rel.uuid = apoc.create.uuid()
    SET rel.created = apoc.date.currentTimestamp()
    SET rel.status = line.`Status`
    SET rel.weight = line.`Weight`
    
    // Set degree, indegree, outdegree properties on all nodes
    
Set Degree Property

    MATCH (n)
    WITH n,length((n)-->()) AS outdegrees, length((n)<--()) AS indegrees
    SET n.indegree = indegrees, n.outdegree = outdegrees, n.degree = indegrees+outdegrees
    SET n.modified = apoc.date.currentTimestamp()

Set PageRank property

    // Set pagerank property on all nodes
    CALL algo.pageRank(null,null, {iterations:20, dampingFactor:0.85,
    write: true,writeProperty:'pagerank', concurrency:4})
    YIELD nodes, iterations, loadMillis, computeMillis, writeMillis, dampingFactor, write, writeProperty
    MATCH (n)
    SET n.modified = apoc.date.currentTimestamp()

Set Betweenness property

    // Set betweenness property on all nodes
    CALL algo.betweenness(null, null, {direction:'out',write:true, writeProperty:'betweenness'})
    YIELD nodes, minCentrality, maxCentrality, sumCentrality, loadMillis, computeMillis, writeMillis
    MATCH (n)
    SET n.modified = apoc.date.currentTimestamp()

Set Closeness property

    // Set closeness property on all nodes
    CALL algo.closeness(null, null , {write:true, writeProperty:'closeness'})
    YIELD nodes,loadMillis, computeMillis, writeMillis
    MATCH (n)
    SET n.modified = apoc.date.currentTimestamp()

Set Component property

    // Set component property on all nodes
    CALL algo.unionFind(null, null, {write:true, partitionProperty:"component"})
    YIELD nodes, setCount, loadMillis, computeMillis, writeMillis
    MATCH (n)
    SET n.modified = apoc.date.currentTimestamp()

Set Connected property

    // Set connected property on all nodes
    CALL algo.scc(null, null, {write:true,partitionProperty:'connected'})
    YIELD loadMillis, computeMillis, writeMillis, setCount, maxSetSize, minSetSize
    MATCH (n)
    SET n.modified = apoc.date.currentTimestamp()

Label Propagation report

    // Label Propagation Report
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

Node Analytics report

    // Create Node Report
    MATCH (n)
    RETURN labels(n) as Labels, n.name as Name, n.datasource as DataSource, n.pagerank as PageRank,
    n.degree AS Degree, n.indegree as InDegree, n.outdegree as OutDegree,
    n.closeness as CloseNess, n.betweenness as BetweenNess,
    n.component as Component, n.connected as Connected
    ORDER BY Labels, Name, Degree

Query Permissions for all users

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

Stream data to Gephi

    // Stream data to Gephi
    // In gephi add a stream on http://Server:7474 and start Server
    MATCH path = (n)--(m)
    WITH path
    WITH collect(path) AS paths	
    CALL apoc.gephi.add(null,'workspace1', paths) yield nodes, relationships	
    RETURN nodes, relationships
    
    
