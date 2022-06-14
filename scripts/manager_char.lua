function onInit()
	CharManager.addSkill = addSkill;
	CharManager.resetHealth = resetHealth;
	CharManager.onSkillSelect = onSkillSelect;
end

function onSkillSelect(aSelection, rSkillAdd)
	-- For each selected skill, add it to the character
	for _,sSkill in ipairs(aSelection) do
		addSimpleSkillDB(rSkillAdd.nodeChar, sSkill, rSkillAdd.nProf or 1);
	end
end

function addSkills(nodeChar, aSkills)
	-- Check for empty or missing skill list, then use full list
	if not aSkills then 
		aSkills = {}; 
	end
	if #aSkills == 0 then
		for k,_ in pairs(DataCommon.skilldata) do
			table.insert(aSkills, k);
		end
		table.sort(aSkills);
	end
		
	-- Add links (if we can find them)
	for k,v in ipairs(aSkills) do
		local rSkillData = DataCommon.skilldata[v];
		if rSkillData then
			local rSkill = { text = v, linkclass = "", linkrecord = "" };
			local nodeSkill = RecordManager.findRecordByStringI("skill", "name", v);
			if nodeSkill then
				rSkill.linkclass = "reference_skill";
				rSkill.linkrecord = DB.getPath(nodeSkill);
			end
			aSkills[k] = rSkill;
		end
	end
	
	for k,v in ipairs(aSkills) do
		SECharManager.addSimpleSkillDB(nodeChar,v.text, v.linkclass, v.linkrecord)
	end
end

function addSimpleSkill(nodeChar, sSkill)
	local rSkillData = DataCommon.skilldata[sSkill];
	if rSkillData then
		return addSimpleSkillDB(nodeChar, sSkill, "reference_skill", "reference.skilldata." .. rSkillData.lookup .. "@*" );
	end
end

function addSimpleSkillDB(nodeChar, sSkill, linkclass, linkrecord)
	-- Get the list we are going to add to
	local nodeList = nodeChar.createChild("simpleskilllist");
	if not nodeList then
		return nil;
	end
	
	-- Make sure this item does not already exist
	local nodeSkill = nil;
	for _,vSkill in pairs(nodeList.getChildren()) do
		if DB.getValue(vSkill, "name", "") == sSkill then
			nodeSkill = vSkill;
			break;
		end
	end
		
	-- Add the item
	if not nodeSkill then
		nodeSkill = nodeList.createChild();
		DB.setValue(nodeSkill, "name", "string", sSkill);
		if linkrecord then
			DB.setValue(nodeSkill, "shortcut", "windowreference",linkclass,  linkrecord);
		end
	end

	-- Announce
	CharManager.outputUserMessage("char_abilities_message_skilladd", DB.getValue(nodeSkill, "name", ""), DB.getValue(nodeChar, "name", ""));
	return nodeSkill;
end

function addSkill(nodeChar, sClass, sRecord)
	local nodeSource = DB.findNode(sRecord);
	if not nodeSource then
		return;
	end
	
	-- Add skill entry
	local nodeSkill = SECharManager.addSimpleSkill(nodeChar, DB.getValue(nodeSource, "name", ""));
	if not nodeSkill then
		local nodeSkill = SECharManager.addSimpleSkillDB(nodeChar, DB.getValue(nodeSource, "name", ""));
		DB.setValue(nodeSkill, "text", "formattedtext", DB.getValue(nodeSource, "text", ""));
	end
end

function resetHealth(nodeChar, bLong)
	local bResetWounds = false;
	local bResetTemp = false;
	local bResetHitDice = false;
	local bResetHalfHitDice = false;
	local bResetQuarterHitDice = false;
	
	local sOptHRHV = OptionsManager.getOption("HRHV");
	if sOptHRHV == "fast" then
		if bLong then
			bResetWounds = true;
			bResetTemp = true;
			bResetHitDice = true;
		else
			bResetQuarterHitDice = true;
			--SE
			bResetHitDice = true;
		end
	elseif sOptHRHV == "slow" then
		if bLong then
			bResetTemp = true;
			bResetHalfHitDice = true;
		end
	else
		if bLong then
			bResetWounds = true;
			bResetTemp = true;
			bResetHalfHitDice = true;
		end
		--SE
		bResetHitDice = true;
	end
	
	-- Reset health fields and conditions
	if bResetWounds then
		DB.setValue(nodeChar, "hp.wounds", "number", 0);
		DB.setValue(nodeChar, "hp.deathsavesuccess", "number", 0);
		DB.setValue(nodeChar, "hp.deathsavefail", "number", 0);
	end
	if bResetTemp then
		DB.setValue(nodeChar, "hp.temporary", "number", 0);
	end
	
	-- Reset all hit dice
	if bResetHitDice then
		for _,vClass in pairs(DB.getChildren(nodeChar, "classes")) do
			DB.setValue(vClass, "hdused", "number", 0);
		end
	end

	-- Reset half or quarter of hit dice (assume biggest hit dice selected first)
	if bResetHalfHitDice or bResetQuarterHitDice then
		local nHDUsed, nHDTotal = CharClassManager.getCharClassHDUsage(nodeChar);
		if nHDUsed > 0 then
			local nHDRecovery;
			if bResetQuarterHitDice then
				nHDRecovery = math.max(math.floor(nHDTotal / 4), 1);
			else
				nHDRecovery = math.max(math.floor(nHDTotal / 2), 1);
			end
			if nHDRecovery >= nHDUsed then
				for _,vClass in pairs(DB.getChildren(nodeChar, "classes")) do
					DB.setValue(vClass, "hdused", "number", 0);
				end
			else
				local nodeClassMax, nClassMaxHDSides, nClassMaxHDUsed;
				while nHDRecovery > 0 do
					nodeClassMax = nil;
					nClassMaxHDSides = 0;
					nClassMaxHDUsed = 0;
					
					for _,vClass in pairs(DB.getChildren(nodeChar, "classes")) do
						local nClassHDUsed = DB.getValue(vClass, "hdused", 0);
						if nClassHDUsed > 0 then
							local aClassDice = DB.getValue(vClass, "hddie", {});
							if #aClassDice > 0 then
								local nClassHDSides = tonumber(aClassDice[1]:sub(2)) or 0;
								if nClassHDSides > 0 and nClassMaxHDSides < nClassHDSides then
									nodeClassMax = vClass;
									nClassMaxHDSides = nClassHDSides;
									nClassMaxHDUsed = nClassHDUsed;
								end
							end
						end
					end
					
					if nodeClassMax then
						if nHDRecovery >= nClassMaxHDUsed then
							DB.setValue(nodeClassMax, "hdused", "number", 0);
							nHDRecovery = nHDRecovery - nClassMaxHDUsed;
						else
							DB.setValue(nodeClassMax, "hdused", "number", nClassMaxHDUsed - nHDRecovery);
							nHDRecovery = 0;						
						end
					else
						break;
					end
				end
			end
		end
	end
end