## Defining Serializer

```lua
local Serializer = loadstring(game:HttpGet("https://raw.githubusercontent.com/zyzxti123/Serializer/main/source.lua"))()({
    DebugFunctions = false, --// Show constants, upvalues, and protos in functions
    DebugTypes = true --// Show all types for values and keys
    ReadMetatables = false --// Display full metatable structure (by default only values from __index will be showed)
})
```

## Serializer Functions

### Serializing JSON
```lua
Serializer.serializeJSON(input: string): string
```
Serializes JSON into redeable string

### Serializing Table
```lua
Serializer.serializeTable(input: table): string
```
Serializes table into redeable string

### Serializing Metatable
```lua
Serializer.serializeMetatable(input: metatable): string
```
Serializes metatable into redeable string and reconstructing the structure of the metatable

## Basic Usage
To use the serializer, simply call the corresponding function and pass the data to be serialized. For example:
```lua
local Serializer = loadstring(game:HttpGet("https://raw.githubusercontent.com/zyzxti123/Serializer/main/source.lua"))()({
    DebugFunctions = false, --// Show constants, upvalues, and protos in functions
    DebugTypes = true, --// Show all types for values and keys
    ReadMetatables = false --// Display full metatable structure (by default only values from __index will be showed)
})

local example = {
    ["Hello Github"] = "Hello Github!"
}

warn(Serializer.serializeTable(example)) --> return { ["Hello Github"] = "Hello Github!" --string, string }
```

## Why?
The Serializer provides an efficient and human-readable way to serialize and debug complex data structures in roblox. Whether you’re working with JSON, tables, metatabler, or functions, this tool allows you to quickly inspect and visualize the underlying data in a clear format. It’s especially useful for debugging, data analysis, and ensuring that your serialized data matches the expected structure.
