# PointsManager Mini Documentation

Updated 2017-12-05

[< Lua][0]

## Functions

### Set Points
*side* - String: one of `["Radiant", "Dire"]`
*newPoints* - Integer: new Point value
```Lua
PointsManager:SetPoints(side, newPoints)
```
### Add Points
*side* - String: one of `["Radiant", "Dire"]`
*amount* - Integer: Points to add. If nil add 1 Point
```Lua
PointsManager:AddPoints(side, amount)
```

[0]: README.md
