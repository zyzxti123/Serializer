local Serializer = {}
Serializer.__index = Serializer

local Watermark = "--[["
Watermark = Watermark .. "\n@developer: zyzxti"
Watermark = Watermark .. "\n@contact: zyzxti#2047"
Watermark = Watermark .. "\n@usage: serializing tables to string / serializing json to serialized table"
Watermark = Watermark .. "\n@version: 1.3.6f | https://github.com/zyzxti123/Serializer"
Watermark = Watermark .. "\n]]--"
Watermark = Watermark .. string.rep("\n", 3)

function Serializer:addTabSpaces(str, depth)
    return string.rep("\t", depth or 0) .. str
end

function Serializer:getArguments(func)
    local args = {}
    local funcInfo = debug.getinfo(func)

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

function Serializer:formatArguments(args)
    return args and #args > 0 and table.concat(args, ", ") or ""
end

function Serializer:serializeFunction(func, depth)
    local args = self:getArguments(func)
    local formattedArgs = self:formatArguments(args)

    local output = "function(" .. formattedArgs .. ")"
          
    if self.options.DebugFunctions then
        local getconstants = debug.getconstants
        local getupvalues = debug.getupvalues
        local getprotos = debug.getprotos

        if getconstants and getupvalues and getprotos then
            output = output .. self:addTabSpaces("\n", depth)
            output = output .. self:addTabSpaces("------[[CONSTANTS]]------", depth)

            local constants = {}
            for i, v in next, getconstants(func) do
                output = output .. self:addTabSpaces("\n", depth)
                output = output .. self:addTabSpaces(tostring(i) .. " = " .. tostring(v), depth)
            end
    
            output = output .. self:addTabSpaces("\n", depth)
            output = output .. self:addTabSpaces("------[[UPVALUES]]-------", depth)

            local upvalues = {}
            for i, v in next, getupvalues(func) do
                output = output .. self:addTabSpaces("\n", depth)
                output = output .. self:addTabSpaces(tostring(i) .. " = " .. tostring(v), depth)
            end
    
            output = output .. self:addTabSpaces("\n", depth)
            output = output .. self:addTabSpaces("-------[[PROTOS]]--------", depth)

            local protos = {}
            for i, v in next, getprotos(func) do
                output = output .. self:addTabSpaces("\n", depth)
                output = output .. self:addTabSpaces(tostring(i) .. " = " .. tostring(v), depth)
            end
        else
            output = output .. self:addTabSpaces("\n", depth)
            output = output .. self:addTabSpaces("--DebugFunctions Not supported!", depth)
        end
    else
        output = output .. self:addTabSpaces("\n", depth)
    end

	output = output .. self:addTabSpaces("\n", depth)
    output = output .. self:addTabSpaces("end", depth - 1)
	
    return output
end

function Serializer:serializeTable(input, depth)
    local output = {}
    depth = depth or 0

    for key, value in next, input do
        local keyStr = string.format("[%s]", typeof(key) == "number" and tostring(key) or "'" .. tostring(key) .. "'")
        local valueType = type(value)
        local formattedStr = self:addTabSpaces(keyStr .. " = ", depth)

        if valueType == "table" then
            formattedStr = formattedStr
                           .. "{"
                           .. "\n"
                           .. self:serializeTable(value, depth + 1)
                           .. "\n"
                           .. self:addTabSpaces("},", depth)
        elseif valueType == "function" then
            formattedStr = formattedStr
                           .. self:serializeFunction(value, depth + 1)
                           .. ","
        else
            formattedStr = formattedStr
                           .. string.format("%q", tostring(value))
                           .. "," 
        end

        if self.options.DebugTypes then
            formattedStr = formattedStr
                           .. " --"
                           .. tostring(typeof(key))
                           .. ", " 
                           .. tostring(typeof(value))
        end

        table.insert(output, formattedStr)
    end

    --//Removing dead spaces
    for i, v in next, output do
        if v == "" or v == "\n" then
            table.remove(output, i)
        end
    end

    return table.concat(output, "\n")
end

export type Options = {
    DebugFunctions: boolean?,
    DebugTypes: boolean?
}

return function(options: Options?)
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
