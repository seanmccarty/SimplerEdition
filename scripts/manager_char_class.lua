local oAddClass;

function onInit()
	CharClassManager.getCharClassHDUsage = getCharClassHDUsage;
	CharClassManager.helperAddClassHP = helperAddClassHP;
	CharClassManager.helperAddClassUpdateSpellSlots = helperAddClassUpdateSpellSlots;
	CharClassManager.addClassProficiency = addClassProficiency; 
	oAddClass = CharClassManager.addClass;
	CharClassManager.addClass = addClass;
end

---Overrides the the calculation for how many hit dice a character will have to be the CON bonus (minimum 1)
---@param nodeChar any the character node of interest
---@return integer nHDUsed number of hit dice used
---@return number nHD max number of hit dice for the character
function getCharClassHDUsage(nodeChar)
	local nHD = math.max(1,DB.getValue(nodeChar,"abilities.constitution.bonus",0));
	local nHDUsed = 0;
	
	for _,nodeChild in ipairs(DB.getChildList(nodeChar, "classes")) do
		nHDUsed = nHDUsed + DB.getValue(nodeChild, "hdused", 0);
	end
	
	return nHDUsed, nHD;
end

---Hit points added per level for a given class are pre-determined and all hit dice are d6
---@param rAdd any the rAdd structure for the character
function helperAddClassHP(rAdd)
	if rAdd.bNewCharClass then
		DB.setValue(rAdd.nodeCharClass, "hddie", "dice", "1d6");
	end

	-- Add hit points based on class leveled
	local nHP = DB.getValue(rAdd.nodeChar, "hp.total", 0);
	local nPerLevelHP = tonumber(DB.getValue(rAdd.nodeSource, "hp.hitperlevel", "0")) or 0;
	nHP = nHP + nPerLevelHP;

	CharManager.outputUserMessage("char_abilities_message_hpaddmax", rAdd.sSourceName, rAdd.sCharName, nPerLevelHP);
	DB.setValue(rAdd.nodeChar, "hp.total", "number", nHP);
end

---Available spells slots are calculated differently for SE and are all of one type
---@param rAdd any the rAdd structure for the character
function helperAddClassUpdateSpellSlots(rAdd)
	--SE set spell slots
	--Get spells slots for the new level (rAdd has the count before the upgrade happens)
	local tCharClassMagicData = CharClassManager.getCharClassMagicData(rAdd.nodeChar);

	--if nSpellClasses > 0 it means the ability to cast spells is present
	if tCharClassMagicData.nSpellClasses > 0 then
		--if there is spellcasting, it is the number of initial spell slots + the number of slots above first level
		local nTotalSlots = rAdd.nCharClassLevel + DB.getValue(rAdd.nodeSource, "initialSpellSlots", 1) - 1;
		local bPactmagic = tCharClassMagicData[1].bPactmagic;
		if bPactmagic then
			DB.setValue(rAdd.nodeChar, "powermeta.pactmagicslots1.max", "number", nTotalSlots);
			--if we have slots, set the spell slots for 2-5 to have a value so the power groups are visible in combat mode. The xml for these is invisible though so you don't see the indicators.
			DB.setValue(rAdd.nodeChar, "powermeta.pactmagicslots2.max", "number", 1);
			DB.setValue(rAdd.nodeChar, "powermeta.pactmagicslots3.max", "number", 1);
			DB.setValue(rAdd.nodeChar, "powermeta.pactmagicslots4.max", "number", 1);
			DB.setValue(rAdd.nodeChar, "powermeta.pactmagicslots5.max", "number", 1);
		else
			DB.setValue(rAdd.nodeChar, "powermeta.spellslots1.max", "number", nTotalSlots);
			--if we have slots, set the spell slots for 2-5 to have a value so the power groups are visible in combat mode. The xml for these is invisible though so you don't see the indicators.
			DB.setValue(rAdd.nodeChar, "powermeta.spellslots2.max", "number", 1);
			DB.setValue(rAdd.nodeChar, "powermeta.spellslots3.max", "number", 1);
			DB.setValue(rAdd.nodeChar, "powermeta.spellslots4.max", "number", 1);
			DB.setValue(rAdd.nodeChar, "powermeta.spellslots5.max", "number", 1);
		end
	end	

	--Add the new spells for the class
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
				if nSpellLevel == rAdd.nCharClassLevel or (rAdd.nCharClassLevel == 1 and nSpellLevel == 0) then
					if StringManager.trim(vSource:lower()) ==  rAdd.sSourceName:lower() then
						PowerManager.addPower("reference_spell", vSpell.getPath(), rAdd.nodeChar, Interface.getString("power_label_groupspells"));
					end
				end
			end
		end
	end
end

---The only changed portion is the skill as indicated by the comment
---@param nodeChar any the character that the class is being added to
---@param sClass string the type of the record being added
---@param sRecord string the record being added
---@param bWizard boolean if this is added by char wizard
---@return nil
function addClassProficiency(nodeChar, sClass, sRecord, bWizard)
	local rAdd = CharManager.helperBuildAddStructure(nodeChar, sClass, sRecord, bWizard);
	if not rAdd then
		return;
	end

	-- Saving Throw Proficiencies
	if rAdd.sSourceType == "savingthrows" then
		local sText = StringManager.trim(DB.getText(rAdd.nodeSource, "text", ""));
		if sText == "" then
			return;
		end

		for sProf in sText:gmatch("(%a[%a%s]+)%,?") do
			local sProfLower = StringManager.trim(sProf):lower();
			if StringManager.contains(DataCommon.abilities, sProfLower) then
				DB.setValue(rAdd.nodeChar, "abilities." .. sProfLower .. ".saveprof", "number", 1);
				CharManager.outputUserMessage("char_abilities_message_saveadd", sProf, rAdd.sCharName);
			end
		end
	end

	if not rAdd.bWizard then
		-- Armor, Weapon or Tool Proficiencies
		if StringManager.contains({"armor", "weapons", "tools"}, rAdd.sSourceType) then
			local sText = StringManager.trim(DB.getText(rAdd.nodeSource, "text", ""));
			if sText == "" then
				return;
			end

			CharManager.addProficiency(rAdd.nodeChar, rAdd.sSourceType, DB.getText(rAdd.nodeSource, "text", ""));
			

		-- Skill Proficiencies
		elseif rAdd.sSourceType == "skills" then
			local nPicks, tSkills = CharManager.parseSkillProficiencyText(rAdd.nodeSource);
			if nPicks == 0 then
				--SE uses non-standard skill text and there are no picks.
				local sText = DB.getText(rAdd.nodeSource, "text","");
				local aSkills = CharManager.parseSkillsFromString(sText);
				if aSkills then 
					for _,sSkill in ipairs(aSkills) do
						CharManager.helperAddSkill(nodeChar, sSkill);
					end
					return;
				else
					CharManager.outputUserMessage("char_error_addskill");
					return nil;
				end
			end
			CharManager.pickSkills(rAdd.nodeChar, tSkills, nPicks);
		end
	end
end

---Overrides the addClass so we can intercept multi-classing. If it is not multi-classing, add the class then add the extra preset data that SE has
---@param nodeChar any the character that the class is being added to
---@param sClass string the type of the record being added
---@param sRecord string the record being added
---@param bWizard boolean if this is added by char wizard
function addClass(nodeChar, sClass, sRecord, bWizard)
	local nodeSource = DB.findNode(sRecord);
	local sClassName = StringManager.trim(DB.getValue(nodeSource, "name", ""));
	if CharClassManager.getCharLevel(nodeChar) == CharClassManager.getCharClassLevel(nodeChar, sClassName) then
		oAddClass(nodeChar, sClass, sRecord, bWizard);

		DB.setValue(nodeChar,"abilities.strength.score","number",tonumber(DB.getValue(nodeSource, "stat.str", "0")))
		DB.setValue(nodeChar,"abilities.dexterity.score","number",tonumber(DB.getValue(nodeSource, "stat.dex", "0")))
		DB.setValue(nodeChar,"abilities.constitution.score","number",tonumber(DB.getValue(nodeSource, "stat.con", "0")))
		DB.setValue(nodeChar,"abilities.intelligence.score","number",tonumber(DB.getValue(nodeSource, "stat.int", "0")))
		DB.setValue(nodeChar,"abilities.wisdom.score","number",tonumber(DB.getValue(nodeSource, "stat.wis", "0")))
		DB.setValue(nodeChar,"abilities.charisma.score","number",tonumber(DB.getValue(nodeSource, "stat.cha", "0")))

		--SE Armor Class (transform from total AC to modifier to base of 10)
		local nACmod = tonumber(DB.getValue(nodeSource, "AC", "0"));
		nACmod = nACmod - 10;
		DB.setValue(nodeChar, "defenses.ac.armor", "number", nACmod);
		DB.setValue(nodeChar, "defenses.ac.dexbonus", "string", "no");

		--SE profIncrease for if proficiency gets a boost at the start
		local nProfMod = tonumber(DB.getValue(nodeSource, "profIncrease", "0"));
		DB.setValue(nodeChar, "profIncrease", "number", nProfMod);
	else
		CharManager.outputUserMessage("SE_char_abilities_message_classadd_abort",DB.getValue(nodeChar, "name", ""));
		return;
	end
end