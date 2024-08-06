## Defining Serializer

```lua
local Serializer = loadstring(game:HttpGet("https://raw.githubusercontent.com/zyzxti123/Serializer/main/source.lua"))()({
    DebugFunctions = false, --// Show constants, upvalues, and protos in functions
    DebugTypes = true --// Show all types for values and keys
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

## Usage
To use the serializer, simply call the corresponding function and pass the data to be serialized. For example:
```lua
local Serializer = loadstring(game:HttpGet("https://raw.githubusercontent.com/zyzxti123/Serializer/main/source.lua"))()({
    DebugFunctions = false, --// Show constants, upvalues, and protos in functions
    DebugTypes = true --// Show all types for values and keys
})

local example = {
    ["Hello Github"] = "Hello Github!"
}

warn(Serializer.serializeTable(example)) --> return { ["Hello Github"] = "Hello Github!" --string, string }
```

## Why?
Yes.
