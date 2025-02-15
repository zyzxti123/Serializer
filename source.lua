local Serializer = {}
Serializer.__index = Serializer

local Watermark: string = ""
Watermark ..= "--[["
Watermark ..= "\n@developer: zyzxti"
Watermark ..= "\n@contact: zyzxti#2047"
Watermark ..= "\n@version: 1.6 | https://github.com/zyzxti123/Serializer"
Watermark ..= "\n]]--"
Watermark ..= string.rep("\n", 2)

type Array<Type> = {[number] : Type}
type Dictionary<Type> = {[string] : Type}
type Options = {
	DebugFunctions: boolean?, 
	DebugTypes: boolean?,
	ReadMetatables: boolean?
}

function Serializer:addTabSpaces(str: string, depth: number): string
	return string.rep("\t", depth or 0) .. str
end

function Serializer:formatString(input: string): string
	local specialChars = {
		["\""] = "\\\"",
		["\\"] = "\\\\",
		["\a"] = "\\a",
		["\b"] = "\\b",
		["\t"] = "\\t",
		["\n"] = "\\n",
		["\v"] = "\\v",
		["\f"] = "\\f",
		["\r"] = "\\r",
	}
	return input:gsub("[%z\\\"\1-\31\127-\255]", function(s: string)
		return specialChars[s] and specialChars[s] or "\\" .. string.byte(s)
	end):gsub('"', "'")
end

function Serializer:removeDotZero(num: number): string
	num = string.format("%.2f", num)
	return num:match("%.00$") and num:gsub("%.00$", "") or num
end

function Serializer:formatNumber(num: number): string
	if num == math.huge then
		return "math.huge"
	elseif num == -math.huge then
		return "-math.huge"
	elseif num == 0/0 then
		return "0/0"
	elseif num == -0/0 then
		return "-0/0"
	end
	
	return num >= 2^63-1 and string.format("%.2e", num) or tostring(num) --string.format("%.2f", num)
end

function Serializer:isService(inst: Instance): boolean
	local success, result = pcall(function() 
		return game:FindService(inst.ClassName)
	end)
	return success
end

function Serializer:formatValue(val: any): string
	local valType: any = typeof(val)
	local valTypeCases: {[string]: (...any) -> (...any)} = {}
	
	valTypeCases["nil"] = function() 
		return "nil" 
	end
	
	valTypeCases["string"] = function() 
		return '"' .. self:formatString(val) .. '"'
	end
	
	valTypeCases["number"] = function()
		return self:formatNumber(val) 
	end
	
	valTypeCases["boolean"] = function() 
		return val and "true" or "false" 
	end
	
	valTypeCases["CFrame"] = function() 
		return string.format("CFrame.new(%f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f, %f)", val:GetComponents()) 
	end
	
	valTypeCases["Vector3"] = function() 
		return string.format("Vector3.new(%f, %f, %f)", val.X, val.Y, val.Z) 
	end
	
	valTypeCases["Vector2"] = function() 
		return string.format("Vector2.new(%f, %f)", val.X, val.Y) 
	end
	
	valTypeCases["Color3"] = function() 
		return string.format("Color3.new(%f, %f, %f)", val.R, val.G, val.B) 
	end
	
	valTypeCases["BrickColor"] = function() 
		return string.format("BrickColor.new('%s')", val.Name) 
	end
	
	valTypeCases["UDim2"] = function() 
		return string.format("UDim2.new(%f, %d, %f, %d)", val.X.Scale, val.X.Offset, val.Y.Scale, val.Y.Offset) 
	end
	
	valTypeCases["UDim"] = function() 
		return string.format("UDim.new(%f, %d)", val.Scale, val.Offset) 
	end
	
	valTypeCases["EnumItem"] = function() 
		return tostring(val)
	end
	
	valTypeCases["DateTime"] = function()
		return "DateTime.fromUnixTimestamp(" .. val.UnixTimestamp .. ")"
	end
	
	valTypeCases["NumberSequence"] = function()
		local keypoints = {}
		for _, keypoint in ipairs(val.Keypoints) do
			table.insert(keypoints, string.format("NumberSequenceKeypoint.new(%f, %f, %f)", keypoint.Time, keypoint.Value, keypoint.Envelope))
		end
		
		return string.format("NumberSequence.new({%s})", table.concat(keypoints, ", "))
	end
	
	valTypeCases["Instance"] = function() 
		if self:isService(val) then
			return string.format("game:GetService('%s')", self:formatString(val.ClassName))
		end
		
		local fullName = self:formatString(val:GetFullName())
		return fullName:find(" ") and fullName or fullName
	end
	
	--valTypeCases["function"] = function() 
	--	return self:serializeFunction(val, 1) .. " -- ???"
	--end
	
	return valTypeCases[valType] and valTypeCases[valType]() or self:formatString(tostring(val))
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

function Serializer:getFunctionArguments(func: (...any) -> (...any)): {string}
	local funcArgs: {string} = {}
	
	if getexecutorname ~= nil then
		local funcInfo: {} = debug.getinfo(func)
		if funcInfo.nups then
			for i = 1, funcInfo.nups do
				table.insert(funcArgs, "arg" .. i)
			end
		end

		if funcInfo.is_varang then
			table.insert(funcArgs, "...")
		end
	else
		local funcArgsNum: number = debug.info(func, "a")
		for i = 1, funcArgsNum do
			table.insert(funcArgs, "arg" .. i)
		end
	end
	
	return funcArgs
end

function Serializer:formatFunctionArguments(funcArgs: {string}): string
	return (funcArgs and #funcArgs > 0) and table.concat(funcArgs, ", ") or ""
end

function Serializer:serializeFunction(func: (...any) -> (...any), depth: number): string
	local funcLine: number = debug.info(func, "l")
	local funcName: string = debug.info(func, "n")
	local funcArgs: string = self:formatFunctionArguments(self:getFunctionArguments(func))
	
	local output: string = "function(" .. funcArgs .. ")"

	if self.Options.DebugFunctions then
		output ..= `\t-- Line Definied: {funcLine}, Function Name: {funcName ~= "" and funcName or "Anonymous Function"}`
		
		local debug_getconstants = debug.getconstants
		local debug_getupvalues = debug.getupvalues
		local debug_getprotos = debug.getprotos

		if debug_getconstants and debug_getupvalues and debug_getprotos then
			output ..= self:addTabSpaces("\n", depth)
			output ..= self:addTabSpaces("-- [[ Constants:", depth)

			for i, v in next, debug_getconstants(func) do
				output ..= self:addTabSpaces("\n", depth + 1)
				output ..= self:addTabSpaces(tostring(i) .. " = " .. tostring(v), depth)
			end
			
			output ..= self:addTabSpaces("]] --", depth)
			output ..= self:addTabSpaces("\n", depth)
			output ..= self:addTabSpaces("-- [[ Upvalues:", depth)

			for i, v in next, debug_getupvalues(func) do
				output ..= self:addTabSpaces("\n", depth + 1)
				output ..= self:addTabSpaces(tostring(i) .. " = " .. tostring(v), depth)
			end
			
			output ..= self:addTabSpaces("]] --", depth)
			output ..= self:addTabSpaces("\n", depth)
			output ..= self:addTabSpaces("--[[ Protos:", depth)

			for i, v in next, debug_getprotos(func) do
				output ..= self:addTabSpaces("\n", depth + 1)
				output ..= self:addTabSpaces(tostring(i) .. " = " .. tostring(v), depth)
			end
			
			output ..= self:addTabSpaces("\n", depth)
			output ..= self:addTabSpaces("]] --", depth)
		else
			output ..= self:addTabSpaces("\n", depth)
			output ..= self:addTabSpaces("-- DebugFunctions is not supported on your executor!", depth)
		end
	else
		output ..= self:addTabSpaces("\n", depth)
	end

	output ..= self:addTabSpaces("\n", depth)
	output ..= self:addTabSpaces("end", depth - 1)

	return output
end

function Serializer:serializeMetatable(input: (Array | Dictionary), depth: number): string

end

function Serializer:serializeTable(input: (Array | Dictionary), depth: number): string
	local output: {string} = {}
	depth = depth or 0
	
	for key: any, value: any in pairs(input) do
		local valType: any = typeof(value)
		local keyStr: string = self:addTabSpaces(string.format("[%s]", typeof(key) == "number" and tostring(key) or '"' .. tostring(key) .. '"') .. " = ", depth)

		if valType == "table" then
			local serializedTable: string = self:serializeTable(value, depth + 1)

			if serializedTable == "" or serializedTable == "\n" then
				keyStr ..= "{},"
			else
				keyStr ..= "{" .. "\n" .. serializedTable .. "\n" .. self:addTabSpaces("},", depth)
			end
		elseif valType == "function" then
			keyStr ..= self:serializeFunction(value, depth + 1) .. ","
		else
			keyStr ..= self:formatValue(value) .. "," 
		end

		if self.Options.DebugTypes then
			keyStr ..= " --" .. tostring(typeof(key)) .. ", " .. tostring(typeof(value))
		end

		table.insert(output, keyStr)
	end

	return table.concat(self:removeEmptyStrings(output), "\n")
end

return function(options: Options?)
	local self = setmetatable({}, Serializer)
	
	self.Options = options or {
		DebugFunctions = false,
		DebugTypes = true,
		ReadMetatables = true,
	}::Options

	return {
		serializeJSON = function(input)
			local success, result = pcall(function() 
				return game:GetService("HttpService"):JSONDecode(input)
			end)
			assert(success, result)
			return Watermark .. "\nreturn {\n" .. self:serializeTable(result, 1) .. "\n}"
		end,

		serializeTable = function(input)
			assert(typeof(input) == "table", "The first argument in serializeTable must be a Table!")
			return Watermark .. "\nreturn {\n" .. self:serializeTable(input, 1) .. "\n}"
		end
	}
end
