// data profiling and validation
match (n) return distinct labels(n), count(*);
match (n)-[r]->() return distinct type(r), count(*);
match p= (sc:SupplyChain)<-[:HAS_CHAIN]-(c:Company)-[HAS_SIC]->(s:SIC) 
return p limit 25;
match (sc:SupplyChain {id:1})-[*..3]-(conn) return sc, conn limit 10;

// Some SCM queries
//depth of SC Network by traversing graph
match path = ((sc:SupplyChain)-[:STARTS_WITH|PRECEDES*]->(s:Stage))
where not ((s)-[:PRECEDES]->())
return  distinct sc.id, (max(length(path))-1) as maxlength
order by maxlength desc;

//depth of SC network by reading stage properties
match (sc:SupplyChain)-->(s:Stage)
return distinct sc.id, max(s.relDepth) as maxlengthprop
order by maxlengthprop desc;

//how many start and end nodes
match (s1:Stage)<-[start:STARTS_WITH]-(sc:SupplyChain)
with sc, count(start) as starts
match (sc)<-[end:ENDS]-(s2)
return sc.id, starts, count(end);

//verify the number of endstages for a SupplyChain by counting the paths
match path = (:SupplyChain {id:12})-[:STARTS_WITH]->(startstage:Stage)-[:PRECEDES*]->(endstage:Stage)
where not ((endstage)-[:PRECEDES]->())
with distinct endstage
return count(endstage);

//Zooming in on chain nr 20 - different path lengths
match path = (:SupplyChain {id:20})-[:STARTS_WITH]->(startstage:Stage)-[:PRECEDES*]->(endstage:Stage)
where not ((endstage)-[:PRECEDES]->())
return distinct count(path), length(path);

//Visualizing the different path lengths for chain nr 20
match path = (:SupplyChain {id:20})-[:STARTS_WITH]->(startstage:Stage)-[:PRECEDES*]->(endstage:Stage)
where not ((endstage)-[:PRECEDES]->())
return path;

//Visualizing the paths with length = 8
//profile: Cypher version: CYPHER 3.5, planner: COST, runtime: SLOTTED. 4200 total db hits in 39 ms.

match path = (:SupplyChain {id:20})-[:STARTS_WITH]->(startstage:Stage)-[:PRECEDES*]->(endstage:Stage)
where not ((endstage)-[:PRECEDES]->()) and length(path) = 8
return path;

//Visualizing the paths with length = 8 with ENDS check
//profile: Cypher version: CYPHER 3.5, planner: COST, runtime: SLOTTED. 2138 total db hits in 11 ms.
match path = (sc:SupplyChain {id:20})-[:STARTS_WITH]->(startstage:Stage)-[:PRECEDES*]->(endstage:Stage)-[:ENDS]-(sc)
where length(path) = 9
return path;
