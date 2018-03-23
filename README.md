# NGAC - Next Generation Access Control - Policy Information Point (PIP)

This is the readme file for a small prototype for a Policy Information Point (PIP) for Next Generation Access Control (NGAC). NGAC is a Attribute Based Access Control (ABAC) standard described by INCITS (499 - Functional Architecture).

This prototype is based on Neo4j to implement the directed Property Graph and the Cypher Query Language to load data and perform some analytics and authorization permission queries.

NGAC is based on Attribute Based Access Control (ABAC) Principles and part of the Identity & Access Management (IAM) Security Domain implementing support for Fine-Grained Authorization Services.

This prototype is based on Neo4j 3.3.4 and makes use of Neo4j APOC and Graph Alogroritms plugin Libraries.

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
6) run the cyppher code snippits from the ngac.cql file   (one part at the time) through the browser to create indices, import data, set analytical properties and run some permission queries

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
    
Load Nodes:

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

