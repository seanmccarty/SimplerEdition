function onInit()
	ActorManager5E.getAbilityBonus = getAbilityBonus;
	ActorManager5E.getAbilityEffectsBonus = getAbilityEffectsBonus;
end

function getAbilityBonus(rActor, sAbility)
	if (sAbility or "") == "" then
		return 0;
	end
	if not rActor then
		return 0;
	end

	local bNegativeOnly = (sAbility:sub(1,1) == "-");
	if bNegativeOnly then
		sAbility = sAbility:sub(2);
	end
	
	local nStatScore = ActorManager5E.getAbilityScore(rActor, sAbility);
	
	local nStatVal = 0;
	if StringManager.contains(DataCommon.abilities, sAbility) then
		nStatVal = nStatScore;
	else
		nStatVal = nStatScore;
	end

	if bNegativeOnly and nStatVal > 0 then
		nStatVal = 0;
	end
	
	return nStatVal;
end

function getAbilityEffectsBonus(rActor, sAbility)
	if not rActor or ((sAbility or "") == "") then
		return 0, 0;
	end
	
	local bNegativeOnly = (sAbility:sub(1,1) == "-");
	if bNegativeOnly then
		sAbility = sAbility:sub(2);
	end

	local sAbilityEffect = DataCommon.ability_ltos[sAbility];
	if not sAbilityEffect then
		return 0, 0;
	end
	
	local nAbilityMod, nAbilityEffects = EffectManager5E.getEffectsBonus(rActor, sAbilityEffect, true);
	
	local nAbilityScore = ActorManager5E.getAbilityScore(rActor, sAbility);
	local nAffectedScore = math.max(nAbilityScore + nAbilityMod, 0);
	
	local nCurrentBonus = nAbilityScore;
	local nAffectedBonus = nAffectedScore;
	
	nAbilityMod = nAffectedBonus - nCurrentBonus;

	if bNegativeOnly and (nAbilityMod > 0) then
		nAbilityMod = 0;
	end

	return nAbilityMod, nAbilityEffects;
end