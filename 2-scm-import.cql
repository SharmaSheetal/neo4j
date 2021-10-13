//importing the dataset
create index on :SupplyChain(id);
create index on :Stage(name);
create index on :Stage(betweenness);
create index on :SIC(code);
create index on :Company(id);
create index on :StageClassification(name);

//load the companies
load csv with headers from "https://docs.google.com/spreadsheets/u/0/d/1vD4UCxsincEQYQpAeCbEqnd3QFdKcuL4ukesbyu5RIc/export?format=csv&id=1vD4UCxsincEQYQpAeCbEqnd3QFdKcuL4ukesbyu5RIc&gid=0" as csv
merge (sic:SIC {code: toInt(csv.SIC_Code), desc: csv.SIC_Description})
merge (c:Company {id: toInt(csv.companyId)})
merge (ch:SupplyChain {id: toInt(csv.chainId)})
merge (c)-[:HAS_SIC]->(sic)
create (c)-[:HAS_CHAIN]->(ch);

//load the rels between the chain stages
load csv with headers from
"https://docs.google.com/spreadsheets/u/0/d/1vD4UCxsincEQYQpAeCbEqnd3QFdKcuL4ukesbyu5RIc/export?format=csv&id=1vD4UCxsincEQYQpAeCbEqnd3QFdKcuL4ukesbyu5RIc&gid=1371172744" as csv
merge (ss:Stage {name: csv.sourceStage, chainId: toInt(csv.chainId)})
merge (ds:Stage {name: csv.destinationStage, chainId: toInt(csv.chainId)})
create (ss)-[:PRECEDES]->(ds);

//create the STARTS_WITH and ENDS rels between the SupplyChain and the first and last chain stage
//create STARTS_WITH
load csv with headers from
"https://docs.google.com/spreadsheets/u/0/d/1vD4UCxsincEQYQpAeCbEqnd3QFdKcuL4ukesbyu5RIc/export?format=csv&id=1vD4UCxsincEQYQpAeCbEqnd3QFdKcuL4ukesbyu5RIc&gid=1371172744" as csv
match (sc:SupplyChain {id: toInt(csv.chainId)}), (ss:Stage {name: csv.sourceStage, chainId: toInt(csv.chainId)})
where not (()-[:PRECEDES]->(ss))
AND sc.id = ss.chainId
merge (sc)-[:STARTS_WITH]->(ss);
//create ENDS
match path = (sc:SupplyChain)-[:STARTS_WITH]->(startstage:Stage)-[:PRECEDES*]->(endstage:Stage)
where not ((endstage)-[:PRECEDES]->())
merge (sc)<-[:ENDS]-(endstage);


//load the detail of each Stage
load csv with headers from
"https://docs.google.com/spreadsheets/u/0/d/1vD4UCxsincEQYQpAeCbEqnd3QFdKcuL4ukesbyu5RIc/export?format=csv&id=1vD4UCxsincEQYQpAeCbEqnd3QFdKcuL4ukesbyu5RIc&gid=579862779" as csv
match (s:Stage {chainId: toInt(csv.chainId), name: csv.Stage_Name})
set s.stageCost = toFloat(csv.stageCost)
set s.relDepth = toInteger(csv.relDepth)
set s.stageClassification = csv.stageClassification
set s.avgDemand = csv.avgDemand
set s.stdDevDemand = csv.stdDevDemand
set s.maxServiceTime	= csv.maxServiceTime
set s.serviceLevel = csv.serviceLevel
set s.stageTime = toFloat(csv.stageTime)
set s.stdDev_stageTime = csv.stdDev_stageTime;



//split out the stageClassifications
match (s:Stage)
merge (sc:StageClassification {name: s.stageClassification})
create (s)-[:IS_A]->(sc);

//merge the two "Parts" stageClassifications
match (sc1:StageClassification {name:"Parts"}), (sc2:StageClassification {name:"Part"})
WITH head(collect([sc1,sc2])) as nodes
CALL apoc.refactor.mergeNodes(nodes,{properties:"combine", mergeRels:true}) yield node
set node.name = "Parts"
return count(node);


//model in text
match (n)-[r]->(m)
return distinct labels(n), type(r), labels(m);
//model in visualization
call db.schema.visualization;