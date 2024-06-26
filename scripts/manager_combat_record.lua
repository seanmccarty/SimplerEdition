function onInit()
	CombatRecordManager.setRecordTypePostAddCallback("npc",addNPC);
	CombatRecordManager.setRecordTypePostAddCallback("vehicle",addVehicle);
	CombatRecordManager.handleCombatAddInitDnD = handleCombatAddInitDnD;
end

function addNPC(tCustom)
	
	if not tCustom.nodeRecord or not tCustom.nodeCT then
		return;
	end

	transformScore(tCustom.nodeCT, "strength");
	transformScore(tCustom.nodeCT, "dexterity");
	transformScore(tCustom.nodeCT, "constitution");
	transformScore(tCustom.nodeCT, "intelligence");
	transformScore(tCustom.nodeCT, "wisdom");
	transformScore(tCustom.nodeCT, "charisma");

	CombatManager2.onNPCPostAdd(tCustom);
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
	local nDexMod = DB.getValue(tCustom.nodeCT, "abilities.dexterity.score", 0);
	DB.setValue(tCustom.nodeCT, "init", "number", nDexMod);
		--DB.setValue(tCustom.nodeCT, "initresult", "number", math.random(10) + DB.getValue(tCustom.nodeCT, "init", 0));
	-- end
	CombatRecordManager.handleCombatAddInitDnD(tCustom);
	return true;
end

function addVehicle(tCustom)
	if not tCustom.nodeRecord or not tCustom.nodeCT then
		return;
	end

	transformScore(tCustom.nodeCT, "strength");
	transformScore(tCustom.nodeCT, "dexterity");
	transformScore(tCustom.nodeCT, "constitution");
	transformScore(tCustom.nodeCT, "intelligence");
	transformScore(tCustom.nodeCT, "wisdom");
	transformScore(tCustom.nodeCT, "charisma");

	CombatManager2.onVehiclePostAdd(tCustom);

	local nDexMod = DB.getValue(tCustom.nodeCT, "abilities.dexterity.score", 0);
	DB.setValue(tCustom.nodeCT, "init", "number", nDexMod);
	CombatRecordManager.handleCombatAddInitDnD(tCustom);
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

function handleCombatAddInitDnD(tCustom)
	local sOptINIT = OptionsManager.getOption("INIT");
	local nInit;
	
	if sOptINIT == "group" then
		if tCustom.nodeCTLastMatch then
			nInit = DB.getValue(tCustom.nodeCTLastMatch, "initresult", 0);
		else
			nInit = math.random(10) + DB.getValue(tCustom.nodeCT, "init", 0);
		end
	elseif sOptINIT == "on" then
		nInit = math.random(10) + DB.getValue(tCustom.nodeCT, "init", 0);
	else
		return;
	end
	DB.setValue(tCustom.nodeCT, "initresult", "number", nInit);
end