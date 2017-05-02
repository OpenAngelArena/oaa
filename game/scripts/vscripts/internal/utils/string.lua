function string.starts(s, start)
	return string.sub(s, 1, string.len(start)) == start
end

function string.ends(s, e)
	return e == "" or string.sub(s, -string.len(e)) == e
end

function string.split(inputstr, sep)
	local t = {}
	for str in string.gmatch(inputstr, "([^" .. (sep or "%s") .. "]+)") do
		table.insert(t, str)
	end
	return t
end