function onInit()
	CombatManager2.rollRandomInit = rollRandomInit;
end

function rollRandomInit(nMod, bADV, bDIS)
	local nInitResult = math.random(10);
	if bADV and not bDIS then
		nInitResult = math.max(nInitResult, math.random(10));
	elseif bDIS and not bADV then
		nInitResult = math.min(nInitResult, math.random(10));
	end
	nInitResult = nInitResult + nMod;
	return nInitResult;
end