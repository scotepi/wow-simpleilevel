--[[
	Total Rewrite:
	---------------------------------------
	To Do List for 1.0:
	* Fix level 80 heirlooms on 81+ players
	* Better way of handleing people under 60 who don't have 14 items
	
	To-Do List for 2.0 and beyond:
	* Add color based score for over 100% accuracy
		- white - yellow - green (333) - blue (heroic t11) - purple (heroic t12) - red (500 assumed max due to belt bucle)
	* Add SiL's AiL to your charciter information sheet
	* Add the AiL to the inspect window
	* UI for viwing the cache - log way off
	* More mathmatical stats for party and raid
	
	Known Issues:
	* Blizzard_InspectUI\InspectPaperDollFrame.lua errors are bugs in the default UI
	* Lower level toons will never be 100%, posibly have accuracy scale?
	* Level 80 heirlooms on level 81+ return the wrong iLevel
	* Doesn't work on heath or mana bars when you target someone, this is a bug, there is no UnitName("mouseover") or UnitGUID("mouseover") there
	
	Changelog for 0.63:
	* Fixed color for hours to be more visable, light blue insted of dark
	* Fixed rounding on /sil again ><
	* Added padding to player names in raid and party to hopefully make it more readable
	
	Changelog for 0.62: 2011-02-01
	* Changed all files to UTF-8
	* Fixed translation to use native characters
	* Fixed /sil get <name> to be case insensitive
	* Fixed typo in party and raid
	
	Changelog for 0.61: 2011-01-31
	* Fixed raid and party scoring, forgot to set a variable to local
	* Added localization for zhTW, thanks meowgoddess
	
	Changelog for 0.6: 2011-01-29
	* Fixed hairlooms yet again >< should have tested a little more
	* Fixed scanning people, should be less then 100% for 1sec or less and then fully load
	* Fixed duplicate tool tips! Thanks kd3 and Adys in #wowuidev on freenode
	* Fixed missing tool tips, no longer uses hook functions but insted uses events
	* Added color to the advanced tool tips for accuracy and age
	* Added color for age, green < 1h, blue < 1day, red > day
	* Added information to party and raid scaning for people not in range and no cache
	* Cleaned up some internal functions, making it esier for other addons to use
	* Finalized saved variables including cache and settings
]]

-- Local Variables
SIL_Loaded = false;
SIL_Debug = false;
SIL_Version = 0.63;
local L = false;

if ( SIL_Local ) then
	L = SIL_Local;
else
	L = SIL_enUS;
end

function SIL_OnEvent(SIL_Nil, eventName, arg1, arg2, arg3)
	if ( eventName == 'ADDON_LOADED' ) and not ( SIL_Loaded ) then
		
		-- This is a first load
		if not ( SIL_Settings ) or not ( SIL_CacheGUID ) then
			SIL_Initialize();
		end
		
		-- This is a newer version
		if ( SIL_Version > SIL_Settings['version'] ) then
			SIL_Upgrade();
		end
		
		-- Tell the player we have been loaded
		SIL_Console(SIL_Replace(L['Loading Addon'], 'version', SIL_Version));
		SIL_Loaded = true;
		
		-- Debug if its the devs alt
		if ( UnitGUID('player') == '0x058000000657392B' ) then
			SIL_Debug = true;
		end
	end
	
	if ( eventName == 'PLAYER_TARGET_CHANGED' ) then
		SIL_StartScore('target', false, true);
	end
	
	if ( eventName == 'INSPECT_READY' ) then	
		SIL_ProcessInspect(arg1); 
	end
	
	-- Mouse over someone
	if ( eventName == 'UPDATE_MOUSEOVER_UNIT' ) and not ( InCombatLockdown() ) then
		SIL_ShowTooltip();
	end
end;

--[[
	SIL_Initialize();
	Clears settings/resets on inital load
]]
function SIL_Initialize()
	SIL_CacheGUID = {}; -- [UnitGUID] = {'items'=>#,'total'=>#,'name'=>UnitName,'time'=>time()};
	
	SIL_Settings = {}
	SIL_Settings['age'] = 1800;				-- How long till information is refreshed
	SIL_Settings['accuracy'] = 14;			-- How many items is considered 100% accurate
	SIL_Settings['advanced'] = false;		-- Display extra information in the tooltips
	SIL_Settings['version'] = SIL_Version;	-- Version for future referance
end;

--[[
	SIL_Upgrade();
	attempts to upgrade from a older version or resets the settings
]]
function SIL_Upgrade()
	
	-- Nothing to do yet
	
	SIL_Settings['version'] = SIL_Version;
end

--[[
	SIL_GUIDtoName(guid);
	returns name or false
]]
function SIL_GUIDtoName(guid)
	if ( SIL_CacheGUID[guid] ) then
		return SIL_CacheGUID[guid]['name'];
	else
		return false;
	end
end

--[[
	SIL_NameToGUID(guid);
	returns guid or false
]]
function SIL_NameToGUID(name)
	if ( name ) then
		name = strlower(name);
		
		for guid,info in pairs(SIL_CacheGUID) do
			if ( strlower(info['name']) == name ) then
				return guid;
			end
		end
	end
	
	return false;
end

--[[
	SIL_HasScore(name|guid);
	returns true or false
]]
function SIL_HasScore(target)
	
	-- It looks like a name, convert to guid
	if not ( tonumber(target) ) then
		target = SIL_NameToGUID(target);
	end
	
	if ( SIL_CacheGUID[target] ) and ( SIL_CacheGUID[target]['items'] ) then
		return true;
	else
		return false;
	end
end

--[[
	SIL_GetScore(name|guid);
	returns false or score, accuracy, age
]]
function SIL_GetScore(target)
	
	-- It looks like a name, convert to guid
	if not ( tonumber(target) ) then
		target = SIL_NameToGUID(target);
	end
	
	if ( SIL_CacheGUID[target] ) and ( SIL_CacheGUID[target]['items'] ) then
		
		-- Return the unformated score, accuracy and age
		local score = SIL_CacheGUID[target]['total'] / SIL_CacheGUID[target]['items'];
		local accuracy = SIL_GetAccuracy(SIL_CacheGUID[target]['items'], true);
		local age = time() - SIL_CacheGUID[target]['time']
		return score, accuracy, age;
	else
		return false;
	end
end

--[[
	SIL_SetScore(items, total, name, guid);
	return true or false
]]
function SIL_SetScore(items, total, guid)
	if ( items ) and ( total ) and ( guid ) then
		SIL_CacheGUID[guid]['items'] = items;
		SIL_CacheGUID[guid]['total'] = total;
		SIL_CacheGUID[guid]['time'] = time();
		
		return true;
	else
		return false;
	end
end;

--[[
	SIL_ScoreHeirloom(UnitLevel)
	returns the hairloom iLevel for someone of level
]]
function SIL_ScoreHeirloom(level)
	
	--[[
		Here is how I came to the level 81-85 bracket
		200 = level of 80 instance gear
		333 = level of 85 instance gear
		333 - 200 = 133 iLevels / 5 levels = 26.6 iLevel / level
		so then that means
		85 - 80 = 5 * 26.6 = 133 + 200 = 333
	]]
	
	if ( level > 80 ) then
		return (( level - 80 ) * 26.6) + 200; -- Can be 29.2 for 85 = 346
	elseif ( level > 70 ) then
		return (( level - 70 ) * 10) + 100;
	elseif ( level > 60 ) then
		return (( level - 60 ) * 4) + 60;
	else
		return level;
	end
end

--[[
	SIL_ClearScore(name|guid);
	return true or false
]]
function SIL_ClearScore(target)
	
	-- It looks like a name, convert to guid
	if not ( tonumber(target) ) then
		target = SIL_NameToGUID(target);
	end
	
	if ( SIL_CacheGUID[target] ) and ( SIL_CacheGUID[target]['items'] )then
		SIL_CacheGUID[target]['items'] = false;
		SIL_CacheGUID[target]['total'] = false;
		SIL_CacheGUID[target]['time'] = false;
		
		return true;
	else
		return false;
	end
end;

--[[
	SIL_GetAccuracy(items, timesOneHundred)
	if timesOneHundred = true then the score will be 0-100
	returns the accuracy for a give number of items
]]
function SIL_GetAccuracy(items, times)
	local accuracy = 0;
	
	-- Find the accuracy
	if ( items < SIL_Settings['accuracy'] ) then
		accuracy = items / SIL_Settings['accuracy'];
	else
		accuracy = 1;
	end
	
	-- Return a result
	if ( times ) then
		return SIL_Round(accuracy * 100, 1);
	else
		return accuracy;
	end;
end;

--[[
	SIL_StartScore(target, forceRefresh, showTooltip);
	returns true or false if a score was started
]]
function SIL_StartScore(target, refresh, tooltip)
	
	-- Incombat so we can't do anything
	if ( InCombatLockdown() ) then 
		return false;
	
	-- We can inspect the person
	elseif ( CanInspect(target) ) then
		local guid = UnitGUID(target);
		local name = UnitName(target);
		
		-- We want to start from scratch
		if ( refresh ) then
			SIL_Console("Clearing score for "..name, true);
			SIL_ClearScore(guid);
			
		end
		
		-- Check there score to get all usefull information
		local score, accuracy, age = SIL_GetScore(guid);
		
		-- Some debuging
		if ( score ) then
			SIL_Console(name.." score:"..score.." acc:"..accuracy.." age:"..age, true);
		end
		
		-- We have a score and its under age and its accurate
		if ( score ) and ( age < SIL_Settings['age'] ) and ( accuracy == '100.0' ) then
			
			if ( tooltip ) then
				SIL_ShowTooltip();
			end
			
			SIL_Console(name.." Cached "..age, true);
			return false;
		
		-- We can do something!
		else
			
			-- Start some information if we haven't seen them before
			if not ( SIL_CacheGUID[guid] ) then
				SIL_CacheGUID[guid] = {};
				SIL_CacheGUID[guid]['name'] = name;
				SIL_Console(name.." New", true);
			else
				SIL_Console(name.." reFresh", true);
			end
			
			-- Update the target information for this person
			SIL_CacheGUID[guid]['target'] = target;
			SIL_CacheGUID[guid]['tooltip'] = tooltip;
			
			-- Start the inspect
			NotifyInspect(target);
			
			-- Pass 1 and 2nd pass will be after the event fires
			SIL_ProcessInspect(guid, tooltip);
			
			return true;
		end
	else
		return false;
	end
end


--[[
	SIL_ProcessInspect(guid, showTooltip)
	returns false or the score and accuracy in %;
]]
function SIL_ProcessInspect(guid, tooltip)
	
	-- Incombat so we can't do anything
	if ( InCombatLockdown() ) then 
		return false;
	
	else
		
		-- We have some more information about this person
		if ( SIL_CacheGUID[guid] ) then
			local name = SIL_CacheGUID[guid]['name'];
			local target = SIL_CacheGUID[guid]['target'];
			
			SIL_Console('Processing '..name..' by '..target, true);
			
			-- Figure out wether or not to display the tooltip
			if not ( tooltip ) and not ( tooltip == false ) then
				tooltip = SIL_CacheGUID[guid]['tooltip'];
			end
			
			local totalItems = 0;
			local totalScore = 0;
			
			-- Loop all items
			for i = 1, 18 do
				
				-- Skip the Shirt
				if ( i ~= 4 ) then
					local itemLink = GetInventoryItemLink(target, i);
					
					-- We have a item link
					if ( itemLink ) then
						local _, _, itemRarity , itemLevel = GetItemInfo(itemLink);
						
						-- We have a valid itemLevel and its above white 1, and below artificat 6
						if ( itemLevel ) then
							
							-- special processing for Heirlooms
							if ( itemRarity == 7 ) then
								itemLevel = SIL_ScoreHeirloom(UnitLevel(target));
								SIL_Console('Item '..itemLink..' iLevel '..itemLevel, true);
							end
							
							totalItems = totalItems + 1;
							totalScore = totalScore + itemLevel;
						end
					end
				end
			end
			
			-- We have some items to give a score for!
			if ( totalItems > 0 ) then
				
				-- Set there score
				SIL_SetScore(totalItems, totalScore, guid);
				
				-- Get the score back, this is dumb but it avoids dupe code
				local score, accuracy = SIL_GetScore(guid);
				
				if ( tooltip ) then
					SIL_ShowTooltip(score, totalItems);
				end
				
				--- SIL_Console(name..' has '..totalItems..' items with a score or '..score..' and accuracy of '..accuracy..'%', true);
				return score, accuracy, 0;
			else
				--- SIL_Console(name..' has no items', true);
				return false;
			end
		else
			return false;
		end
	end
end

--[[
	SIL_ShowTooltip();
	Updates the tooltip information
]]
function SIL_ShowTooltip()
	local guid = UnitGUID("mouseover");
	
	if ( SIL_HasScore(guid) ) then
		
		local items = SIL_CacheGUID[guid]['items'];
		local score, accuracyPercent, age = SIL_GetScore(guid);
		local accuracy = SIL_GetAccuracy(items, false);
		
		-- We have a score so color it
		if ( accuracy == 1 ) then
			r,g,b = SIL_ColorScore(score);
		
		-- Its over 0.2 so make it gray
		elseif ( accuracy > 0.2 ) then
			r = SIL_Round(accuracy, 2);
			g = r;
			b = r;
		
		-- Limit it to 0.2
		else
			r = 0.2;
			g = 0.2;
			b = 0.2;
		end
		
		-- Fix 100.0%
		if ( accuracyPercent == '100.0' ) then
			accuracyPercent = '100';
		end
		
		-- Build text colors
		local rgbHex = SIL_RGBtoHex(tonumber(r),tonumber(g),tonumber(b));
		local accHex = SIL_RGBtoHex(accuracy,accuracy,accuracy);
		
		-- Build the tool tip text
		local textLeft1 = '|cFF216bff'..L['Tool Tip Left 1']..'|r ';
		local textRight1 = '|cFF'..rgbHex..SIL_Replace(L['Tool Tip Right 1'], 'score', SIL_Round(score, 1))..'|r';
		local textLeft2 = SIL_Replace(L['Tool Tip Left 2'], 'hex', accHex);
		textLeft2 = SIL_Replace(textLeft2, 'accuracy', accuracyPercent);
		local textRight2 = SIL_Replace(L['Tool Tip Right 2'], 'localizedAge', SIL_AgeToText(age));
		
		-- Loop tooltip text to check if its alredy there
		local ttLines = GameTooltip:NumLines();
		local ttUpdated = false;
		for i = 1,ttLines do
					
			-- If the static text matches
			if ( _G["GameTooltipTextLeft"..i]:GetText() == textLeft1 ) then
				
				-- Update the text
				_G["GameTooltipTextLeft"..i]:SetText(textLeft1);
				_G["GameTooltipTextRight"..i]:SetText(textRight1);
				GameTooltip:Show();
				
				-- Update the advanced info too
				if ( SIL_Settings['advanced'] ) then
					_G["GameTooltipTextLeft"..i+1]:SetText(textLeft2);
					_G["GameTooltipTextRight"..i+1]:SetText(textRight2);
					GameTooltip:Show();
				end
				
				-- Rember that we have updated the tool tip so we wont again
				ttUpdated = true;
				break;
			end
		end
		
		-- Tool tip is new
		if not ( ttUpdated ) then
			
			GameTooltip:AddDoubleLine(textLeft1, textRight1);
			GameTooltip:Show();
			
			if ( SIL_Settings['advanced'] ) then
				GameTooltip:AddDoubleLine(textLeft2, textRight2);
				GameTooltip:Show();
			end
		end
		
		return true;
	else
		return false;
	end
end;

--[[
	SIL_ColorScore(score);
	returns r,g,b for the a score
]]
function SIL_ColorScore(score)
--[[
-- GS Light code for quick referance
if ( ItemScore > 5999 ) then ItemScore = 5999; end
	local Red = 0.1; local Blue = 0.1; local Green = 0.1; local GS_QualityDescription = "Legendary"
   	if not ( ItemScore ) then return 0, 0, 0, "Trash"; end
	for i = 0,6 do
		if ( ItemScore > i * 1000 ) and ( ItemScore <= ( ( i + 1 ) * 1000 ) ) then
		    local Red = GS_Quality[( i + 1 ) * 1000].Red["A"] + (((ItemScore - GS_Quality[( i + 1 ) * 1000].Red["B"])*GS_Quality[( i + 1 ) * 1000].Red["C"])*GS_Quality[( i + 1 ) * 1000].Red["D"])
            local Blue = GS_Quality[( i + 1 ) * 1000].Green["A"] + (((ItemScore - GS_Quality[( i + 1 ) * 1000].Green["B"])*GS_Quality[( i + 1 ) * 1000].Green["C"])*GS_Quality[( i + 1 ) * 1000].Green["D"])
            local Green = GS_Quality[( i + 1 ) * 1000].Blue["A"] + (((ItemScore - GS_Quality[( i + 1 ) * 1000].Blue["B"])*GS_Quality[( i + 1 ) * 1000].Blue["C"])*GS_Quality[( i + 1 ) * 1000].Blue["D"])
			--if not ( Red ) or not ( Blue ) or not ( Green ) then return 0.1, 0.1, 0.1, nil; end
			return Red, Green, Blue, GS_Quality[( i + 1 ) * 1000].Description
		end
	end``````````````````````````````````````````````````````````````````
return 0.1, 0.1, 0.1
]]
	-- Only color over 133
	if ( score > 333 ) then
	
	else
		
	end
	
	return 1,1,1;
end

--[[
	SIL_TooltipHook();
	Called when you mouse over someone, should attempt to also do mouseover event
	return true or false if a tooltip was able to be shown
]]
function SIL_TooltipHook(arg1, arg2)
	
	-- Can't do anything if we are incombat
	if ( InCombatLockdown() ) then 
		return false; 
	else
		return SIL_ShowTooltip();
	end;
end;

--[[
	SIL_AgeToText(age);
]]
function SIL_AgeToText(age)
	if ( type(age) == 'number' ) then
		if ( age > 86400 ) then
			age = SIL_Round(age / 86400, 2);
			return SIL_Replace(L['Age Days'], 'age', '|cFFff0000'..age..'|r');
		elseif ( age > 3600 ) then
			age = SIL_Round(age / 3600, 1)
			return SIL_Replace(L['Age Hours'], 'age', '|cFF33ccff'..age..'|r');
		elseif ( age > 60 ) then
			age = SIL_Round(age / 60, 1)
			return SIL_Replace(L['Age Minutes'], 'age', '|cFF00ff00'..age..'|r');
		else
			return SIL_Replace(L['Age Seconds'], 'age', '|cFF00ff00'..age..'|r');
		end
	else
		return 'n/a';
	end
end


--[[
	SIL_Party(outputInfo)
	return false or partyAverage, partyTotal, partySize
]]
function SIL_Party(output)
	if ( GetNumPartyMembers() > 0 ) then
		local partySize = 0;
		local partyTotal = 0;
		
		-- Add yourself
		SIL_StartScore('player', true, false);
		local score, accuracy, age = SIL_ProcessInspect(UnitGUID('player'), false);
		
		if ( score ) then
			partySize = partySize + 1;
			partyTotal = partyTotal + score;
			
			if ( output ) then
				local str = SIL_Replace(L['Party Member Score'], 'name', UnitName('player'));
				str = SIL_Replace(str, 'score', SIL_Round(score, 1));
				str = SIL_Replace(str, 'accuracy', accuracy);
				str = SIL_Replace(str, 'ageLocal', SIL_AgeToText(age));
				
				SIL_Console(str);
			end
		end
		
		for i = 1,4 do
			if ( GetPartyMember(i) ) then
				local name = UnitName('party'..i);
				local guid = UnitGUID('party'..i);
				local score = false;
				
				-- Try and refresh the information
				if ( CanInspect(name) ) then
					SIL_StartScore(name, true, false);
					score, accuracy, age = SIL_ProcessInspect(guid, false);
				
				-- We couldn't inspect so try from the cache
				elseif ( SIL_HasScore(guid) ) then
					score, accuracy, age = SIL_GetScore(guid);
				end
				
				-- They have a score so count them
				if ( score ) then
					partySize = partySize + 1;
					partyTotal = partyTotal + score;
					
					if ( output ) then
						
						local str = SIL_Replace(L['Party Member Score'], 'name', SIL_Strpad(name, 20));
						str = SIL_Replace(str, 'score', SIL_Round(score, 1));
						str = SIL_Replace(str, 'accuracy', accuracy);
						str = SIL_Replace(str, 'ageLocal', SIL_AgeToText(age));
				
						SIL_Console(str);
					end
				else
					if ( output ) then
						SIL_Console(SIL_Replace(L['Party Member Score False'], 'name', SIL_Strpad(name, 20)));
					end
				end
			end
		end
		
		if ( partySize > 0 ) then
			local partyAverage = partyTotal / partySize;
			
			if ( output ) then
				SIL_Console("------------------------");
				
				local str = SIL_Replace(L['Party Score'], 'score', SIL_Round(partyAverage, 1));
				str = SIL_Replace(str, 'number', partySize);
				
				SIL_Console(str);
			end
			
			return partyAverage, partyTotal, partySize;
		else 
			return false;
		end
	else
		if ( output ) then
			SIL_Console(L['Party False']);
		end
		
		return false;
	end
end

--[[
	SIL_Raid(outputInfo);
	returns false or raidAverage, raidTotal, raidSize
]]
function SIL_Raid(output)
	
	if ( UnitInRaid("player") ) then
		local raidSize = 0;
		local raidTotal = 0;
		
		for i = 1, 40 do
			name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(i);
			
			if ( name ) then
				
				local guid = UnitGUID(name);
				local score = false;
				
				-- Start Inspecting if they are in range
				if ( CanInspect(name) ) then
					SIL_StartScore(name, true, false);
					score, accuracy, age = SIL_ProcessInspect(guid, false);
				
				-- We couldn't inspect so try from the cache
				elseif ( SIL_HasScore(guid) ) then
					score, accuracy, age = SIL_GetScore(guid);
				end
				
				-- They have a score so count them
				if ( score ) then
					raidSize = raidSize + 1;
					raidTotal = raidTotal + score;
					
					if ( output ) then
						
						local str = SIL_Replace(L['Raid Member Score'], 'name', SIL_Strpad(name, 20));
						str = SIL_Replace(str, 'score', SIL_Round(score, 1));
						str = SIL_Replace(str, 'accuracy', accuracy);
						str = SIL_Replace(str, 'ageLocal', SIL_AgeToText(age));
				
						SIL_Console(str);
					end
				else
					if ( output ) then
						SIL_Console(SIL_Replace(L['Raid Member Score False'], 'name', SIL_Strpad(name, 20)));
					end
				end
			end
		end
		
		if ( raidSize > 0 ) then
			local raidAverage = raidTotal / raidSize;
			
			if ( output ) then
				SIL_Console("------------------------");
				
				local str = SIL_Replace(L['Raid Score'], 'score', SIL_Round(raidAverage, 1));
				str = SIL_Replace(str, 'number', raidSize);
				
				SIL_Console(str);
			end
			
			return raidAverage, raidTotal, raidSize;
		else 
			return false;
		end
	else
		if ( output ) then
			SIL_Console(L['Raid False']);
		end
		
		return false;
	end
end


--[[
	SIL_SlashCommand(command);
	handleing of /sil
]]
function SIL_SlashCommand(command)
	
	-- Break up the command
	local command, value = command:match("^(%S*)%s*(.-)$");
	command = strlower(command);
	number = tonumber(value);
	
	-- clear all the settings
	if ( command == "clear" ) then
		SIL_Console(L['Slash Clear']);
		SIL_Initialize();
	
	-- Toggle debug mode
	elseif ( command == "debug" ) then
		if ( SIL_Debug ) then
			SIL_Console("Debug Off");
			SIL_Debug = false;
		else
			SIL_Console("Debug On");
			SIL_Debug = true;
		end

	-- Toggle debug mode
	elseif ( command == "advanced" ) then
		if ( SIL_Settings['advanced'] ) then
			SIL_Console(L['Slash Advanced Off']);
			SIL_Settings['advanced'] = false;
		else
			SIL_Console(L['Slash Advanced On']);
			SIL_Settings['advanced'] = true;
		end
	
	-- Get the AiL of your target
	elseif ( command == "target" ) or (( command == "get" ) and ( value == '' )) then
		
		-- Make sure we can inspect
		if ( CanInspect('target') ) then
		
			SIL_StartScore('target', true, false);
			local score, accuracy = SIL_ProcessInspect(UnitGUID('target'), false);
			
			
			if ( score ) then
				local str = SIL_Replace(L['Slash Target Score True'], 'target', UnitName('target'));
				str = SIL_Replace(str, 'score', SIL_Round(score, 1));
				str = SIL_Replace(str, 'accuracy', accuracy);
				
				SIL_Console(str);
				
			else
				SIL_Console(L['Slash Target Score False']);
			end
		else
			SIL_Console(L['Slash Target Score False']);
		end
	
	-- Get the AiL of someone by name
	elseif ( command == "get" ) and ( value ) then
		
		SIL_Console("Trying to get a score for "..value, true);
		
		-- Check that we have a score
		if ( SIL_HasScore(value) ) then
			
			local score, accuracy, age = SIL_GetScore(value);
			
			if ( score ) then
				
				-- Make the age legable
				age = SIL_AgeToText(age);
				
				local str = L['Slash Get Score True'];
				str = SIL_Replace(str, 'target', value);
				str = SIL_Replace(str, 'score', SIL_Round(score, 1));
				str = SIL_Replace(str, 'accuracy', accuracy);
				str = SIL_Replace(str, 'ageLocal', age);
				
				SIL_Console(str);
				
			-- This shouldn't happen
			else
				SIL_Console("Error 3456: HasScore is true but GetScore is false!", true);
				SIL_Console("Error 3456: HasScore is true but GetScore is false!", true);
				SIL_Console("Error 3456: HasScore is true but GetScore is false!", true);
				
				SIL_Console(SIL_Replace(L['Slash Target Score False'], 'target', value));
			end
		else
			SIL_Console(SIL_Replace(L['Slash Target Score False'], 'target', value));
		end
	
	-- Set the accuracy 1-18
	elseif ( command == "accuracy" ) and ( number ) and ( 0 < number ) and ( number < 19 ) then
		SIL_Settings['accuracy'] = number;
		SIL_Console(SIL_Replace(L['Slash Accuracy Change'], 'items', SIL_Settings['accuracy']));
	
	-- Set the max age
	elseif (( command == "cache" ) or ( command == "age" )) and ( number ) then
		SIL_Settings['age'] = number;
		SIL_Console(SIL_Replace(L['Slash Age Change'], 'timeInSeconds', SIL_Settings['age']));
	
	-- Display party information
	elseif ( command == "party" ) then
		SIL_Party(true);
		
	-- Display raid information
	elseif ( command == "raid" ) then
		SIL_Raid(true);
		
	
	-- Display the help
	else
		
		-- Get the score for the player
		SIL_StartScore('player', true, false);
		local score, accuracy = SIL_ProcessInspect(UnitGUID('player'), false);
		
		SIL_Console(L['Help1']);
		SIL_Console(L['Help2']);
		SIL_Console(L['Help3']);
		SIL_Console(L['Help4']);
		SIL_Console(L['Help5']);
		SIL_Console(L['Help6']);
		SIL_Console(L['Help7']);
		SIL_Console(L['Help8']);
		SIL_Console(L['Help9']);
		SIL_Console(L['Help10']);
		
		if ( score ) then
			SIL_Console('-----------------------');
			SIL_Console(SIL_Replace(L['Your Score'], 'score', SIL_Round(score, 1)));
		end
	end
end

--[[
	SIL_Replace(string, variable, value)
	replace a %variable with a value
	return string
]]
function SIL_Replace(str, var, value)
	
	if ( str ) and ( var ) and ( value ) then
		str = string.gsub(str, '%%'..var, value);
	end
	
	return str;
end

--[[
	SIL_Round(number, decimals)
	from http://www.wowpedia.org/Round
	returns a rounded number
]]
function SIL_Round(number, decimals)
    return (("%%.%df"):format(decimals)):format(number)
end

--[[
	SIL_RGBtoHex(r, g, b)
	from http://www.wowpedia.org/RGBPercToHex
	returns a rounded number
]]
function SIL_RGBtoHex(r, g, b)
	r = r <= 1 and r >= 0 and r or 0
	g = g <= 1 and g >= 0 and g or 0
	b = b <= 1 and b >= 0 and b or 0
	return string.format("%02x%02x%02x", r*255, g*255, b*255)
end

--[[
	SIL_Console(message, debugMode);
	ouputs a message to the console, if debugMode=true and SIL_Debug outputs the debug info 
]]
function SIL_Console(message, debugMode) 
	if ( SIL_Debug ) and ( debugMode ) then
		print("|cFFbbbbbbDebug:|r "..message);
	elseif not ( debugMode ) and ( message ) then
		print("|cFF216bff"..L['Addon Short Name']..":|r "..message);
	end;
end;

--[[
	SIL_Strpad(string, length, pad);
	pads a string to a set length with pad
	returns string
]]
function SIL_Strpad(str, length, pad)
	if not ( padd ) then
		padd = ' ';
	end
	
	while str.len() < length do
		str = str..pad;
	end
	
	return str;
end

-- Create the frame and register the events
local f = CreateFrame("Frame", "SimpleItemLevel", UIParent);
f:SetScript("OnEvent", SIL_OnEvent);
f:RegisterEvent("ADDON_LOADED");
f:RegisterEvent("INSPECT_READY");
f:RegisterEvent("PLAYER_TARGET_CHANGED");
f:RegisterEvent("UPDATE_MOUSEOVER_UNIT");

-- Hook the tooltip for units
-- GameTooltip:HookScript("OnTooltipSetUnit", SIL_TooltipHook);

-- Set up the slash command information
SlashCmdList["SIMPLEILEVEL"] = SIL_SlashCommand;
SLASH_SIMPLEILEVEL1 = "/sil";
SLASH_SIMPLEILEVEL3 = "/silvl";
SLASH_SIMPLEILEVEL2 = "/simpleitemlevel";