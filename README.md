# ngac - Next Generation Access Control
This is the Readme file for a prototype for a NGAC (Next Generation Access Control) limited scale prototype based on neo4j.

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
-- bla
-- bla
- ASSOCIATED_TO
- PROHIBITION_ON

The xx.xql file contains Cypher Commands to:

1. Create Indices
2. Load Nodes
3. Load Relationships
4. Query Permissions
5. Produce Node Analytics Report
6. Degree
7. Closeness
8. Betweenness

The ngac_nodes.csv file contains nodes to be imported
The ngac_relationships file containes relationships to be imported

Both files must be placed in the Neo4j import directory
