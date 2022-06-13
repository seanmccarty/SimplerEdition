-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--
function onInit()
	CharArmorManager.calcItemArmorClass = calcItemArmorClass;
end


function calcItemArmorClass(nodeChar)
	local nMainShieldTotal = 0;
	
	for _,vNode in pairs(DB.getChildren(nodeChar, "inventorylist")) do
		if DB.getValue(vNode, "carried", 0) == 2 then
			if ItemManager.isArmor(vNode) then
				local bID = LibraryData.getIDState("item", vNode, true);
				
				if ItemManager.isShield(vNode) then
					if bID then
						nMainShieldTotal = nMainShieldTotal + DB.getValue(vNode, "ac", 0) + DB.getValue(vNode, "bonus", 0);
					else
						nMainShieldTotal = nMainShieldTotal + DB.getValue(vNode, "ac", 0);
					end				
				end
			end
		end
	end
		
	DB.setValue(nodeChar, "defenses.ac.shield", "number", nMainShieldTotal);
	DB.setValue(nodeChar, "defenses.ac.disstealth", "number", 0);
end
