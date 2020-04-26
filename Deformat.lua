local lib = LibStub:NewLibrary("HH-Deformat", 1)

local temp_list, template = {},
[[local string_match = string.match
return function(message)
	local pcall_status, m1, m2, m3, m4, m5 = pcall(string_match, message, [=[^%s$]=])
	assert(pcall_status, "Error deformatting message", message, [=[^%s$]=], m1)
	return %s
end]]

-- Return a inverted match string and corresponding list of ordered match slots (m1-m5)
local match, gsub = string.match, string.gsub
local function invert(pattern)
	local inverted, arglist = pattern
	-- Escape magic characters
	inverted = gsub(inverted, "%(", "%%(")
	inverted = gsub(inverted, "%)", "%%)")
	inverted = gsub(inverted, "%-", "%%-")
	inverted = gsub(inverted, "%+", "%%+")
	inverted = gsub(inverted, "%.", "%%.")
	-- Account for reordered replacements
	local k = match(inverted, '%%(%d)%$')
	if k then
		local i, list = 1, wipe(temp_list)
		while k ~= nil do
			inverted = gsub(inverted, "(%%%d%$.)", "(.-)", 1)
			list[i] = 'm'..tostring(k)
			k, i = match(inverted, "%%(%d)%$"), i + 1
		end
		arglist = table.concat(list, ", ")
	-- Simple patterns
	else
		inverted = gsub(inverted, "%%d", "(%%d+)")
		inverted = gsub(inverted, "%%s", "(.-)")
		arglist = "m1, m2, m3, m4, m5"
	end
	return inverted, arglist
end

-- Match string against a pattern, caching the inverted pattern
local invert_cache = {}
function lib.Deformat(str, pattern)
	local func = invert_cache[pattern]
	if not func then
		local inverted, arglist = invert(pattern)
		func = loadstring(template:format(inverted, inverted, arglist))()
		invert_cache[pattern] = func
	end
	return func(str)
end
