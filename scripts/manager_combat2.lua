function onInit()
	oAddNPC = CombatManager.getCustomAddNPC();
	CombatManager.setCustomAddNPC(addNPC);
	CombatManager2.rollRandomInit = rollRandomInit;
end

function addNPC(sClass, nodeNPC, sName)
	nodeEntry = oAddNPC(sClass, nodeNPC, sName);
	
	---TODO: account for group addition of NPC
	-- local sOptINIT = OptionsManager.getOption("INIT");
	-- if sOptINIT == "group" then
	-- 	if nodeLastMatch then
	-- 		local nLastInit = DB.getValue(nodeLastMatch, "initresult", 0);
	-- 		DB.setValue(nodeEntry, "initresult", "number", nLastInit);
	-- 	else
	-- 		DB.setValue(nodeEntry, "initresult", "number", math.random(10) + DB.getValue(nodeEntry, "init", 0));
	-- 	end
	-- elseif sOptINIT == "on" then
	local nDexMod = DB.getValue(nodeNPC, "abilities.dexterity.score", 0);
	DB.setValue(nodeEntry, "init", "number", nDexMod);
		DB.setValue(nodeEntry, "initresult", "number", math.random(10) + DB.getValue(nodeEntry, "init", 0));
	-- end

	transformScore(nodeEntry, "strength");
	transformScore(nodeEntry, "dexterity");
	transformScore(nodeEntry, "constitution");
	transformScore(nodeEntry, "intelligence");
	transformScore(nodeEntry, "wisdom");
	transformScore(nodeEntry, "charisma");
    return nodeEntry;
end

---Converts score from 5E to SE
---@param nodeEntry any nodeEntry from parent function
---@param sAbility any full string name of ability to transform from 5E to SE
function transformScore(nodeEntry, sAbility)
	if DB.getValue(nodeEntry, "abilities." .. sAbility .. ".score", 0) ~= DB.getValue(nodeEntry, "abilities." .. sAbility .. ".bonus", 0) then
		local origValue = DB.getValue(nodeEntry, "abilities." .. sAbility .. ".score", 0);
		DB.setValue(nodeEntry, "abilities." .. sAbility .. ".score", "number",math.floor((origValue-10)/2));
	end
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