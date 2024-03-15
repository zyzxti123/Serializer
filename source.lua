local m = {}
m.__index = m

function m:AddTabSpaces(_string: string, depth: number): string
	depth = depth or 0
	return string.rep("\t", depth) .. _string
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
	return table.concat(arguments, ", ")
end

function m:GetConstants(_function): {any}
	local constants: {any} = {}

	for key, value in pairs(debug.getconstants(_function)) do
		constants[key] = value
	end

	return constants
end

function m:FormatConstants(constants: {any}): string
	local _constants: string = ""

	for key, value in pairs(constants) do
		table.insert(_constants, self:AddTabSpaces(string.format("%s = %s --%s, %s", tostring(key), tostring(value), tostring(typeof(key)), tostring(typeof(value))), self.depth + 1))
	end

	return table.concat(_constants, "\n")
end

function m:GetUpvalues(_function)
	local upvalues = {}

	for key, value in pairs(debug.getupvalues(_function)) do
		upvalues[key] = value
	end

	return upvalues
end

function m:FormatUpvalues(upvalues: {any}): string
	local _upvalues: string = {}
	local _debugInfo = {}

	for key, value in pairs(_upvalues) do
		table.insert(_upvalues, self:AddTabSpaces(string.format("%s = %s --%s, %s", tostring(key), tostring(value), tostring(typeof(key)), tostring(typeof(value))), self.depth + 1))
	end

	return table.concat(_upvalues, "\n")
end

function m:GetProtos(_function): {any}
	local protos: {any} = {}

	for index in ipairs(debug.getprotos(_function)) do
		protos[index] = debug.getproto(_function, index, true)[1]
	end

	return protos
end

function m:FormatProtos(protos: {any}): string
	local _protos = protos or self:GetProtos()

	--TODO

	return _protos
end

function m:serializeTable(input: any, depth: number): string
	warn(input)	

	local self = setmetatable({}, m)

	self.output = {}
	self.depth = depth or 0

	if typeof(input) == "table" then
		for key, value in pairs(input) do
			if typeof(value) == "table" then
				key = ((typeof(key) == "string" and string.format("['%s']", key) or (typeof(key) == "number" and string.format("[%s]", key)))) or key
				table.insert(self.output, self:AddTabSpaces(string.format("%s = { --%s, %s", key, typeof(key), typeof(value)), self.depth))
				table.insert(self.output, self:serializeTable(value, self.depth + 1))
				table.insert(self.output, self:AddTabSpaces("},", self.depth))
			elseif typeof(value) == "function" then
				key = ((typeof(key) == "string" and string.format("['%s']", key) or (typeof(key) == "number" and string.format("[%s]", key)))) or key
				local constants: {any} = (debug and debug.getconstants) and self:GetConstants(value) or {}
				local upvalues: {any} = (debug and debug.getupvalues) and self:GetUpvalues(value) or {}
				--local protos: {any} = (debug and debug.getprotos) and self:GetProtos() or {}
				local arguments: {any} = (debug and debug.getinfo) and self:GetArguments(value) or {}

				table.insert(self.output, self:AddTabSpaces(string.format("%s = function(%s) --%s", key, self:FormatArguments(arguments) or "", typeof(value)), self.depth))

				if #constants > 0 then
					table.insert(self.output, "")
					table.insert(self.output, self:AddTabSpaces("-- Constants --", depth + 1))
					table.insert(self.output, self:FormatConstants(constants))
				end

				if #upvalues > 0 then
					table.insert(self.output, "")
					table.insert(self.output, self:AddTabSpaces("-- Upvalues --", depth + 1))
					table.insert(self.output, self:FormatConstants(upvalues))
				end

				if (debug and debug.getinfo) and self:HasReturn() then 
					table.insert(self.output, self:AddTabSpaces("return", self.depth + 1))
				else
					table.insert(self.output, "\n")
				end

				table.insert(self.output, self:AddTabSpaces("end", self.depth))
			else
				--key = ((typeof(key) == "string" and string.format("['%s']", key)) and (typeof(key) == "number" and string.format("[%s]", key))) or key
				key = ((typeof(key) == "string" and string.format("['%s']", key) or (typeof(key) == "number" and string.format("[%s]", key)))) or key
				value = typeof(value) == "string" and string.format("'%s'", value) or value
				table.insert(self.output, self:AddTabSpaces(string.format("%s = %s, --%s, %s", key, tostring(value), typeof(key), typeof(value)), depth))
			end
		end 
	elseif typeof(input) == "function" then
		local constants: {any} = (debug and debug.getconstants) and self:GetConstants(input) or {}
		local upvalues: {any} = (debug and debug.getupvalues) and self:GetUpvalues(input) or {}
		--local protos: {any} = (debug and debug.getprotos) and self:GetProtos(input) or {}
		local arguments: {any} = (debug and debug.getinfo) and self:GetArguments(input) or {}

		table.insert(self.output, self:AddTabSpaces(string.format("return function(%s) --%s", self:FormatArguments(arguments) or "", typeof(input)), self.depth))

		if #constants > 0 then
			table.insert(self.output, "")
			table.insert(self.output, self:AddTabSpaces("-- Constants --", depth + 1))
			table.insert(self.output, self:FormatConstants(constants))
		end

		if #upvalues > 0 then
			table.insert(self.output, "")
			table.insert(self.output, self:AddTabSpaces("-- Upvalues --", depth + 1))
			table.insert(self.output, self:FormatConstants(upvalues))
		end

		if (debug and debug.getinfo) and self:HasReturn() then 
			table.insert(self.output, self:AddTabSpaces("return", self.depth + 1)) 
		else
			table.insert(self.output, "\n")
		end

		table.insert(self.output, self:AddTabSpaces("end", self.depth))
	else
		table.insert(self.output, string.format("%s --%s", tostring(input), tostring(typeof(input))))
	end

	return table.concat(self.output, "\n")
end

function serializeTable(...)
	return m:serializeTable(...)
end

return serializeTable
