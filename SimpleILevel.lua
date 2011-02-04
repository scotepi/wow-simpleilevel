--[[
	Total Rewrite:
	---------------------------------------
	To Do List for 1.0:
	* Tweeks and bug fixes
	
	To Do List for 2.0:
	* Add options for displaying AiL in chat next to names
	* Move to a .xml UI
	* Add a simple UI for displaying party and raid scores
	* Purge cache older then X days
	
	To-Do List for 2.0 and beyond:
	* Add SiL's AiL to your charciter information sheet
	* Add the AiL to the inspect window
	* UI for viwing the cache - porb same time as party/raid ui
	* More mathmatical stats for party and raid, min, max, std dev
	
	Known Issues:
	* Blizzard_InspectUI\InspectPaperDollFrame.lua errors are bugs in the default UI
	* Level 80 heirlooms on level 81+ return the wrong iLevel
	* Doesn't work on heath or mana bars when you target someone, this is a bug, there is no UnitName("mouseover") or UnitGUID("mouseover") there
	
	Changelog for 0.7: 2011-02-03
	* Cleaned up party and raid display some more, removing age when its current, less then 30sec
	* This will most likely become 1.0 for 4.0.6 patch
	* Fixed the advanced line to be a single line insted of double, no more spacing issue with localization
	* Added colorization to all scores!
		White->Yellow = 1-200
		Yellow->Green = 200-333
		Green->Blue = 333-376
		More to come when t12 iLevel is known
]]

-- Local Variables
local addonName, L = ...;
local SIL_Loaded = false;
local SIL_Debug = false;
local SIL_Version = 0.7;

-- Color constants
local SIL_ColorIndex = {0,200,333,379,1000};
local SIL_Colors = {
	-- White base color
	[0] = 		{['r']=255,	['g']=255,	['b']=255,	['p']=0,},
	-- Yellow for wrath dungeon gear
	[200] = 	{['r']=255,	['g']=204,	['b']=0,	['p']=0,},
	-- Green for cata dungeon
	[333] = 	{['r']=0,	['g']=204,	['b']=0,	['p']=200,},
	-- Blue for heroic t11 final gear
	[379] = 	{['r']=0,	['g']=102,	['b']=204,	['p']=333,},
	-- Red for a max score
	[1000] = 	{['r']=255,	['g']=0,	['b']=0,	['p']=379},
};


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
	SIL_Settings['advanced'] = false;		-- Display extra information in the tooltips
	SIL_Settings['version'] = SIL_Version;	-- Version for future referance
end;

--[[
	SIL_Upgrade();
	attempts to upgrade from a older version or resets the settings
]]
function SIL_Upgrade()
	
	local oldVersion = SIL_Settings['version'];
	
	if ( oldVersion < 0.63 ) and ( SIL_Settings['accuracy'] ) then
		SIL_Settings['accuracy'] = nil;
	end
	
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
	returns false or score, age and items
]]
function SIL_GetScore(target)
	
	-- It looks like a name, convert to guid
	if not ( tonumber(target) ) then
		target = SIL_NameToGUID(target);
	end
	
	if ( SIL_CacheGUID[target] ) and ( SIL_CacheGUID[target]['items'] ) then
		
		-- Return the unformated score and age
		local score = SIL_CacheGUID[target]['total'] / SIL_CacheGUID[target]['items'];
		local age = time() - SIL_CacheGUID[target]['time'];
		return score, age, SIL_CacheGUID[target]['items'];
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
		local score, age, items = SIL_GetScore(guid);
		
		-- Some debuging
		if ( score ) then
			SIL_Console(name.." score:"..score.." age:"..age, true);
		end
		
		-- We have a score and its under age and has over 5 items
		if ( score ) and ( age < SIL_Settings['age'] ) and ( items > 5 ) then
			
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
	returns false or the score
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
				local score = SIL_GetScore(guid);
				
				if ( tooltip ) then
					SIL_ShowTooltip();
				end
				
				return score, 0, totalItems;
			else
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
		
		local score, age, items = SIL_GetScore(guid);
		
		-- Build the tool tip text
		local textLeft = '|cFF216bff'..L['Tool Tip Left']..'|r ';
		local textRight = SIL_Replace(L['Tool Tip Right'], 'score', SIL_FormatScore(score, items));
		
		local textAdvanced = SIL_Replace(L['Tool Tip Advanced'], 'localizedAge', SIL_AgeToText(age));
		
		-- Loop tooltip text to check if its alredy there
		local ttLines = GameTooltip:NumLines();
		local ttUpdated = false;
		
		for i = 1,ttLines do
					
			-- If the static text matches
			if ( _G["GameTooltipTextLeft"..i]:GetText() == textLeft ) then
				
				-- Update the text
				_G["GameTooltipTextLeft"..i]:SetText(textLeft);
				_G["GameTooltipTextRight"..i]:SetText(textRight);
				GameTooltip:Show();
				
				-- Update the advanced info too
				if ( SIL_Settings['advanced'] ) then
					_G["GameTooltipTextLeft"..i+1]:SetText(textAdvanced);
					GameTooltip:Show();
				end
				
				-- Rember that we have updated the tool tip so we wont again
				ttUpdated = true;
				break;
			end
		end
		
		-- Tool tip is new
		if not ( ttUpdated ) then
			
			GameTooltip:AddDoubleLine(textLeft, textRight);
			GameTooltip:Show();
			
			if ( SIL_Settings['advanced'] ) then
				GameTooltip:AddLine(textAdvanced);
				GameTooltip:Show();
			end
		end
		
		return true;
	else
		return false;
	end
end;

--[[
	SIL_FormatScore(score, items);
	takes a score and item count and returns a colored text string with the score
	returns colored string
]]
function SIL_FormatScore(score, items)
	local hexColor = SIL_ColorScore(score, items);
	local score = SIL_Round(score, 1);
	
	return '|cFF'..hexColor..score..'|r';
end

--[[
	SIL_ColorScore(score);
	returns hex color for the a score
]]
function SIL_ColorScore(score, items)
	-- Default to white
	local r,g,b = 1,1,1;
	
	local found = false;
	
	for i,maxScore in pairs(SIL_ColorIndex) do
		if ( score < maxScore ) and not ( found ) then
			local colors = SIL_Colors[maxScore];
			local baseColors = SIL_Colors[colors['p']];
			
			local steps = maxScore - colors['p'];
			local scoreDiff = score - colors['p'];
			
			local diffR = (baseColors['r'] - colors['r']) / 255;
			local diffG = (baseColors['g'] - colors['g']) / 255;
			local diffB = (baseColors['b'] - colors['b']) / 255;
			
			local diffStepR = diffR / steps;
			local diffStepG = diffG / steps;
			local diffStepB = diffB / steps;
			
			local scoreDiffR = scoreDiff * diffStepR;
			local scoreDiffG = scoreDiff * diffStepG;
			local scoreDiffB = scoreDiff * diffStepB;
			
			r = (baseColors['r'] / 255) - scoreDiffR;
			g = (baseColors['g'] / 255) - scoreDiffG;
			b = (baseColors['b'] / 255) - scoreDiffB;
			
			found = true;
		end
	end
	
	-- Nothing was found so red
	if not ( found ) then
		r = SIL_Colors[1000]['r'];
		g = SIL_Colors[1000]['g'];
		b = SIL_Colors[1000]['b'];
	end
	
	-- There are some missing items so gray
	if ( items ) and ( items < 6 ) then
		return SIL_RGBtoHex(0.5,0.5,0.5);
	else
		return SIL_RGBtoHex(r,g,b);
	end
end

-- Quick function for testing color ranges
function SIL_ColorTest(l,h)
	for i = l,h do
		print("Testing "..i.." "..SIL_FormatScore(i));
	end
end

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
		local score, age, items = SIL_ProcessInspect(UnitGUID('player'), false);
		
		if ( score ) then
			partySize = partySize + 1;
			partyTotal = partyTotal + score;
			
			if ( output ) then
			
				local str = L['Party Member Score'];
						
				if ( age < 30 ) then
					str = L['Party Member Score Fresh'];
				end
						
				str = SIL_Replace(str, 'name', SIL_Strpad(UnitName('player'), 20));
				str = SIL_Replace(str, 'score', SIL_FormatScore(score, items));
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
					score, age, items = SIL_ProcessInspect(guid, false);
				
				-- We couldn't inspect so try from the cache
				elseif ( SIL_HasScore(guid) ) then
					score, age, items = SIL_GetScore(guid);
				end
				
				-- They have a score so count them
				if ( score ) then
					partySize = partySize + 1;
					partyTotal = partyTotal + score;
					
					if ( output ) then
						
						local str = L['Party Member Score'];
						
						if ( age < 30 ) then
							str = L['Party Member Score Fresh'];
						end
						
						str = SIL_Replace(str, 'name', SIL_Strpad(name, 20));
						str = SIL_Replace(str, 'score', SIL_FormatScore(score, items));
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
				
				local str = SIL_Replace(L['Party Score'], 'score', SIL_FormatScore(partyAverage));
				str = SIL_Replace(str, 'number', partySize);
				
				SIL_Console(str);
			end
			
			return partyAverage, partyTotal, partySize;
		else 
			return false;
		end
	else
		if ( output ) then
			SIL_Console(ERR_NOT_IN_GROUP);
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
					score, age, items = SIL_ProcessInspect(guid, false);
				
				-- We couldn't inspect so try from the cache
				elseif ( SIL_HasScore(guid) ) then
					score, age, items = SIL_GetScore(guid);
				end
				
				-- They have a score so count them
				if ( score ) then
					raidSize = raidSize + 1;
					raidTotal = raidTotal + score;
					
					if ( output ) then
						
						local str = L['Raid Member Score'];
						
						if ( age < 30 ) then
							str = L['Raid Member Score Fresh'];
						end
						
						
						str = SIL_Replace(str, 'name', SIL_Strpad(name, 20));
						str = SIL_Replace(str, 'score', SIL_FormatScore(score, items));
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
				
				local str = SIL_Replace(L['Raid Score'], 'score', SIL_FormatScore(raidAverage));
				str = SIL_Replace(str, 'number', raidSize);
				
				SIL_Console(str);
			end
			
			return raidAverage, raidTotal, raidSize;
		else 
			return false;
		end
	else
		if ( output ) then
			SIL_Console(ERR_NOT_IN_RAID);
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
			local score, age, items = SIL_ProcessInspect(UnitGUID('target'), false);
			
			
			if ( score ) then
				local str = SIL_Replace(L['Slash Target Score True'], 'target', UnitName('target'));
				str = SIL_Replace(str, 'score', SIL_FormatScore(score, items));
				
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
			
			local score, age, items = SIL_GetScore(value);
			
			if ( score ) then
				
				-- Make the age legable
				age = SIL_AgeToText(age);
				
				local str = L['Slash Get Score True'];
				str = SIL_Replace(str, 'target', value);
				str = SIL_Replace(str, 'score', SIL_FormatScore(score, items));
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
		local score, age, items = SIL_ProcessInspect(UnitGUID('player'), false);
		
		SIL_Console(L['Addon Name'].." - v"..SIL_Version);
		SIL_Console(L['Help Help']);
		SIL_Console(L['Help Clear']);
		SIL_Console(L['Help Advanced']);
		SIL_Console(L['Help Target']);
		SIL_Console(L['Help Get']);
		SIL_Console(L['Help Age']);
		SIL_Console(L['Help Party']);
		SIL_Console(L['Help Raid']);
		
		if ( score ) then
			SIL_Console('-----------------------');
			SIL_Console(SIL_Replace(L['Your Score'], 'score', SIL_FormatScore(score, items)));
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
	if not ( pad ) then
		pad = ' ';
	end
	
	while string.len(str) < length do
		str = str..pad;
	end
	
	return str;
end

-- Create the frame and register the events
local f = CreateFrame("Frame", "SimpleItemLevel", UIParent);
f:SetScript("OnEvent", SIL_OnEvent);
f:RegisterEvent("ADDON_LOADED");			-- Processing settings
f:RegisterEvent("PLAYER_TARGET_CHANGED");	-- Initating the inspect process
f:RegisterEvent("INSPECT_READY");			-- Finishing the inspect process
f:RegisterEvent("UPDATE_MOUSEOVER_UNIT");	-- Showing and updating tool tips

-- Set up the slash command information
SlashCmdList["SIMPLEILEVEL"] = SIL_SlashCommand;
SLASH_SIMPLEILEVEL1 = "/sil";
SLASH_SIMPLEILEVEL3 = "/silvl";
SLASH_SIMPLEILEVEL2 = "/simpleitemlevel";