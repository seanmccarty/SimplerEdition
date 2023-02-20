function onInit()
	OptionsManager.deleteOption("HRST");
	ActionsManager.registerResultHandler("check", onCheckRoll);
	ActionDamage.applyCriticalToModRoll = applyCriticalToModRoll;
	ActionInit.getRoll = getInitRoll;
	ActionRecovery.performRoll = performRecoveryRoll;
	ActionSave.performConcentrationRoll = performConcentrationRoll;
	ActionSave.getRoll = getSaveRoll;
	ActionsManager.registerResultHandler("skill", onSkillRoll);
	CharEncumbranceManager.addStandardCalc();
end

function onCheckRoll(rSource, rTarget, rRoll)
	ActionsManager2.decodeAdvantage(rRoll);

	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	local res = rRoll.aDice[1].result or 0

	if rRoll.nTarget then
		local nTotal = ActionsManager.total(rRoll);
		local nTargetDC = tonumber(rRoll.nTarget) or 0;
		
		rMessage.text = rMessage.text .. " (vs. DC " .. nTargetDC .. ")";
		if res == 20 then
			rMessage.text = rMessage.text .. " [CRITICAL SUCCESS]";
		elseif res == 1 then
			rMessage.text = rMessage.text .. " [CRITICAL FAILURE]";
		elseif nTotal >= nTargetDC then
			rMessage.text = rMessage.text .. " [SUCCESS]";
		else
			rMessage.text = rMessage.text .. " [FAILURE]";
		end
	elseif res == 20 then
		rMessage.text = rMessage.text .. " [CRITICAL SUCCESS]";
	elseif res == 1 then
		rMessage.text = rMessage.text .. " [CRITICAL FAILURE]";
	end
	
	Comm.deliverChatMessage(rMessage);
end

function applyCriticalToModRoll(rRoll, rSource, rTarget)
	local runningMod = 0;
	for _,vClause in ipairs(rRoll.clauses) do
		local nMod = 0;
		for _,vDie in ipairs(vClause.dice) do
			if vDie:sub(1,1) == "-" then
				nMod = nMod - (tonumber(vDie:sub(3)) or 0);
			else
				nMod = nMod + (tonumber(vDie:sub(2)) or 0);
			end
		end
		vClause.modifier = vClause.modifier + nMod;
		runningMod = runningMod + nMod;
	end
	rRoll.nMod = rRoll.nMod + runningMod;
	table.insert(rRoll.tNotifications, "[CRITICAL " .. runningMod.. "]");
end

function getInitRoll(rActor, bSecretRoll)
	local rRoll = {};
	rRoll.sType = "init";
	rRoll.aDice = { "d10" };
	rRoll.nMod = 0;
	
	rRoll.sDesc = "[INIT]";
	
	rRoll.bSecret = bSecretRoll;

	-- Determine the modifier and ability to use for this roll
	local sNodeType, nodeActor = ActorManager.getTypeAndNode(rActor);
	if nodeActor then
		if sNodeType == "pc" then
			rRoll.nMod = DB.getValue(nodeActor, "initiative.total", 0);
		else
			rRoll.nMod = DB.getValue(nodeActor, "init", 0);
		end
	end
	
	return rRoll;
end

function performRecoveryRoll(draginfo, rActor, nodeClass)
	local rRoll = {};
	rRoll.sType = "recovery";
	rRoll.sClassNode = DB.getPath(nodeClass);
	
	rRoll.sDesc = "[RECOVERY]";
	rRoll.aDice = {};
	rRoll.nMod = 0;

	local aHDDice = DB.getValue(nodeClass, "hddie", {});
	if #aHDDice > 0 then
		table.insert(rRoll.aDice, aHDDice[1]);
	end

	
	ActionsManager.performAction(draginfo, rActor, rRoll);
end

function performConcentrationRoll(draginfo, rActor, nTargetDC)
	EffectManager.message("Damage requires a concentration check.", rActor, false);
end

function getSaveRoll(rActor, sSave)
	local rRoll = {};
	rRoll.sType = "save";
	rRoll.aDice = { "d20" };
	local nMod, bADV, bDIS, sAddText = ActorManager5E.getSave(rActor, sSave);
	local sNodeType, nodeActor = ActorManager.getTypeAndNode(rActor);
	
	rRoll.nMod = nMod + DB.getValue(nodeActor, "profbonus", 0);
	if sNodeType == "pc" then
		rRoll.sDesc = "[SAVE] ".. Interface.getString("SE_modifier_prof") .. " " .. StringManager.capitalize(sSave);
	else
		rRoll.sDesc = "[SAVE] " .. StringManager.capitalize(sSave);
	end

	if sAddText and sAddText ~= "" then
		rRoll.sDesc = rRoll.sDesc .. " " .. sAddText;
	end
	if bADV then
		rRoll.sDesc = rRoll.sDesc .. " [ADV]";
	end
	if bDIS then
		rRoll.sDesc = rRoll.sDesc .. " [DIS]";
	end
	
	return rRoll;
end

function onSkillRoll(rSource, rTarget, rRoll)
	ActionsManager2.decodeAdvantage(rRoll);
	
	local rMessage = ActionsManager.createActionMessage(rSource, rRoll);
	local res = rRoll.aDice[1].result or 0

	if rRoll.nTarget then
		local nTotal = ActionsManager.total(rRoll);
		local nTargetDC = tonumber(rRoll.nTarget) or 0;
		
		rMessage.text = rMessage.text .. " (vs. DC " .. nTargetDC .. ")";
		if res == 20 then
			rMessage.text = rMessage.text .. " [CRITICAL SUCCESS]";
		elseif res == 1 then
			rMessage.text = rMessage.text .. " [CRITICAL FAILURE]";
		elseif nTotal >= nTargetDC then
			rMessage.text = rMessage.text .. " [SUCCESS]";
		else
			rMessage.text = rMessage.text .. " [FAILURE]";
		end
	elseif res == 20 then
		rMessage.text = rMessage.text .. " [CRITICAL SUCCESS]";
	elseif res == 1 then
		rMessage.text = rMessage.text .. " [CRITICAL FAILURE]";
	end
	
	Comm.deliverChatMessage(rMessage);
end
