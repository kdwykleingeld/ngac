# ngac abac neo4j pep pdp pip iam authorization access control

Currently working on a prototype for an NGAC (Next Generation Access Control) based
ABAC (Attribute Based Access Control) Authorization Service Solution.

It will contain a Java based PDP (Policy Decision Point) component that is able to receive Authorization Requests
from a PEP (Policy Enforcement Point) in the XACML XML or JSON data format.

Policy- and attribute data for the Authorization Service will be stored as Nodes and Directed Relationship with properties
in a Neo4j based Property Graph DBMS.

Data will include nodes with Label types User, UserAttribute,  Process, Object, ObjectAttribute and PolicyClass and several
node label types for representing attribute and meta data.
Relationships will include ASSIGNED_TO and ASSOCIATED_{permission} TYPE relationships and several generic meta data rels.

Storing NGAC policy and attribute data in a Graph DBMS is the basis for a highly performant and efficient
real-time authorization processing engine. Resolving authorization decisions is simply a matter of path traversal in the graph.
