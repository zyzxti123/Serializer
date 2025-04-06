--!strict
local Serializer = {Cache = {}}
Serializer.__index = Serializer

--https://www.lua.org/gems/sample.pdf
--https://devforum.roblox.com/t/does-assigning-functions-to-variables-help-with-performance/1647552
local string_lower = string.lower
local string_find = string.find
local string_sub = string.sub
local string_gsub = string.gsub
local string_len = string.len
local string_format = string.format
local string_match = string.match
local string_byte = string.byte
local string_rep = string.rep
local table_insert = table.insert
local table_remove = table.remove
local table_concat = table.concat
local debug_getconstants = debug["getconstants"]
local debug_getupvalues = debug["getupvalues"]
local debug_getprotos = debug["getprotos"]
local debug_getinfo = debug["getinfo"]
local debug_info = debug.info
local debug_traceback = debug.traceback

local Watermark: string = ""
Watermark ..= "--[["
Watermark ..= "\n\t@developer: zyzxti"
Watermark ..= "\n\t@contact: zyzxti#2047"
Watermark ..= "\n\t@version: 0.8.5 | https://github.com/zyzxti123/Serializer"
Watermark ..= "\n]]--"
Watermark ..= string_rep("\n", 2)

type Array<Type> = {[number] : Type}
type Dictionary<Type1, Type2> = {[Type1] : Type2}
type Options = {
	DebugFunctions: boolean?, 
	DebugTypes: boolean?,
	ReadMetatables: boolean?,
}

--[[
	Adds tabulators to the input string based on the provided depth.
]]--
Serializer.AddTabulators = function(self, input: string, depth: number?): string -- WIP function
	assert(typeof(input) == "string", "Expected input to be a string")
	assert(typeof(depth) == "number", "Expected depth to be a number")

	return string_rep("\t", depth or 0) .. input
end

--[[
	Adds new lines to the input string based on the provided depth.
]]--
Serializer.AddNewLines = function(self, input: string, depth: number?): string -- WIP function
	assert(typeof(input) == "string", "Expected input to be a string")
	assert(typeof(depth) == "number", "Expected depth to be a number")

	return string_rep("\n", depth or 0) .. input
end

--[[
	Adds a single-line comment to the input string.
]]--
Serializer.AddSingleLineComment = function(self, input: string, comment: string?): string -- WIP function
	assert(typeof(input) == "string", "Expected input to be a string")
	assert(typeof(comment) == "string" or comment == nil, "Expected comment to be a string")

	return string_format("%s -- %s", input, comment or "") or input
end

--[[
	Adds a block comment to the input string.
]]--
Serializer.AddBlockComment = function(self, input: string, comment: string?): string
	assert(typeof(input) == "string", "Expected input to be a string")
	assert(typeof(comment) == "string", "Expected comment to be a string")

	return string_format("%s --[[\n\t%s\n]]--", input, comment)
end

--[[
	Formats the given string to make it more readable by escaping special characters.
]]--
Serializer.FormatString = function(self, input: string): string
	assert(typeof(input) == "string", "Expected input to be a string")

	local specialCharacters: {[string]: string} = {
		["\""] = "\\\"",
		["\\"] = "\\\\",
		["\a"] = "\\a",
		["\b"] = "\\b",
		["\t"] = "\\t",
		["\n"] = "\\n",
		["\v"] = "\\v",
		["\f"] = "\\f",
		["\r"] = "\\r",
		["/"] = "\\/"
	}

	return string_gsub(string_gsub(input, "[%z\\\"/\1-\31\127-\255]", function(character: string)
		return specialCharacters[character] and specialCharacters[character] or "\\" .. string_byte(character)
	end), '"', '\"')
end

--[[
	Removes dot zeroes and the decimal separator if the number is an integer.
]]--
Serializer.RemoveDotZero = function(self, number: number, precision: number?): string
	assert(typeof(number) == "number", "Expected number to be a number")
	assert(precision and typeof(number) == "number" or not precision, "Expected precision to be a number")

	return string_gsub(string_format("%." .. (precision or 2) .. "f", number), "%.?0+$", "")
end

--[[
	Formats the number to handle special cases like infinity, NaN, or large numbers.
]]--
Serializer.FormatNumber = function(self, number: number): string
	assert(typeof(number) == "number", "Expected number to be a number")

	if number == math.huge then
		return "math.huge"
	elseif number == -math.huge then
		return "-math.huge"
	elseif number == 0/0 then
		return "0/0"
	elseif number == -0/0 then
		return "-0/0"
	end

	return number >= 2^63-1 and string_format("%.2e", number) or tostring(number) --string_format("%.2f", num)
end

--[[
	Checks if a service exists by <code>ClassName</code>.
]]--
Serializer.IsService = function(self, className: string): boolean
	local success: boolean, results: any = pcall(function() 
		return game:FindService(className)
	end)

	return success, results
end

--[[
	Checks if table is a Array from the input table.
]]--
Serializer.IsArray = function(self, input: (Array<any> | Dictionary<any, any>)): boolean
	assert(typeof(input) == "table", "Expected input to be a table")
	
	local count = 0
	for key: any in pairs(input) do
		if typeof(key) ~= "number" or key < 1 or math.floor(key) ~= key then
			return false
		end
		count += 1
	end
	
	return count == #input
end

Serializer.GetSortedKeyValuePairs = function(self, input: (Array<any> | Dictionary<any, any>)): Dictionary<any, any>
	local keys: Array<string> = {}
	for key: any, _ in pairs(input) do
		table.insert(keys, key)
	end

	table.sort(keys, function(a, b)
		local typeA: any, typeB: any = typeof(a), typeof(b)

		if typeA == typeB then
			if typeA == "number" then
				return a < b
			elseif typeA == "string" then
				return a < b
			else
				return tostring(a) < tostring(b)
			end
		end

		if typeA == "number" then return true end
		if typeB == "number" then return false end
		if typeA == "string" then return true end
		if typeB == "string" then return false end

		return tostring(typeA) < tostring(typeB)
	end)

	local sorted: Dictionary<any, any> = {}
	for _, key: any in ipairs(keys) do
		sorted[key] = input[key]
	end

	return sorted
end

--[[
	Removes empty strings from the input table.
]]--
Serializer.RemoveEmptyStrings = function(self, input: Array<string>): Array<string>
	assert(typeof(input) == "table", "Expected input to be a table")

	local output: Array<string> = {}
	for _, value in ipairs(input) do
		if value and string_len(value) > 0 and string_match(value, "%S") then
			table_insert(output, value)
		end
	end

	return output
end

--[[
	Formats the full path of an instance.
]]--
Serializer.FormatInstancePath = function(self, instance: Instance): string
	assert(typeof(instance) == "Instance", "Expected instance to be an Instance")

	local isServiceInstance: boolean, serviceInstance: Instance = self:IsService(instance.ClassName)
	if isServiceInstance and serviceInstance then
		return string_format("game:GetService('%s')", instance.ClassName)
	end

	local instancePath: string = instance:GetFullName()
	local instancePathParts: Array<string> = instancePath:split(".")
	local formattedInstancePathParts: Array<string> = {}

	for i = 1, #instancePathParts do
		local instancePathPart: string = instancePathParts[i]
		local isServiceInstance: boolean, serviceInstance: Instance = self:IsService(instancePathPart)

		if isServiceInstance and serviceInstance then
			table_insert(formattedInstancePathParts, string_format("game:GetService('%s')", instancePathPart))
		else
			table_insert(formattedInstancePathParts, string_find(instancePathPart, "[%s%p]") and string_format("['%s']", instancePathPart) or instancePathPart)
		end
	end

	return "game." .. string_gsub(table_concat(formattedInstancePathParts, "."), ".%[", "[")
end

--[[
	Formats various types of values into a string.
]]--
Serializer.FormatValue = function(self, input: any): string
	local inputType: any = typeof(input)
	local inputTypeHandlers: {[string]: (...any) -> (...any)} = {}

	inputTypeHandlers["nil"] = function() 
		return "nil" 
	end

	inputTypeHandlers["string"] = function() 
		return '"' .. self:FormatString(input) .. '"'
	end

	inputTypeHandlers["number"] = function()
		return self:FormatNumber(input) 
	end

	inputTypeHandlers["boolean"] = function() 
		return input and "true" or "false" 
	end

	inputTypeHandlers["CFrame"] = function() 
		return string_format("CFrame.new(%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f)", input:GetComponents()) 
	end

	inputTypeHandlers["Vector3"] = function() 
		return string_format("Vector3.new(%f, %f, %f)", input.X, input.Y, input.Z) 
	end

	inputTypeHandlers["Vector2"] = function() 
		return string_format("Vector2.new(%f, %f)", input.X, input.Y) 
	end

	inputTypeHandlers["Color3"] = function() 
		return string_format("Color3.new(%f, %f, %f)", input.R, input.G, input.B) 
	end

	inputTypeHandlers["BrickColor"] = function() 
		return string_format("BrickColor.new('%s')", input.Name) 
	end

	inputTypeHandlers["UDim2"] = function() 
		return string_format("UDim2.new(%f, %d, %f, %d)", input.X.Scale, input.X.Offset, input.Y.Scale, input.Y.Offset) 
	end

	inputTypeHandlers["UDim"] = function() 
		return string_format("UDim.new(%f, %d)", input.Scale, input.Offset) 
	end

	inputTypeHandlers["EnumItem"] = function() 
		return tostring(input)
	end

	inputTypeHandlers["DateTime"] = function()
		return "DateTime.fromUnixTimestamp(" .. input.UnixTimestamp .. ")"
	end

	inputTypeHandlers["NumberSequence"] = function()
		local keypoints = {}
		for _, keypoint in ipairs(input.Keypoints) do
			table_insert(keypoints, string_format("NumberSequenceKeypoint.new(%f, %f, %f)", keypoint.Time, keypoint.Value, keypoint.Envelope))
		end

		return string_format("NumberSequence.new({%s})", table_concat(keypoints, ", "))
	end

	inputTypeHandlers["NumberRange"] = function()
		return string_format("NumberRange.new(%f, %f)", input.Min, input.Max)
	end

	inputTypeHandlers["Instance"] = function() 
		return self:FormatInstancePath(input)
	end

	--inputTypeHandlers["function"] = function() 
	--	return self:serializeFunction(val, 1) .. " -- ???"
	--end

	return inputTypeHandlers[inputType] and inputTypeHandlers[inputType]() or self:FormatString(tostring(input))
end

--[[
	Gets the arguments of a function.
]]--
Serializer.GetFunctionArguments = function(self, func: (...any) -> (...any)): Array<string>
	assert(typeof(func) == "function", "Expected func to be a function")

	local functionArguments: Array<string> = {}
	if debug_getinfo then
		local functionDebugInfo: Dictionary<any, any> = debug_getinfo(func)
		if functionDebugInfo.nups then
			for i = 1, functionDebugInfo.nups do
				table_insert(functionArguments, "arg" .. i)
			end
		end

		if functionDebugInfo.is_varang then
			table_insert(functionArguments, "...")
		end
	else
		local functionArgumentsCount: number = debug_info(func, "a")
		for i = 1, functionArgumentsCount do
			table_insert(functionArguments, "arg" .. i)
		end
	end

	return functionArguments
end

--[[
	Formats the function arguments into a comma-separated string.
]]--
Serializer.FormatFunctionArguments = function(self, functionArguments: {string}): string
	assert(typeof(functionArguments) == "table", "Expected input to be a table")

	return #functionArguments > 0 and table_concat(functionArguments, ", ") or ""
end

--[[
	Serializes a given function into a string format.
]]--
Serializer.SerializeFunction = function(self, func: (...any) -> (...any), depth: number): string
	assert(typeof(func) == "function", "Expected func to be a function")
	assert(typeof(depth) == "number", "Expected depth to be a number")

	local functionLine = debug_info(func, "l")
	local functionName = debug_info(func, "n")
	local functionArguments = self:FormatFunctionArguments(self:GetFunctionArguments(func))

	local output = string_format("function(%s)", functionArguments)

	if self.Options.DebugFunctions then
		output ..= string_format("\t-- Line Defined: %d, Function Name: %s", functionLine, functionName ~= "" and functionName or "Anonymous Function")

		if debug_getconstants and debug_getupvalues and debug_getprotos then
			output ..= self:AddTabulators("\n", depth)

			output ..= self:AddTabulators("--[[ Constants:", depth)
			for i, v in next, debug_getconstants(func) do
				output ..= self:AddTabulators("\n", depth + 1)
				output ..= self:AddTabulators(string_format("%s = %s", tostring(i), tostring(v)), depth + 2)
			end
			output ..= "\n"
			output ..= self:AddTabulators("]]--", depth)
			output ..= string_rep("\n", 2)

			output ..= self:AddTabulators("--[[ Upvalues:", depth)
			for i, v in next, debug_getupvalues(func) do
				output ..= "\n"
				output ..= self:AddTabulators(string_format("%s = %s", tostring(i), tostring(v)), depth + 2)
			end
			output ..= "\n"
			output ..= self:AddTabulators("]]--", depth)
			output ..= string_rep("\n", 2)

			output ..= self:AddTabulators("--[[ Protos:", depth)
			for i, v in next, debug_getprotos(func) do
				output ..= "\n"
				output ..= self:AddTabulators(string_format("%s = %s", tostring(i), tostring(v)), depth + 2)
			end
			output ..= "\n"
			output ..= self:AddTabulators("]]--", depth)
		else
			output ..= self:AddTabulators("\n", depth)
			output ..= self:AddTabulators("-- DebugFunctions is not supported on your executor!", depth)
		end
	else
		output ..= self:AddTabulators("\n", depth)
	end

	output ..= self:AddTabulators("\n", depth)
	output ..= self:AddTabulators("end", depth - 1)

	return output
end

--[[
	Serializes a given metatable into a string format.
]]--
Serializer.SerializeMetatable = function(self, input: (Array<any> | Dictionary<any, any>), depth: number): string
	assert(typeof(input) == "table", "Expected input to be a table")
	assert(typeof(depth) == "number", "Expected depth to be a number")
	
	local serializedTable: string = self:SerializeTable(input, depth)
	local serializedMetatable: string = self:SerializeTable(getmetatable(input::any), depth)
	return string_format("setmetatable({\n%s\n%s}, {\n%s\n%s})", serializedTable, self:AddTabulators("", depth - 1), serializedMetatable, self:AddTabulators("", depth - 1))
end

--[[
	Serializes a given table into a string format.
]]--
Serializer.SerializeTable = function(self, input: (Array<any> | Dictionary<any, any>), depth: number): string
	assert(typeof(input) == "table", "Expected input to be a table")
	assert(typeof(depth) == "number", "Expected depth to be a number")
	
	-- Prevent for stack overflow when something trying to grab same exact table somewhere
	if self.Cache[input] then
		return table.concat(self:RemoveEmptyStrings(self.Cache[input]), "\n")
	end
	
	local output: {string} = {}
	depth = depth or 0
	
	local iterator: (...any) -> (...any) = self:IsArray(input) and ipairs or pairs
	for key: any, value: any in iterator(input) do
		local valueType: any = typeof(value)
		local keyString: string = self:AddTabulators(string_format("[%s]", typeof(key) == "number" and tostring(key) or '"' .. tostring(self:FormatString(key)) .. '"'), depth)

		local valueString: string
		if valueType == "table" then
			if self.Options.ReadMetatables and getmetatable(value) ~= nil then
				local serializedMetatable: string = self:SerializeMetatable(value, depth + 1)
				if serializedMetatable == "" or serializedMetatable == "\n" then
					valueString = "{},"
				else
					valueString = string_format("%s,", serializedMetatable)
				end
			else
				local serializedTable: string = self:SerializeTable(value, depth + 1)
				if serializedTable == "" or serializedTable == "\n" then
					valueString = string_format("{%s},", getmetatable(value) ~= nil and "--[[ Metatable detected - enable 'ReadMetatables' to serialize and preserve its full structure accurately ]]--" or "")
				else
					valueString = string_format("{\n%s%s\n%s},", getmetatable(value) ~= nil and self:AddTabulators("--[[ Metatable detected - enable 'ReadMetatables' to serialize and preserve its full structure accurately ]]--\n", depth + 1) or "" , serializedTable, self:AddTabulators("", depth))
				end
			end
		elseif valueType == "function" then
			valueString = string_format("%s,", self:SerializeFunction(value, depth + 1))
		else
			valueString = string_format("%s,", self:FormatValue(value))
		end

		if self.Options.DebugTypes then
			local debugTypeInfo = string_format(" --%s, %s", tostring(typeof(key)), tostring(typeof(value)))

			if typeof(value) == "Instance" then
				debugTypeInfo ..= string_format(" (ClassName: %s)", value.ClassName)
			end

			valueString ..= debugTypeInfo
		end

		table.insert(output, string_format("%s = %s", keyString, valueString))
	end
	
	self.Cache[input] = output
	return table.concat(self:RemoveEmptyStrings(output), "\n")
end

return function(options: Options?)
	local self = setmetatable({}, Serializer)

	self.Options = options or {
		DebugFunctions = false,
		DebugTypes = true,
		ReadMetatables = false,
	}::Options

	return {
		serializeJSON = function(input: string): string
			assert(typeof(input) == "string", "The first argument in serializeJSON must be a string!")
			
			local function Exception(result)
				return string_format("Failed to serializeJSON %s\nTraceback: %s", result, debug_traceback())
			end

			local success, results = pcall(function() 
				return game:GetService("HttpService"):JSONDecode(input)
			end)

			if success then
				local success, results = pcall(function() 
					return string_format("%s\nreturn {\n%s\n}", Watermark, self:SerializeTable(results, 1))
				end)
				return success and results or Exception(results)
			end
			
			return Exception(results)
		end,

		serializeTable = function(input: (Array<any> | Dictionary<any, any>)): string
			assert(typeof(input) == "table", "The first argument in serializeTable must be a Table!")
			
			local function Exception(result)
				return string_format("Failed to serializeTable: %s\nTraceback: %s", result, debug_traceback())
			end
			
			local success, results = pcall(function() 
				return  string_format("%s\nreturn {\n%s\n}", Watermark, self:SerializeTable(input, 1))
			end)
			
			return success and results or Exception(results)
		end
	}
end
