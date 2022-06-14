function onInit()
	CharManager.helperAddSkill = helperAddSkill;
	CharManager.resetHealth = resetHealth;
end

---SE uses a different skill list format along with code to add the link
---@param nodeChar any the character to be modified
---@param sSkill string the skill to be added
---@param nProficient any this parameter is ignored
---@return any nodeSkill the node of the skill added
function helperAddSkill(nodeChar, sSkill, nProficient)
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

		--check if this is defined in the campaign or module so this will resolve and show the descriptive text
		local nodeRefSkill = RecordManager.findRecordByStringI("skill", "name", sSkill);
		if nodeRefSkill then
			local linkclass = "reference_skill";
			local linkrecord = DB.getPath(nodeRefSkill);
			DB.setValue(nodeSkill, "shortcut", "windowreference",linkclass,  linkrecord);
		end
	end

	-- Announce
	CharManager.outputUserMessage("char_abilities_message_skilladd", DB.getValue(nodeSkill, "name", ""), DB.getValue(nodeChar, "name", ""));
	return nodeSkill;
end

---Makes a few modifications as marked since SE handles rests a little differently for hit dice
---@param nodeChar any the character to be rested
---@param bLong boolean if this is a long rest
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