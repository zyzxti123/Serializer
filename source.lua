-- ▼ 
-- ▶ 

local m = {}
m.__index = m

function m:AddTabSpaces(_string: string, depth: number): string
	depth = depth or 0

	if depth > 0 then
		return string.rep("\t", depth) .. _string
	end

	return _string
end

function m:HasReturn(_function): boolean
	local info = debug.getinfo(_function, "u")
	return info and info.nups > 0
end

function m:GetArguments(_function): {string}
	local arguments: {string} = {}

	for key = 1, debug.getinfo(_function)["numparams"] do
		table.insert(arguments, "arg" .. key)
	end

	if debug.getinfo(_function)["is_vararg"] > 0 then
		table.insert(arguments, "...")
	end

	return arguments
end

function m:FormatArguments(arguments): string
	if arguments == nil or #arguments <= 0 then return end
	return table.concat(arguments, ", ")
end

function m:serializeTable(input: any, depth: number): string
	local self = setmetatable({}, m)

	self.output = {}
	self.depth = depth or 0

	if typeof(input) == "table" then
		for key, value in pairs(input) do
			if typeof(value) == "table" then
				local keyType, valueType = typeof(key), typeof(value)
				
				if typeof(key) == "string" or typeof(key) == "number" then 
					key = string.format("[%s]", string.format("%q", key))
				else
					key = string.format("[%s]", tostring(key))
				end
				
				table.insert(self.output, self:AddTabSpaces(string.format("%s =  ▼  { --%s, %s", key, keyType, valueType), self.depth))
				table.insert(self.output, self:serializeTable(value, self.depth + 1))
				table.insert(self.output, self:AddTabSpaces("},", self.depth))
			elseif typeof(value) == "function" then
				local keyType, valueType = typeof(key), typeof(value)
				if typeof(key) == "string" or typeof(key) == "number" then 
					key = string.format("[%s]", string.format("%q", key))
				else
					key = string.format("[%s]", tostring(key))
				end
				
				table.insert(self.output, self:AddTabSpaces(string.format("%s = %s, --%s, %s", key, self:serializeTable(value), keyType, valueType), self.depth))
			else
				local keyType, valueType = typeof(key), typeof(input)
				if typeof(key) == "string" or typeof(key) == "number" then 
					key = string.format("[%s]", string.format("%q", key))
				else
					key = string.format("[%s]", tostring(key))
				end
				
				value = typeof(value) == "string" and string.format("'%s'", value) or value
				
				table.insert(self.output, self:AddTabSpaces(string.format("%s = %s, --%s, %s", key, tostring(value), keyType, valueType), self.depth))
			end
		end
	elseif typeof(input) == "function" then
		local arguments: {any} = (debug and debug.getinfo) and self:GetArguments(input) or {}
		
		local key = (debug and debug.getinfo) and debug.getinfo(input).name or ""
		local keyType, inputType = typeof(key), typeof(input)
		
		--if typeof(key) == "string" or typeof(key) == "number" then 
		--	key = string.format("[%s]", string.format("%q", key))
		--else
		--	key = string.format("[%s]", tostring(key))
		--end
		
		table.insert(self.output, self:AddTabSpaces(string.format("function %s(%s) --%s", key, (self:FormatArguments(arguments) or ""), inputType), self.depth))

		if ((debug and debug.getinfo) and self:HasReturn(input)) then 
			table.insert(self.output, "")
		end

		table.insert(self.output, self:AddTabSpaces("end", self.depth))
		--table.insert(self.output, self:AddTabSpaces(string.format("return %s", key), self.depth)) 
	else
		table.insert(self.output, string.format("%s --%s", tostring(input), tostring(typeof(input))))
	end
	
	return table.concat(self.output, "\n") --"  ▼  {\n" .. table.concat(self.output, "\n") .. "\n}"
end

function serializeTable(...)
	local varargs = {...}
	return m:serializeTable(table.unpack(varargs))
end

return serializeTable
