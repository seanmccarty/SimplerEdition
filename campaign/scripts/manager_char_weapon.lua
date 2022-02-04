-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

WEAPON_TYPE_RANGED = "ranged";

WEAPON_PROP_AMMUNITION = "ammunition";
WEAPON_PROP_CRITRANGE = "crit range %(?(%d+)%)?";
WEAPON_PROP_FINESSE = "finesse";
WEAPON_PROP_HEAVY = "heavy";
WEAPON_PROP_LIGHT = "light";
WEAPON_PROP_MAGIC = "magic";
WEAPON_PROP_REACH = "reach";
WEAPON_PROP_REROLL = "reroll %(?(%d+)%)?";
WEAPON_PROP_THROWN = "thrown";
WEAPON_PROP_TWOHANDED = "two-handed";
WEAPON_PROP_VERSATILE = "versatile %(?%d?(d%d+)%)?";

function onInit()
	CharWeaponManager.getAttackBonus = getAttackBonus;
	CharWeaponManager.getDamageBaseAbility = getDamageBaseAbility;
	CharWeaponManager.getDamageClauses = getDamageClauses;
	CharWeaponManager.buildDamageAction = buildDamageAction;
end


function getAttackBonus(nodeChar, nodeWeapon)
	local sAbility = CharWeaponManager.getAttackAbility(nodeChar, nodeWeapon);
	
	local nMod = DB.getValue(nodeWeapon, "attackbonus", 0);
	nMod = nMod + ActorManager5E.getAbilityBonus(nodeChar, sAbility);
	--remove prof bonus

	return nMod, sAbility;
end


function getDamageBaseAbility(nodeChar, nodeWeapon)
	local sAbility = "";

	-- Use ability based on type
	local nWeaponType = DB.getValue(nodeWeapon, "type", 0);
	-- Ranged
	if nWeaponType == 1 then
		sAbility = "dexterity";
	-- Melee or Thrown
	else
		sAbility = "strength";

		local bFinesse = CharWeaponManager.checkProperty(nodeWeapon, WEAPON_PROP_FINESSE);
		if bFinesse then
			local nSTR = ActorManager5E.getAbilityBonus(nodeChar, "strength");
			local nDEX = ActorManager5E.getAbilityBonus(nodeChar, "dexterity");
			if nDEX > nSTR then
				sAbility = "dexterity";
			end
		end
	end
	--remove two hand/off hand

	return sAbility;
end

function getDamageClauses(nodeChar, nodeWeapon, sBaseAbility, nReroll)
	local clauses = {};

	-- Check for versatile property and two-handed usage
	local sVersatile = nil;
	--remove two hand /off hand

	-- Iterate over database nodes in order they are displayed
	local rActor = ActorManager.resolveActor(nodeChar);
	local aDamageNodes = UtilityManager.getSortedTable(DB.getChildren(nodeWeapon, "damagelist"));
	for _,v in ipairs(aDamageNodes) do
		-- Build basic damage clause information
		local sDmgAbility = DB.getValue(v, "stat", "");
		if sDmgAbility == "base" then
			sDmgAbility = sBaseAbility;
		end
		local nAbilityBonus = ActorManager5E.getAbilityBonus(rActor, sDmgAbility);
		local nMult = DB.getValue(v, "statmult", 1);
		if nAbilityBonus > 0 and nMult ~= 1 then
			nAbilityBonus = math.floor(nMult * nAbilityBonus);
		end
		local aDmgDice = DB.getValue(v, "dice", {});
		local nDmgMod = nAbilityBonus + DB.getValue(v, "bonus", 0);
		local sDmgType = DB.getValue(v, "type", "");
		
		-- Handle versatile value, if any
		if sVersatile and #aDmgDice > 0 then
			aDmgDice[1] = sVersatile;
			sVersatile = nil;
		end

		-- Handle reroll value, if any
		local aDmgReroll = nil;
		if nReroll then
			aDmgReroll = {};
			for kDie,vDie in ipairs(aDmgDice) do
				aDmgReroll[kDie] = nReroll;
			end
		end
		
		-- Add clause to list of clauses
		table.insert(clauses, { dice = aDmgDice, stat = sDmgAbility, statmult = nMult, modifier = nDmgMod, dmgtype = sDmgType, reroll = aDmgReroll });
	end

	return clauses;
end

function buildDamageAction(nodeChar, nodeWeapon)
	-- Build basic damage action record
	local rAction = {};
	rAction.bWeapon = true;
	rAction.label = DB.getValue(nodeWeapon, "name", "");
	-- remove two handed/one handed
	rAction.range = CharWeaponManager.getRange(nodeChar, nodeWeapon);

	-- Check for reroll property
	local nPropReroll = getPropertyNumber(nodeWeapon, WEAPON_PROP_REROLL);
	if nPropReroll and (nPropReroll > 0) then
		rAction.nReroll = nPropReroll;
	end
	
	-- Build damage clauses
	local sBaseAbility = CharWeaponManager.getDamageBaseAbility(nodeChar, nodeWeapon);
	rAction.clauses = CharWeaponManager.getDamageClauses(nodeChar, nodeWeapon, sBaseAbility, rAction.nReroll);

	return rAction;
end