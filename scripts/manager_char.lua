function onInit()
	CharManager.addClassRef = addClassRef;
	CharManager.addSkillRef = addSkillRef;
	CharManager.getClassHDUsage = getClassHDUsage;
	CharManager.resetHealth = resetHealth;
	CharManager.addClassProficiencyDB = addClassProficiencyDB;
	CharManager.onClassSkillSelect = onClassSkillSelect;
end

function addClassRef(nodeChar, sClass, sRecord, bWizard)
	local nodeSource = CharManager.resolveRefNode(sRecord)
	if not nodeSource then
		return;
	end

	-- Get the list we are going to add to
	local nodeList = nodeChar.createChild("classes");
	if not nodeList then
		return;
	end

	
	-- Notify
	CharManager.outputUserMessage("char_abilities_message_classadd", DB.getValue(nodeSource, "name", ""), DB.getValue(nodeChar, "name", ""));

	-- Keep some data handy for comparisons
	local sClassName = DB.getValue(nodeSource, "name", "");
	local sClassNameLower = StringManager.trim(sClassName):lower();

	-- Check to see if the character already has this class; or create a new class entry
	local nodeClass = nil;
	for _,v in pairs(nodeList.getChildren()) do
		local sExistingClassName = StringManager.trim(DB.getValue(v, "name", "")):lower();
		if (sExistingClassName == sClassNameLower) and (sExistingClassName ~= "") then
			nodeClass = v;
			break;
		end
	end
	local bExistingClass = false;
	if nodeClass then
		bExistingClass = true;
	else
		if nodeList.getChildCount() == 0 then
			nodeClass = nodeList.createChild();
		else
			function SystemMessage(sText)
				local msg = {font = "systemfont"};
				msg.text = sText;
				Comm.addChatMessage(msg);
			end
			CharManager.outputUserMessage("SE_char_abilities_message_classadd_abort",DB.getValue(nodeChar, "name", ""));
			return;
		end
		
	end
	
	-- Calculate current spell slots before levelling up
	local nCasterLevel = CharManager.calcSpellcastingLevel(nodeChar);
	local nPactMagicLevel = CharManager.calcPactMagicLevel(nodeChar);
	
	-- Any way you get here, overwrite or set the class reference link with the most current
	DB.setValue(nodeClass, "shortcut", "windowreference", sClass, sRecord);
	
	-- Add basic class information
	local nLevel = 1;
	if bExistingClass then
		nLevel = DB.getValue(nodeClass, "level", 1) + 1;
	else
		DB.setValue(nodeClass, "name", "string", sClassName);
		local aDice = {};
		-- for i = 1, nHDMult do
		 	table.insert(aDice, "d6");
		-- end
		DB.setValue(nodeClass, "hddie", "dice", aDice);
		
		--load stat values if new class
		DB.setValue(nodeChar,"abilities.strength.score","number",tonumber(DB.getValue(nodeSource, "stat.str", "0")))
		DB.setValue(nodeChar,"abilities.dexterity.score","number",tonumber(DB.getValue(nodeSource, "stat.dex", "0")))
		DB.setValue(nodeChar,"abilities.constitution.score","number",tonumber(DB.getValue(nodeSource, "stat.con", "0")))
		DB.setValue(nodeChar,"abilities.intelligence.score","number",tonumber(DB.getValue(nodeSource, "stat.int", "0")))
		DB.setValue(nodeChar,"abilities.wisdom.score","number",tonumber(DB.getValue(nodeSource, "stat.wis", "0")))
		DB.setValue(nodeChar,"abilities.charisma.score","number",tonumber(DB.getValue(nodeSource, "stat.cha", "0")))
	end
	DB.setValue(nodeClass, "level", "number", nLevel);
	

	-- Calculate total level
	local nTotalLevel = 0;
	for _,vClass in pairs(nodeList.getChildren()) do
		nTotalLevel = nTotalLevel + DB.getValue(vClass, "level", 0);
	end
	
	-- Add hit points based on level added
	--SE
	local nPerLevelHP = tonumber(DB.getValue(nodeSource, "hp.hitperlevel", "0")) or 0;
	local nHP = nTotalLevel * nPerLevelHP;

	CharManager.outputUserMessage("char_abilities_message_hpaddmax", DB.getValue(nodeSource, "name", ""), DB.getValue(nodeChar, "name", ""), nPerLevelHP);
	DB.setValue(nodeChar, "hp.total", "number", nHP);

	--SE Armor Class (transform from total AC to modifier to base of 10)
	local nACmod = tonumber(DB.getValue(nodeSource, "AC", "0"));
	nACmod = nACmod - 10;
	DB.setValue(nodeChar, "defenses.ac.armor", "number", nACmod);
	DB.setValue(nodeChar, "defenses.ac.dexbonus", "string", "no");

	--SE profIncrease
	local nProfMod = tonumber(DB.getValue(nodeSource, "profIncrease", "0"));
	DB.setValue(nodeChar, "profIncrease", "number", nProfMod);

	-- Add proficiencies
	if not bExistingClass and not bWizard then
		if nTotalLevel == 1 then
			for _,v in pairs(DB.getChildren(nodeSource, "proficiencies")) do
				CharManager.addClassProficiencyDB(nodeChar, "reference_classproficiency", v.getPath());
			end
		else
			for _,v in pairs(DB.getChildren(nodeSource, "multiclassproficiencies")) do
				CharManager.addClassProficiencyDB(nodeChar, "reference_classproficiency", v.getPath());
			end
		end
	end
	
	-- Determine whether a specialization is added this level
	if not bWizard then
		local nodeSpecializationFeature = nil;
		local aSpecializationOptions = {};
		for _,v in pairs(DB.getChildren(nodeSource, "features")) do
			if (DB.getValue(v, "level", 0) == nLevel) and (DB.getValue(v, "specializationchoice", 0) == 1) then
				nodeSpecializationFeature = v;
				aSpecializationOptions = CharManager.getClassSpecializationOptions(nodeSource);
				break;
			end
		end
		
		-- Add features, with customization based on whether specialization is added this level
		local rClassAdd = { nodeChar = nodeChar, nodeSource = nodeSource, nLevel = nLevel, nodeClass = nodeClass, nCasterLevel = nCasterLevel, nPactMagicLevel = nPactMagicLevel };
		if #aSpecializationOptions == 0 then
			CharManager.addClassFeatureHelper(nil, rClassAdd);
		elseif #aSpecializationOptions == 1 then
			CharManager.addClassFeatureHelper( { aSpecializationOptions[1].text }, rClassAdd);
		else
			-- Display dialog to choose specialization
			local wSelect = Interface.openWindow("select_dialog", "");
			local sTitle = Interface.getString("char_build_title_selectspecialization");
			local sMessage = string.format(Interface.getString("char_build_message_selectspecialization"), DB.getValue(nodeSpecializationFeature, "name", ""), 1);
			wSelect.requestSelection (sTitle, sMessage, aSpecializationOptions, CharManager.addClassFeatureHelper, rClassAdd);
		end
	else
		return nodeClass;
	end
	--SE set spell slots
	local newSpellSlot = CharManager.calcSpellcastingLevel(nodeChar);
	local newPactSlot = CharManager.calcPactMagicLevel(nodeChar);
	local totalSlots = newSpellSlot + newPactSlot + DB.getValue(nodeSource, "initialSpellSlots", 1) - 1
	DB.setValue(nodeChar, "powermeta.spellslots1.max", "number", totalSlots);
	DB.setValue(nodeChar, "powermeta.pactmagicslots1.max", "number", 0);
	--if we have slots, set the spell slots for 2-5 to have a value so the power groups are visible in combat mode
	if totalSlots > 0 then
		DB.setValue(nodeChar, "powermeta.spellslots2.max", "number", 1);
		DB.setValue(nodeChar, "powermeta.spellslots3.max", "number", 1);
		DB.setValue(nodeChar, "powermeta.spellslots4.max", "number", 1);
		DB.setValue(nodeChar, "powermeta.spellslots5.max", "number", 1);
	end

	--Add the new spells for the class
	local nLevel = nTotalLevel;
	local sClass = sClassName;
	local aMappings = LibraryData.getMappings("spell");
	for _,vMapping in ipairs(aMappings) do
		for _,vSpell in pairs(DB.getChildrenGlobal(vMapping)) do
			local sSpell = StringManager.trim(DB.getValue(vSpell, "name", "")):lower();
			sSpell = StringManager.trim(sSpell);

			local nSpellLevel = DB.getValue(vSpell, "level", 0);
			local aSpellSource = StringManager.split(DB.getValue(vSpell, "source", ""), ",");

			for _,vSource in pairs(aSpellSource) do
				vSource = vSource:lower():gsub("%(optional%)", "")
				vSource = vSource:lower():gsub("%(new%)", "")
				vSource = StringManager.trim(vSource);
				if nSpellLevel == nLevel or (nLevel == 1 and nSpellLevel == 0) then
					if StringManager.trim(vSource:lower()) == sClass:lower() then
						PowerManager.addPower("reference_spell", vSpell.getPath(), nodeChar, Interface.getString("power_label_groupspells"));
					end
				end
			end

		end
	end	
end

function addClassProficiencyDB(nodeChar, sClass, sRecord)
	local nodeSource = CharManager.resolveRefNode(sRecord);
	if not nodeSource then
		return;
	end
	
	local sText = DB.getValue(nodeSource, "text", "");
	if sText == "" then
		return;
	end
	
	local sType = nodeSource.getName();
	
	-- Armor, Weapon or Tool Proficiencies
	if StringManager.contains({"armor", "weapons", "tools"}, sType) then
		local sText = DB.getText(nodeSource, "text");
		CharManager.addProficiencyDB(nodeChar, sType, sText);
		
	-- Saving Throw Proficiencies
	elseif sType == "savingthrows" then
		local sText = DB.getText(nodeSource, "text");
		for sProf in string.gmatch(sText, "(%a[%a%s]+)%,?") do
			local sProfLower = StringManager.trim(sProf:lower());
			if StringManager.contains(DataCommon.abilities, sProfLower) then
				DB.setValue(nodeChar, "abilities." .. sProfLower .. ".saveprof", "number", 1);
				CharManager.outputUserMessage("char_abilities_message_saveadd", sProf, DB.getValue(nodeChar, "name", ""));
			end
		end

	-- Skill Proficiencies
	elseif sType == "skills" then
		-- Parse the skill choice text
		local sText = DB.getText(nodeSource, "text");
		
		local aSkills = {};
		local sPicks;
		--
		

		--

		if sText:match("Choose any ") then
			sPicks = sText:match("Choose any (%w+)");
			
		elseif sText:match("Choose ") then
			sPicks = sText:match("Choose (%w+) ");
			
			sText = sText:gsub("Choose (%w+) from ", "");
			sText = sText:gsub("Choose (%w+) skills? from ", "");
			sText = sText:gsub("and ", "");
			sText = sText:gsub("or ", "");
			
			for sSkill in sText:gmatch("(%a[%a%s]+)%,?") do
				local sTrim = StringManager.trim(sSkill);
				table.insert(aSkills, sTrim);
			end
		end
		
		local nPicks = CharManager.convertSingleNumberTextToNumber(sPicks);
		
		if nPicks == 0 then
			sText = sText:gsub("and ", "");
			sText = sText:gsub("or ", "");
			for sSkill in sText:gmatch("(%a[%a%s]+)%,?") do
				local sTrim = StringManager.trim(sSkill);
				table.insert(aSkills, sTrim);
			end
			if aSkills then 
				addSkills(nodeChar, aSkills);
				return;
			else
				CharManager.outputUserMessage("char_error_addskill");
				return nil;
			end
		end

		CharManager.pickSkills(nodeChar, aSkills, nPicks);
	end
end

function onClassSkillSelect(aSelection, rSkillAdd)
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
			aSkills[k] = { text = v, linkclass = "reference_skill", linkrecord = "reference.skilldata." .. rSkillData.lookup .. "@*" };
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

function addSkillRef(nodeChar, sClass, sRecord)
	local nodeSource = CharManager.resolveRefNode(sRecord);
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

function getClassHDUsage(nodeChar)
	local nHD = math.max(1,DB.getValue(nodeChar,"abilities.constitution.bonus",0));
	local nHDUsed = 0;
	
	for _,nodeChild in pairs(DB.getChildren(nodeChar, "classes")) do
		nHDUsed = nHDUsed + DB.getValue(nodeChild, "hdused", 0);
	end
	
	return nHDUsed, nHD;
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
		local nHDUsed, nHDTotal = getClassHDUsage(nodeChar);
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