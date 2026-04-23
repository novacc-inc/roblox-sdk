--!strict
local Utility = {}

--[[
	Converts a camelCase or PascalCase string to snake_case.
]]
function Utility.toSnakeCase(str: string): string
	local snakeCase = str
		-- Split acronym boundaries first: "HTTPServer" -> "HTTP_Server"
		:gsub("(%u)(%u%l)", "%1_%2")
		-- Split standard camelCase boundaries: "gamePulse" -> "game_Pulse"
		:gsub("([%l%d])(%u)", "%1_%2")

	return snakeCase:lower()
end

--[[
	Recursively converts all keys in a table from camelCase/PascalCase to snake_case.
]]
function Utility.objectToSnakeCase(obj: any): any
	if typeof(obj) ~= "table" then
		return obj
	end

	local newObj = {}
	for key, value in obj do
		local snakeKey = Utility.toSnakeCase(key)
		newObj[snakeKey] = Utility.objectToSnakeCase(value)
	end

	return newObj
end

return Utility
