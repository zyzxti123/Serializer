local Serializer = {}
Serializer.__index = Serializer

local Watermark = "--[[\nTable/JSON serializer developed by - zyzxti#2047\ncan be useful when you want to see a refreshed table or when your executor does not have decompiler\nversion - 1.3\n]]--" --// dont delete it or u are skid

function Serializer:addTabSpaces(str, depth)
    return string.rep("\t", depth or 0) .. str
end

function Serializer:getArguments(func)
    local args = {}
    local funcInfo = debug.getinfo(func)

    if funcInfo.nups then
        for i = 1, funcInfo.nparams do
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

    local output = self:addTabSpaces("function(" .. formattedArgs .. ")", depth)
	output = output .. "\n" .. self:addTabSpaces("end", depth)

    return output
end

function Serializer:serializeTable(input, depth)
    local output = {}
    depth = depth or 0

    for key, value in pairs(input) do
        local keyStr = string.format("[%q]", tostring(key))
        local valueType = type(value)
        local formattedStr = self:addTabSpaces(keyStr .. " = ", depth)

        if valueType == "table" then
            formattedStr = formattedStr .. "{\n" .. self:serializeTable(value, depth + 1) .. "\n" .. self:addTabSpaces("},", depth) .. " --" .. tostring(typeof(key)) .. ", " .. tostring(typeof(value))
        elseif valueType == "function" then
            formattedStr = formattedStr .. self:serializeFunction(value, depth + 1) .. "," .. " --" .. tostring(typeof(key)) .. ", " .. tostring(typeof(value))
        else
            formattedStr = formattedStr .. string.format("%q", tostring(value)) .. "," .. " --" .. tostring(typeof(key)) .. ", " .. tostring(typeof(value))
        end

        table.insert(output, formattedStr)
    end

    return table.concat(output, "\n")
end

function Serializer:serializeJSON(input)
	local success, result = pcall(function() 
		return game:GetService("HttpService"):JSONDecode(input)
	end)

	assert(not success, "The first argument in serializeJSON must be a JSON!")

	return self:serializeTable(result)
end

getgenv().Serializer = {
    serializeJSON = function(input)
        return Watermark .. "\nreturn {\n" .. Serializer:serializeJSON(input, 1) .. "\n}"
    end,

    serializeTable = function(input)
        assert(typeof(input) == "table", "The first argument in serializeTable must be a Table!")
        return Watermark .. "\nreturn {\n" .. Serializer:serializeTable(input, 1) .. "\n}"
    end
}

--// Use this if u want "bypass" console max chars (may be laggy and glitchy but...)
--[[
local old; old = hookfunction(print, function(...)
	local input = {...}
	
	for _, message in pairs(input) do
		local Length = #message
		local Parts = {}

		for index = 1, Length, 5000 do
			table.insert(Parts, message:sub(index, math.min(index + 5000 - 1, Length)))
		end

		for _, part in pairs(Parts) do
			old(part)
		end
	end
end)
]]--
