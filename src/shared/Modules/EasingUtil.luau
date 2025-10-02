local module = {}

function module.lerp(a,b,t)
	return a + (b-a) * t
end

function module.linearIn(a,b,totalframe)
	local tab = {}
	for i = 1,totalframe do
		x = i/totalframe
		local t = x
		table.insert(tab, module.lerp(a,b,t))
		task.wait()
	end
	return tab
end
--[[ QUADS ]]
function module.quadIn(a,b,totalframe)
	local tab = {}
	for i = 1,totalframe do
		x = i/totalframe
		local t = x * x
		table.insert(tab, module.lerp(a,b,t))
	end
	return tab
end
function module.quadOut(a,b,totalframe)
	local tab = {}
	for i = 1,totalframe do
		x = i/totalframe
		local t = 1 - (1 - x) * (1 - x)
		table.insert(tab, module.lerp(a,b,t))
	end
	return tab
end
function module.quadInOut(a,b,totalframe)
	local tab = {}
	for i = 1,totalframe do
		x = i/totalframe
		local t
		if x < 0.5 then
			t = 2 * x * x
		else
			t = 1 - math.pow(-2 * x + 2, 2) / 2
		end
		table.insert(tab, module.lerp(a,b,t))
	end
	return tab
end

--[[ SINE ]]
function module.sineIn(a,b,totalframe)
	local tab = {}
	for i = 1,totalframe do
		x = i/totalframe
		local t = 1 - math.cos((x * math.pi) / 2)
		table.insert(tab, module.lerp(a,b,t))
	end
	return tab
end
function module.sineOut(a,b,totalframe)
	local tab = {}
	for i = 1,totalframe do
		x = i/totalframe
		local t = math.sin((x * math.pi) / 2)
		table.insert(tab, module.lerp(a,b,t))
	end
	return tab
end
function module.sineInOut(a,b,totalframe)
	local tab = {}
	for i = 1,totalframe do
		x = i/totalframe
		local t = -(math.cos(math.pi * x) - 1) / 2
		table.insert(tab, module.lerp(a,b,t))
	end
	return tab
end

--[[ QUINT ]]
function module.quintIn(a,b,totalframe)
	local tab = {}
	for i = 1,totalframe do
		x = i/totalframe
		local t = x * x * x * x * x
		table.insert(tab, module.lerp(a,b,t))
	end
	return tab
end
function module.quintout(a,b,totalframe)
	local tab = {}
	for i = 1,totalframe do
		x = i/totalframe
		local t = 1 - math.pow(1 - x, 5)
		table.insert(tab, module.lerp(a,b,t))
	end
	return tab
end
function module.quintinout(a,b,totalframe)
	local tab = {}
	for i = 1,totalframe do
		x = i/totalframe
		local t
		if x < 0.5 then
			t = 16 * x * x * x * x * x
		else
			t = 1 - math.pow(-2 * x + 2, 5) / 2
		end
		table.insert(tab, module.lerp(a,b,t))
	end
	return tab
end


--[[ Exponential ]]
function module.expoin(a,b,totalframe)
	local tab = {}
	for i = 1,totalframe do
		x = i/totalframe
		local t
		if x == 0 then
			t = 0
		else
			t = math.pow(2, 10 * x - 10)
		end
		table.insert(tab, module.lerp(a,b,t))
	end
	return tab
end
function module.expoout(a,b,totalframe)
	local tab = {}
	for i = 1,totalframe do
		x = i/totalframe
		local t
		if x == 1 then
			t = 1
		else
			t = 1 - math.pow(2, -10 * x)
		end
		table.insert(tab, module.lerp(a,b,t))
	end
	return tab
end
function module.expoinout(a,b,totalframe)
	local tab = {}
	for i = 1,totalframe do
		x = i/totalframe
		local t
		if x == 1 then
			t = 1
		elseif x == 0 then
			t = 0
		elseif x < 0.5 then
			t = math.pow(2, 20 * x - 10) / 2
		else
			t = (2 - math.pow(2, -20 * x + 10)) / 2
		end
		table.insert(tab, module.lerp(a,b,t))
	end
	return tab
end


--[[ Circle ]]
function module.circin(a,b,totalframe)
	local tab = {}
	for i = 1,totalframe do
		x = i/totalframe
		local t = 1 - math.sqrt(1 - math.pow(x, 2))
		table.insert(tab, module.lerp(a,b,t))
	end
	return tab
end
function module.circout(a,b,totalframe)
	local tab = {}
	for i = 1,totalframe do
		x = i/totalframe
		local t = math.sqrt(1 - math.pow(x - 1, 2))
		table.insert(tab, module.lerp(a,b,t))
	end
	return tab
end
function module.circinout(a,b,totalframe)
	local tab = {}
	for i = 1,totalframe do
		x = i/totalframe
		local t
		if x < 0.5 then
			t = (1 - math.sqrt(1 - math.pow(2 * x, 2))) / 2
		else
			t = (math.sqrt(1 - math.pow(-2 * x + 2, 2)) + 1) / 2
		end
		table.insert(tab, module.lerp(a,b,t))
	end
	return tab
end

--[[ Back ]]
function module.backin(a,b,totalframe)
	local tab = {}
	local c1,c3 = 1.70158,1 + 1.70158
	for i = 1,totalframe do
		x = i/totalframe
		local t = c3 * x * x * x - c1 * x * x
		table.insert(tab, module.lerp(a,b,t))
	end
	return tab
end
function module.backout(a,b,totalframe)
	local tab = {}
	local c1,c3 = 1.70158,1 + 1.70158
	for i = 1,totalframe do
		x = i/totalframe
		local t = 1 + c3 * math.pow(x - 1, 3) + c1 * math.pow(x - 1, 2)
		table.insert(tab, module.lerp(a,b,t))
	end
	return tab
end
function module.backinout(a,b,totalframe)
	local tab = {}
	local c1,c2 = 1.70158,1.525 * 1.70158
	for i = 1,totalframe do
		x = i/totalframe
		local t
		if x < 0.5 then
			t = (math.pow(2 * x, 2) * ((c2 + 1) * 2 * x - c2)) / 2
		else
			t = (math.pow(2 * x - 2, 2) * ((c2 + 1) * (x * 2 - 2) + c2) + 2) / 2
		end
		table.insert(tab, module.lerp(a,b,t))
	end
	return tab
end

--[[ Elastic ]]
function module.elasticin(a,b,totalframe)
	local tab = {}
	local c4 = (2 * math.pi) / 3
	for i = 1,totalframe do
		x = i/totalframe
		local t
		if x == 0 then
			t = 0
		elseif x == 1 then
			t = 1
		else
			t = -math.pow(2, 10 * x - 10) * math.sin((x * 10 - 10.75) * c4)
		end
		table.insert(tab, module.lerp(a,b,t))
	end
	return tab
end
function module.elasticout(a,b,totalframe)
	local tab = {}
	local c4 = (2 * math.pi) / 3
	for i = 1,totalframe do
		x = i/totalframe
		local t
		if x == 0 then
			t = 0
		elseif x == 1 then
			t = 1
		else
			t = math.pow(2, -10 * x) * math.sin((x * 10 - 0.75) * c4) + 1
		end
		table.insert(tab, module.lerp(a,b,t))
	end
	return tab
end
function module.elasticinout(a,b,totalframe)
	local tab = {}
	local c5 = (2 * math.pi) / 4.5
	for i = 1,totalframe do
		x = i/totalframe
		local t
		if x == 0 then
			t = 0
		elseif x == 1 then
			t = 1
		elseif x < 0.5 then
			t = -(math.pow(2, 20 * x - 10) * math.sin((20 * x - 11.125) * c5)) / 2
		else
			t = (math.pow(2, -20 * x + 10) * math.sin((20 * x - 11.125) * c5)) / 2 + 1
		end
		table.insert(tab, module.lerp(a,b,t))
	end
	return tab
end

--[[ Bounce ]]
function module.outbouncecalc(x)
	local n1,d1 = 7.5625,2.75
	if x < 1 / d1 then
		return n1 * x * x
	elseif x < 2 / d1 then
		local x2 = x - 1.5
		return n1 * (x2 / d1) * x + 0.75
	elseif x < 2.5 / d1 then
		local x2 = x - 2.25
		return n1 * (x2 / d1) * x + 0.9375
	else
		local x2 = x - 2.625
		return n1 * (x2 / d1) * x + 0.984375
	end
end
function module.bouncein(a,b,totalframe)
	local tab = {}
	for i = 1,totalframe do
		x = i/totalframe
		local t = 1 - module.outbouncecalc(1 - x)
		table.insert(tab, module.lerp(a,b,t))
	end
	return tab
end
function module.bounceout(a,b,totalframe)
	local tab = {}
	local n1,d1 = 7.5625,2.75
	for i = 1,totalframe do
		x = i/totalframe
		local t
		if x < 1 / d1 then
			t = n1 * x * x
		elseif x < 2 / d1 then
			local x2 = x - 1.5
			t = n1 * (x2 / d1) * x + 0.75
		elseif x < 2.5 / d1 then
			local x2 = x - 2.25
			t = n1 * (x2 / d1) * x + 0.9375
		else
			local x2 = x - 2.625
			t = n1 * (x2 / d1) * x + 0.984375
		end
		table.insert(tab, module.lerp(a,b,t))
	end
	return tab
end
function module.bounceinout(a,b,totalframe)
	local tab = {}
	for i = 1,totalframe do
		x = i/totalframe
		local t
		if x < 0.5 then
			t = (1 - module.outbouncecalc(1 - 2 * x)) / 2
		else
			t = (1 + module.outbouncecalc(2 * x - 1)) / 2
		end
		table.insert(totalframe,t)
	end
	return tab
end

return module
