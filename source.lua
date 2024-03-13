local function serializeTable(_table: {any}, depth: number): string
	local output: {string} = {}
	depth = depth or 0

	local function addTabSpace(str: string, depth: number): string
		depth = depth or 0
		str = string.rep("\t", depth) .. str 
		return str
	end

	for key, value in pairs(_table) do
		if typeof(value) == "table" then
			key = ((typeof(key) == "string" and "['" .. key .. "']") or (typeof(key) == "number" and "[" .. key .. "]")) or key

			table.insert(output, addTabSpace(key .. " = { --" .. typeof(key) .. ", " .. typeof(value), depth))
			table.insert(output, serializeTable(value, depth + 1))
			table.insert(output, addTabSpace("},", depth))
		elseif typeof(value) == "function" then
			key = ((typeof(key) == "string" and "['" .. key .. "']") or (typeof(key) == "number" and "[" .. key .. "]")) or key

			local function formatArguments()
				local arguments = {}
				
				if debug and debug.getinfo then
					for i = 1, debug.getinfo(value)["numparams"] do
						table.insert(arguments, "arg" .. i)
					end

					if debug.getinfo(value)["is_vararg"] > 0 then
						table.insert(arguments, "...")
					end
				end

				return table.concat(arguments, ", ")
			end

			table.insert(output, addTabSpace(key .. " = function(" .. formatArguments() .. ") --" .. typeof(key) .. ", " .. typeof(value), depth))
			table.insert(output, addTabSpace("", depth))
			table.insert(output, addTabSpace("end,", depth))
		else
			key = ((typeof(key) == "string" and "['" .. key .. "']") or (typeof(key) == "number" and "[" .. key .. "]")) or key
			value = typeof(value) == "string" and "'" .. value .. "'" or value

			table.insert(output, addTabSpace(key .. " = " .. tostring(value) .. ", --" .. typeof(key) .. ", " .. typeof(value), depth))
		end
	end

	return table.concat(output, "\n")
end

return serializeTable
