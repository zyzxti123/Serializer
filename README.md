## Defining Serializer

```lua
local Serializer = loadstring(game:HttpGet("https://raw.githubusercontent.com/zyzxti123/Serializer/main/source.lua"))({
  DebugFunctions = false, --//showing constants, upvalues, protos in functions
  DebugTypes = true --//showing types in generic loops (key, indexes, values etc.)
})
```

## Serializer Functions

### Serializing JSON
```lua
Serializer.serializeJSON(input: string): string
```

### Serializing Table
```lua
Serializer.serializeTable(input: table): string
```
