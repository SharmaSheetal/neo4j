//look at cost of paths
match (sc:SupplyChain {id:8})-[:STARTS_WITH]->(startstage:Stage)
with startstage,sc
match path = (startstage)-[:PRECEDES*]->(endstage:Stage)
where (endstage)-[:ENDS]->(sc)
with path, reduce(sum=0, x in nodes(path) | sum+x.stageTime) as totalTime,
reduce(sum=0, y in nodes(path) | sum+y.stageCost) as totalCost
return totalTime, totalCost, [x in nodes(path) | id(x)]
order by totalTime asc
limit 10;


//Calculate the betweenness scores
:param label => ("Stage");
:param relationshipType => ("PRECEDES");
:param limit => (100);
:param config => ({concurrency: 8, direction: "Outgoing", writeProperty: "betweenness"});

CALL algo.betweenness($label, $relationshipType, $config);

MATCH (node:Stage)
WHERE not(node[$config.writeProperty] is null)
RETURN node, node[$config.writeProperty] AS score
ORDER BY score DESC
LIMIT $limit;


//take a look at the nodes with the highest betweenness
MATCH (s:Stage)
WITH s
ORDER BY s.betweenness DESC
LIMIT 1
SET s:BETWEENNESSCHAMP
WITH s
MATCH path = ((sc:SupplyChain)-[:STARTS_WITH|PRECEDES|ENDS*]->(s))
where s in nodes(path)
with sc,s
limit 1
match path = (sc)-[:STARTS_WITH]->(startstage:Stage)-[:PRECEDES*]->(endstage:Stage)-[:ENDS]->(sc)
return path, s
limit 100;

//take a look at the nodes with the highest betweenness in a particular supply chain
MATCH path = ((sc:SupplyChain {id:19})-[:STARTS_WITH|PRECEDES*]->(s))
where s in nodes(path)
with sc,s
match (s)
with s,sc
order by s.betweenness DESC
limit 1
set s:BETWEENNESSCHAMP
with s, sc
match path = (sc)-[:STARTS_WITH]->(startstage:Stage)-[:PRECEDES*]->(endstage:Stage)-[:ENDS]->(sc)
return path, s
limit 100

//take a look at the degree of the nodes with the highest betweenness
MATCH path = ((sc:SupplyChain {id:19})-[:STARTS_WITH|PRECEDES|ENDS*]->(s))
where s in nodes(path)
with sc,s
match (s)
return distinct s.name, apoc.node.degree(s) as degree, s.betweenness as betweenness
order by betweenness DESC
limit 10

//take a look at the betweenness of the nodes ordered by degree
MATCH path = ((sc:SupplyChain {id:19})-[:STARTS_WITH|PRECEDES|ENDS*]->(s))
where s in nodes(path)
with sc,s
match (s)
return distinct s.name, apoc.node.degree(s) as degree, s.betweenness as betweenness
order by degree DESC
limit 10

