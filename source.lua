local Serializer = {}
Serializer.__index = Serializer

local Watermark: string = ""
Watermark ..= "--[["
Watermark ..= "\n@developer: zyzxti"
Watermark ..= "\n@contact: zyzxti#2047"
Watermark ..= "\n@version: 1.5 | https://github.com/zyzxti123/Serializer"
Watermark ..= "\n]]--"
Watermark ..= string.rep("\n", 2)

function Serializer:addTabSpaces(str: string, depth: number): string
    return string.rep("\t", depth or 0) .. str
end

function Serializer:getArguments(func: any): {string}
    local args: {string} = {}
    local funcInfo: {} = debug.getinfo(func)

    if funcInfo.nups then
        for i = 1, funcInfo.nups do
            table.insert(args, "arg" .. i)
        end
    end

    if funcInfo.is_varang then
        table.insert(args, "...")
    end

    return args
end

function Serializer:formatArguments(args: any): string
    return args and #args > 0 and table.concat(args, ", ") or ""
end

function Serializer:formatString(input: string): string
    local result: string = ""
    for index: number = 1, #input do
        local byte: number = string.byte(input, index)
        result ..= byte > 127 and "\\" .. byte or string.char(byte)
    end
    return result
end

--TODO: add more cool formating for values :)
function Serializer:formatValue(value: any): string
    local valueType: any = typeof(value)

    if valueType == nil and value == nil then
        return "nil"
    elseif valueType == "string" then
        return string.format("%q", self:formatString(tostring(value)))
    elseif  valueType == "number" then
        return value
    elseif valueType == "boolean"  then
        return tostring(value)
    elseif valueType == "CFrame" then
        return string.format("CFrame.new(%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f)", value:GetComponents())
    elseif valueType == "Vector3" then
        return string.format("Vector3.new(%f, %f, %f)", value.X, value.Y, value.Z)
    elseif valueType == "Vector2" then 
        return string.format("Vector2.new(%f, %f)", value.X, value.Y)
    elseif valueType == "Color3" then
        return string.format("Color3.new(%f, %f, %f)", value.R, value.G, value.B)
    elseif valueType == "BrickColor" then
        return string.format("BrickColor.new('%s')", value.Name)
    elseif valueType == "UDim2" then
        return string.format("UDim2.new(%f, %d, %f, %d)", value.X.Scale, value.X.Offset, value.Y.Scale, value.Y.Offset)
    elseif valueType == "UDim" then
        return string.format("UDim.new(%f, %d)", value.Scale, value.Offset)
    elseif valueType == "EnumItem" then
        return string.format("%s.%s", value.EnumType.Name, value.Name)
    elseif valueType == "NumberSequence" then
        local keypoints: {string} = {}
        for _, keypoint: NumberSequenceKeypoint in ipairs(value.Keypoints) do
            table.insert(keypoints, string.format("NumberSequenceKeypoint.new(%f, %f, %f)", keypoint.Time, keypoint.Value, keypoint.Envelope))
        end
        return string.format("NumberSequence.new({%s})", table.concat(keypoints, ", "))
    elseif valueType == "Instance" then
        return value.Parent and value:GetFullName() or "nil -- Insatnce parent is nil failed to get full name!"
    else
        --warn(valueType, "is not supported by self:formatValues(...)")
        return string.format("%q", self:formatString(tostring(value)))
    end
end

function Serializer:removeEmptyStrings(tbl: {string}): {string}
    local result: {string} = {}
    for _, value: string in ipairs(tbl) do
        if value == "\n" or value ~= "" then
            table.insert(result, value)
        end
    end
    return result
end

function Serializer:serializeFunction(func: any, depth: number): string
    local args: {string} = self:getArguments(func)
    local formattedArgs: string = self:formatArguments(args)

    local output: string = "function(" .. formattedArgs .. ")"
          
    if self.options.DebugFunctions then
        local getconstants = debug.getconstants
        local getupvalues = debug.getupvalues
        local getprotos = debug.getprotos

        if getconstants and getupvalues and getprotos then
            output ..= self:addTabSpaces("\n", depth)
            output ..= self:addTabSpaces("------[[CONSTANTS]]------", depth)

            local constants = {}
            for i, v in next, getconstants(func) do
                output ..= self:addTabSpaces("\n", depth)
                output ..= self:addTabSpaces(tostring(i) .. " = " .. tostring(v), depth)
            end
    
            output ..= self:addTabSpaces("\n", depth)
            output ..= self:addTabSpaces("------[[UPVALUES]]-------", depth)

            local upvalues = {}
            for i, v in next, getupvalues(func) do
                output ..= self:addTabSpaces("\n", depth)
                output ..= self:addTabSpaces(tostring(i) .. " = " .. tostring(v), depth)
            end
    
            output ..= self:addTabSpaces("\n", depth)
            output ..= self:addTabSpaces("-------[[PROTOS]]--------", depth)

            local protos = {}
            for i, v in next, getprotos(func) do
                output ..= self:addTabSpaces("\n", depth)
                output ..= self:addTabSpaces(tostring(i) .. " = " .. tostring(v), depth)
            end
        else
            output ..= self:addTabSpaces("\n", depth)
            output ..= self:addTabSpaces("--DebugFunctions is not supported on your executor!", depth)
        end
    else
        output ..= self:addTabSpaces("\n", depth)
    end

	output ..= self:addTabSpaces("\n", depth)
    output ..= self:addTabSpaces("end", depth - 1)
	
    return output
end

type Array<Type> = {[number] : Type};
type Dictionary<Type> = {[string] : Type};

function Serializer:serializeTable(input: (Array | Dictionary), depth: number): string
    local output: {string} = {}
    depth = depth or 0

    for key: any, value: any in pairs(input) do
        local keyStr: string = string.format("[%s]", typeof(key) == "number" and tostring(key) or '"' .. tostring(key) .. '"')
        local valueType: any = typeof(value)
        local formattedStr: string = self:addTabSpaces(keyStr .. " = ", depth)

        if valueType == "table" then
            local _output = self:serializeTable(value, depth + 1)
            
            if _output == "" or _output == "\n" then
                formattedStr ..= "{},"
            else
                formattedStr ..= "{" .. "\n" .. _output .. "\n" .. self:addTabSpaces("},", depth)
            end
        elseif valueType == "function" then
            formattedStr ..= self:serializeFunction(value, depth + 1) .. ","
        else
            formattedStr ..= self:formatValue(value) .. "," 
        end

        if self.options.DebugTypes then
            formattedStr ..= " --" .. tostring(typeof(key)) .. ", " .. tostring(typeof(value))
        end

        table.insert(output, formattedStr)
    end

    return table.concat(self:removeEmptyStrings(output), "\n")
end

type Options = {DebugFunctions: boolean?, DebugTypes: boolean?}
getgenv().Serializer = function(options: Options?)
    local self = setmetatable({}, Serializer)

    self.options = options or {
        DebugFunctions = false, 
        DebugTypes = true
    }

    return {
        serializeJSON = function(input)
            local success, result = pcall(function() 
                return game:GetService("HttpService"):JSONDecode(input)
            end)
    
            assert(success, "The first argument in serializeJSON must be a JSON!")
            return Watermark .. "\nreturn {\n" .. self:serializeTable(result, 1) .. "\n}"
        end,
    
        serializeTable = function(input)
            assert(typeof(input) == "table", "The first argument in serializeTable must be a Table!")
            return Watermark .. "\nreturn {\n" .. self:serializeTable(input, 1) .. "\n}"
        end
    }
end
