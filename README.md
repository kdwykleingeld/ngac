# NGAC - Next Generation Access Control - Policy Information Point

This is the readme file for a small prototype for a Policy Information Point (PIP) for Next Generation Access Control (NGAC) based on standards produced by INCITS with Neo4j as Propert Graph NOSQL DBMS an the Cypher Query Language to load data and perform some analytics and authorization querties.

NGAC is based on Attribute Based Access Control (ABAC) Principles and part of the Identity & Access Management (IAM) Security Domain implementing support for Fine-Grained Authorization Services.

This prootype is based on Neo4j 3.3.4 and makes use of Neo4j APOC and Graph Alogroritms plugin Libraries.

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

Both ngac_nodes.csv and ngac_rels.csv must be placed in the Neo4j import directory.
