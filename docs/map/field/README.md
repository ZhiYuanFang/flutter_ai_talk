# Field CSV (per map)

One CSV per map under `data/field/` (e.g. `data/field/field001.csv`).

## Columns

| Column | Description |
|--------|-------------|
| FieldID | Unique field id within the map file |
| RegionFileName | Region asset file name (e.g. `region001`) |
| MapName | Map asset file name (e.g. `field001`) |
| X | Field origin X |
| Y | Field origin Y |
| Width | Field width |
| Height | Field height |
| FieldName | Display name |
| FieldType | Field type id |
| Description | Optional description |
| Enable | 1 = enabled, 0 = disabled |

## Example

```csv
FieldID,RegionFileName,MapName,X,Y,Width,Height,FieldName,FieldType,Description,Enable
1,region001,field001,100,200,500,500,新手村,1,Starting village,1
2,region001,field001,600,200,400,400,森林,2,Forest area,1
```

## Notes

- **RegionFileName** must match a region asset under `data/map/region/` (e.g. `region001.csv`).
- **MapName** must match the map asset file name (e.g. `field001.csv` under `data/field/`).
- **FieldID** is unique within the map CSV file.

---

# Spawn route CSV (per region)

One CSV per region for spawn routes (e.g. `data/map/region/region001/spawns.csv` or alongside region assets). Defines which monsters spawn in that region.

## Columns

| Column | Description |
|--------|-------------|
| SpawnRouteID | Unique spawn route id within the region file |
| ServerName | Server identifier (must match server config) |
| RegionFileName | Region asset file name (e.g. `region001`) |
| MapName | Map asset file name (e.g. `field001`) |
| X | Spawn X coordinate |
| Y | Spawn Y coordinate |
| Type | Monster / entity type id |
| Level | Spawn level |
| ItemCount | Item count (if applicable) |
| Description | Optional description |
| Enable | 1 = enabled, 0 = disabled |
| RespawnTime | Respawn time (seconds) |
| MinRespawnTime | Min respawn time |
| MaxRespawnTime | Max respawn time |
| IsWorldBoss | 1 = world boss spawn |
| IsEventBoss | 1 = event boss spawn |
| IsGuildBoss | 1 = guild boss spawn |
| EventId | Event id (if event boss) |
| SpawnRadius | Spawn radius |
| IsStatic | 1 = static spawn |
| Direction | Facing direction |

## Example

```csv
SpawnRouteID,ServerName,RegionFileName,MapName,X,Y,Type,Level,ItemCount,Description,Enable,RespawnTime,MinRespawnTime,MaxRespawnTime,IsWorldBoss,IsEventBoss,IsGuildBoss,EventId,SpawnRadius,IsStatic,Direction
1,server1,region001,field001,100,200,101,10,0,Slime spawn,1,60,30,90,0,0,0,0,50,0,0
```

## Notes

- **ServerName** must match the server configuration.
- **RegionFileName** must match the region asset (e.g. `region001.csv`).
- **MapName** must match the map asset file name (e.g. `field001.csv` under `data/field/`).
