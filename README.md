# NGAC - Next Generation Access Control
ABAC - Attribute Based Access Control
IAM - Identity & Access Management

This is the readme file for a small prototype for a Policy Information Point (PIP) for Next Generation Access Control (NGAC) based on standards produced by INCITS with Neo4j as Propert Graph NOSQL DBMS an the Cypher Query Language to load data and perform some analytics and authorization querties.

Based on Neo4j 3.3.4.

Requires the APOC and Graph Alogroritms Libraries.

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

- xx.xql file contains Cypher Commands to:
1. Create Indices
2. Load Nodes
3. Load Relationships
4. Query Permissions
5. Produce Node Analytics Report
6. Degree
7. Closeness
8. Betweenness

- ngac_nodes.csv file contains nodes to be imported
- ngac_relationships file containes relationships to be imported

Both files must be placed in the Neo4j import directory

Labels: IAM Identity Access Management ABAC NGAC Attribute Based Access Control Neo4j Cypher Authorization PDP PAP PIP EPP
