function table.removeByValue(t, value)
	for i,v in pairs(t) do
		if v == value then
			table.remove(t, i)
		end
	end
end

function table.swap(array, index1, index2)
	array[index1], array[index2] = array[index2], array[index1]
end

function table.shuffle(array)
	local counter = #array
	while counter > 1 do
		local index = RandomInt(1, counter)
		table.swap(array, index, counter)
		counter = counter - 1
	end
end

function table.contains(table, element)
	if table then
		for _, value in pairs(table) do
			if value == element then
				return true
			end
		end
	end
	return false
end

function table.firstNotNil(table)
	for _,v in pairs(table) do
		if v ~= nil then
			return v
		end
	end
end

function table.allEqual(table, value)
	for _,v in pairs(table) do
		if v ~= value then
			return false
		end
	end
	return true
end

function table.areAllEqual(table)
	for _,v in pairs(table) do
		if value == nil then
			value = v
		end
		if v ~= value then
			return false
		end
	end
	return true
end

function table.allEqualExpectOne(table, value)
	local miss = false
	for _,v in pairs(table) do
		if v ~= value then
			if miss then
				return false
			else
				miss = true
			end
		end
	end
	return true
end

function table.iterate(inputTable)
	local toutput = {}
	for _,v in pairs(inputTable) do
		table.insert(toutput, v)
	end
	return toutput
end

function table.iterateKeys(inputTable)
	local toutput = {}
	for k,_ in pairs(inputTable) do
		table.insert(toutput, k)
	end
	return toutput
end

function table.count(inputTable)
	local counter = 0
	for _,_ in pairs(inputTable) do
		counter = counter + 1
	end
	return counter
end

function table.merge(input1, input2)
	for i,v in pairs(input2) do
		input1[i] = v
	end
end

function table.highest(t)
	if #t < 1 then
		return
	end
	table.sort(t)
	return(t[#t])
end

function table.findIndex(t, value)
	local values = {}
	for i,v in ipairs(t) do
		if v == value then
			table.insert(values, i)
		end
	end
	return values
end

function table.icontains(table, element)
	for _, value in ipairs(table) do
		if value == element then
			return true
		end
	end
	return false
end

function table.add(input1, input2)
	for _,v in ipairs(input2) do
		table.insert(input1, v)
	end
end

function table.addExclusive(input1, input2)
	for _,v in ipairs(input2) do
		if not table.contains(input1, v) then
			table.insert(input1, v)
		end
	end
end

function table.nearest(table, number)
	local smallestSoFar, smallestIndex
	for i, y in ipairs(table) do
		if not smallestSoFar or (math.abs(number-y) < smallestSoFar) then
			smallestSoFar = math.abs(number-y)
			smallestIndex = i
		end
	end
	return table[smallestIndex], smallestIndex
end

function table.nearestKey(t, key)
	if not t then return end
	local selectedKey
	for k,v in pairs(t) do
		if not selectedKey or math.abs(k - key) < math.abs(selectedKey - key) then
			selectedKey = k
		end
	end
	return t[selectedKey]
end

function table.nearestOrLowerKey(t, key)
	if not t then return end
	local selectedKey
	for k,v in pairs(t) do
		if k <= key and (not selectedKey or math.abs(k - key) < math.abs(selectedKey - key)) then
			selectedKey = k
		end
	end
	return t[selectedKey]
end

function table.deepmerge(t1, t2)
	for k,v in pairs(t2) do
		if type(v) == "table" then
			if type(t1[k] or false) == "table" then
				tableMerge(t1[k] or {}, t2[k] or {})
			else
				t1[k] = v
			end
		else
			t1[k] = v
		end
	end
	return t1
end

function table.deepcopy(obj, seen)
	if type(obj) ~= 'table' then return obj end
	if seen and seen[obj] then return seen[obj] end
	local s = seen or {}
	local res = setmetatable({}, getmetatable(obj))
	s[obj] = res
	for k, v in pairs(obj) do res[table.deepcopy(k, s)] = table.deepcopy(v, s) end
	return res
end

function pairsByKeys(t, f)
	local a = {}
	for n in pairs(t) do table.insert(a, n) end
	table.sort(a, f)
	local i = 0
	local iter = function()
		i = i + 1
		if a[i] == nil then
			return nil
		else
			return a[i], t[a[i]]
		end
	end
	return iter
end
