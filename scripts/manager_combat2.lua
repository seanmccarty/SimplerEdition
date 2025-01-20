function onInit()
	CombatManager2.rollRandomInit = rollRandomInit;
end

function rollRandomInit(tInit)
	local tSuffix = {};
	if (tInit.nMod or 0) ~= 0 then
		table.insert(tSuffix, string.format("(%+d)", tInit.nMod));
	end

	local nInitResult = math.random(10);
	if tInit.bADV and not tInit.bDIS then
		local nInitResult2 = math.random(20);
		table.insert(tSuffix, string.format("[ADV] (DROPPED %d)", math.min(nInitResult, nInitResult2)));
		nInitResult = math.max(nInitResult, nInitResult2);
	elseif tInit.bDIS and not tInit.bADV then
		local nInitResult2 = math.random(20);
		table.insert(tSuffix, string.format("[DIS] (DROPPED %d)", math.max(nInitResult, nInitResult2)));
		nInitResult = math.min(nInitResult, nInitResult2);
	end
	tInit.sSuffix = table.concat(tSuffix, " ");

	return nInitResult + (tInit.nMod or 0);
end