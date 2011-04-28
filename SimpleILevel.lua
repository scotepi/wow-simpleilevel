SIL = LibStub("AceAddon-3.0"):NewAddon("SimpleILevel", "AceEvent-3.0", "AceConsole-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("SimpleILevel", true);
SIL_AC = LibStub:GetLibrary("AceConfig-3.0");
SIL_ACD = LibStub:GetLibrary("AceConfigDialog-3.0");
SIL_LDB = LibStub:GetLibrary("LibDataBroker-1.1");
SIL_LDBIcon = SIL_LDB and LibStub("LibDBIcon-1.0");
SIL_Version = '2.0';

function SIL:OnInitialize()
	
	-- Version Info
	self.versionMajor = 2.0;
	self.versionMinor = 16;
	self.version = '2.0.16b';
	SIL_Version = self.version;
	
	-- Load the DB
	self.db = LibStub("AceDB-3.0"):New("SIL_Settings", SIL_Defaults, true);
	self.db.version = self.VersionMajor;
	self.db.versionMinor = self.VersionMinor;
	
	-- Make sure we can cache
	if not ( type(SIL_CacheGUID) == 'table' ) then
		SIL_CacheGUID = {};
	end
	
	-- Start LDB
	self.ldb = SIL_LDB:NewDataObject("SimpleILevel", {
		type = "launcher",
		icon = "Interface\\Icons\\inv_misc_armorkit_24",
		OnClick = function(f,b)
					SIL:OpenMenu();
			end,
		OnTooltipShow = function(tt)
							tt:AddLine(L["Addon Name"]);
		end,
		});
	
	-- Start the minimap icon
	SIL_LDBIcon:Register("SimpleILevel", self.ldb, self.db.global.minimap);
	
	-- Register Options
	SIL_Options.args.purge.desc = SIL:Replace(L['Help Purge Desc'], 'num', self.db.global.purge / 24);
	SIL_AC:RegisterOptionsTable("SimpleILevel", SIL_Options, {"sil", "silev", "simpleilevel"});
	SIL_ACD:AddToBlizOptions("SimpleILevel");
	
	-- Tell the player we have been loaded
	self:Print(self:Replace(L['Loading Addon'], 'version', self.version));
	
	-- Register Events
	self:RegisterEvent("PLAYER_TARGET_CHANGED");
	self:RegisterEvent("INSPECT_READY");
	self:RegisterEvent("UPDATE_MOUSEOVER_UNIT");
	self:Autoscan(self.db.global.autoscan);
	
	-- Auto Purge the cache
	SIL:AutoPurge(true);
end

function SIL:PLAYER_TARGET_CHANGED(e, target)
	if not ( target ) then
		target = 'target';
	end
	
	if ( CanInspect(target) ) then
		self:StartScore(target, false, true);
	end
end

function SIL:INSPECT_READY(e, guid)
	self:ProcessInspect(guid);
end

function SIL:UPDATE_MOUSEOVER_UNIT()
	self:ShowTooltip();
end

-- Reset the settings
function SIL:Reset()
	self:Print(L["Slash Clear"]);
	self.db.global:ResetProfile();
	SIL:SetMinimap(true);
end

-- Clear the cache
function SIL:AutoPurge(silent)
	if ( self.db.global.purge > 0 ) then
		local count = SIL:PurgeCache(self.db.global.purge);
		
		if not ( silent ) then
			SIL:Print(SIL:Replace(L['Purge Notification'], 'num', count));
		end
		
		return count;
	else
		if not ( silent ) then
			SIL:Print(L['Purge Notification False']);
		end
		
		return false;
	end
end

function SIL:PurgeCache(hours)
	if ( tonumber(hours) ) then
		local maxAge = time() - ( tonumber(hours) * 3600 );
		local count = 0;
		
		for guid,info in pairs(SIL_CacheGUID) do
			if ( info['time'] < maxAge ) then
				SIL_CacheGUID[guid] = nil;
				count = 1 + count;
			end
		end
		
		return count;
	else
		return false;
	end
end

function SIL:Strpad(str, length, pad)
	if not ( pad ) then
		pad = ' ';
	end
	
	length = tonumber(length);
	
	if ( type(length) == "number" ) then
		while string.len(str) < length do
			str = str..pad;
		end
	end
	
	return str;
end

function SIL:Replace(str, var, value)
	if ( str ) and ( var ) and ( value ) then
		str = string.gsub(str, '%%'..var, value);
	end
	
	return str;
end

-- from http://www.wowpedia.org/Round
function SIL:Round(number, decimals)
    return (("%%.%df"):format(decimals)):format(number);
end

-- from http://www.wowpedia.org/RGBPercToHex
function SIL:RGBtoHex(r, g, b)
	r = r <= 1 and r >= 0 and r or 0
	g = g <= 1 and g >= 0 and g or 0
	b = b <= 1 and b >= 0 and b or 0
	return string.format("%02x%02x%02x", r*255, g*255, b*255)
end

function SIL:GUIDtoName(guid)
	if ( SIL_CacheGUID[guid] ) then
		return SIL_CacheGUID[guid]['name'];
	else
		return false;
	end
end

function SIL:NameToGUID(name, realm)
	if ( name ) then
		name = strlower(name);
		
		for guid,info in pairs(SIL_CacheGUID) do
			if ( strlower(info['name']) == name ) and ( info['realm'] == realm ) then
				return guid;
			end
		end
	end
	
	return false;
end

-- Make sure we have a GUID
function SIL:GetGUID(target)
	if not ( tonumber(target) ) then
		return SIL:NameToGUID(target);
	else
		return target;
	end
end

-- Check if someone has a score
function SIL:HasScore(target)
	
	
	if ( SIL_CacheGUID[target] ) and ( SIL_CacheGUID[target]['items'] ) then
		return true;
	else
		return false;
	end
end

-- Clear score
function SIL:ClearScore(target)
	target = self:GetGUID(target);
	
	if ( SIL_CacheGUID[target] ) and ( SIL_CacheGUID[target]['items'] )then
		SIL_CacheGUID[target]['items'] = false;
		SIL_CacheGUID[target]['total'] = false;
		SIL_CacheGUID[target]['time'] = false;
		
		return true;
	else
		return false;
	end
end;

-- Get someones score
function SIL:GetScore(target)
	target = self:GetGUID(target);
	
	if ( SIL_CacheGUID[target] ) and ( SIL_CacheGUID[target]['items'] ) then
		local score = SIL_CacheGUID[target]['total'] / SIL_CacheGUID[target]['items'];
		local age = time() - SIL_CacheGUID[target]['time'];
		local items = SIL_CacheGUID[target]['items'];
		
		return score, age, items;
	else
		return false;
	end
end

-- Set someones score
function SIL:SetScore(items, total, guid)
	if ( items ) and ( total ) and ( guid ) then
		SIL_CacheGUID[guid]['items'] = items;
		SIL_CacheGUID[guid]['total'] = total;
		SIL_CacheGUID[guid]['time'] = time();
		
		return true;
	else
		return false;
	end
end

-- Get a relative iLevel on Heirlooms
function SIL:Heirloom(level)
	--[[
		Here is how I came to the level 81-85 bracket
		200 = level of 80 instance gear
		333 = level of 85 instance gear
		333 - 200 = 133 iLevels / 5 levels = 26.6 iLevel / level
		so then that means
		85 - 80 = 5 * 26.6 = 133 + 200 = 333
	]]
	
	if ( level > 80 ) then
		return (( level - 80 ) * 26.6) + 200;
	elseif ( level > 70 ) then
		return (( level - 70 ) * 10) + 100;
	elseif ( level > 60 ) then
		return (( level - 60 ) * 4) + 60;
	else
		return level;
	end
end

-- Formate the score
function SIL:FormatScore(score, items, color)
	if ( type(color) == "nil" ) then color = true; end
	
	if ( tonumber(score) ) then
		local score = tonumber(score);
		local hexColor = self:ColorScore(score, items);
		local score = self:Round(score, 1);
		
		if ( color ) then
			return '|cFF'..hexColor..score..'|r';
		else
			return score;
		end
	else
		return 'xx';
	end
end

function SIL:ColorScore(score, items)
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
		return self:RGBtoHex(0.5,0.5,0.5), 0.5,0.5,0.5;
	else
		return self:RGBtoHex(r,g,b), r, g, b;
	end
end

function SIL:ForceGet(target)
	if ( type(target) == 'nil' ) then target = 'target'; end
	if ( target == '' ) then target = 'target'; end
	if not ( target ) then target = 'target'; end
	
	-- Current target
	if ( target == 'target' ) then
		if ( CanInspect('target') ) then
			SIL:StartScore('target', true, false);
			local score, age, items = SIL:ProcessInspect(UnitGUID('target'), false);
			
			if ( score ) then
				local str = SIL:Replace(L['Slash Target Score True'], 'target', UnitName('target'));
				str = SIL:Replace(str, 'score', SIL:FormatScore(score, items));
				
				SIL:Print(str);
				
			else
				SIL:Print(L['Slash Target Score False']);
			end
		else
			self:Print(L['Slash Target Score False']);
		end
	
	-- Call by name
	elseif not ( target == '' ) then
		local score, age, items = SIL:GetScore(target);
		
		if ( score ) then
			age = self:AgeToText(age);
			
			local str = L['Slash Get Score True'];
			str = self:Replace(str, 'target', SIL_CacheGUID[SIL:NameToGUID(target)]['name']);
			str = self:Replace(str, 'score', self:FormatScore(score, items));
			str = self:Replace(str, 'ageLocal', age);
			
			self:Print(str);
		else
			self:Print(self:Replace(L['Slash Target Score False'], 'target', value));
		end
	else 
		self:Print(L['Slash Target Score False']);
	end
end

function SIL:ShowTooltip()
	local guid = UnitGUID("mouseover");
	
	if ( self:HasScore(guid) ) then
		
		local score, age, items = self:GetScore(guid);
		
		-- Build the tool tip text
		local textLeft = '|cFF216bff'..L['Tool Tip Left']..'|r ';
		local textRight = self:Replace(L['Tool Tip Right'], 'score', self:FormatScore(score, items));
		
		local textAdvanced = self:Replace(L['Tool Tip Advanced'], 'localizedAge', self:AgeToText(age));
		
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
				if ( self.db.global.advanced ) then
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
			
			if ( self.db.global.advanced ) then
				GameTooltip:AddLine(textAdvanced);
				GameTooltip:Show();
			end
		end
		
		return true;
	else
		return false;
	end
end;

--------------------------------------------------------------------
--------------------------------------------------------------------
------------ I got lazy, this is copy and paste, no re-write -------
--------------------------------------------------------------------
--------------------------------------------------------------------

function SIL:ColorTest(l,h)
	for i = l,h do
		self:Print("Testing "..i.." "..self:FormatScore(i));
	end
end

function SIL:AgeToText(age, color)
	if ( type(color) == "nul" ) then color = false; end
	
	if ( type(age) == 'number' ) then
		if ( age > 86400 ) then
			age = self:Round(age / 86400, 2);
			str = L['Age Days'];
			hex = "ff0000";
		elseif ( age > 3600 ) then
			age = self:Round(age / 3600, 1);
			str = L['Age Hours'];
			hex = "33ccff";
		elseif ( age > 60 ) then
			age = self:Round(age / 60, 1);
			str = L['Age Minutes'];
			hex = "00ff00";
		else
			age = age;
			str = L['Age Seconds'];
			hex = "00ff00";
		end
		
		if ( color ) then
			return self:Replace(str, 'age', '|cFF'..hex..age..'|r');
		else
			return self:Replace(str, 'age', age);
		end
	else
		return 'n/a';
	end
end

function SIL:Party(output, dest, to)
	if not ( dest ) then dest = "print"; end
	
	if ( GetNumPartyMembers() > 0 ) then
		local partySize = 0;
		local partyTotal = 0;
		local party = {};
		local partyMin = false;
		local partyMax = 0;
		
		-- Add yourself
		self:StartScore('player', true, false);
		local score, age, items = self:ProcessInspect(UnitGUID('player'), false);
		
		if ( score ) then
			partySize = partySize + 1;
			partyTotal = partyTotal + score;
			table.insert(party, { ['name'] = name, ['score'] = score, ['age'] = age, ['level'] = UnitLevel('player'), });
			partyMin = score;
			partyMax = score;
				
			if ( output ) then
			
				local str = L['Party Member Score'];
				
				if ( age < 30 ) then
					str = L['Party Member Score Fresh'];
				end
				
				if ( dest == "print" ) then
					str = self:Replace(str, 'score', self:FormatScore(score, items, true));
					str = self:Replace(str, 'ageLocal', self:AgeToText(age, true));
				else
					str = self:Replace(str, 'score', self:FormatScore(score, items, false));
					str = self:Replace(str, 'ageLocal', self:AgeToText(age, false));
				end
				
				str = self:Replace(str, 'name', self:Strpad(UnitName('player'), L["Max UnitName"]));
				
				self:PrintTo(str, dest, to);
			end
		end
		
		for i = 1,4 do
			if ( GetPartyMember(i) ) then
				local name = UnitName('party'..i);
				local guid = UnitGUID('party'..i);
				local score = false;
				
				-- Try and refresh the information
				if ( CanInspect(name) ) then
					self:StartScore(name, true, false);
					score, age, items = self:ProcessInspect(guid, false);
				
				-- We couldn't inspect so try from the cache
				elseif ( self:HasScore(guid) ) then
					score, age, items = self:GetScore(guid);
				end
				
				-- They have a score so count them
				if ( score ) then
					partySize = partySize + 1;
					partyTotal = partyTotal + score;
					
					table.insert(party, { ['name'] = name, ['score'] = score, ['age'] = age, ['level'] = UnitLevel('party'..i), });
					
					if ( score < partyMin ) then
						partyMin = score;
					end
					
					if ( score > partyMax ) then
						partyMax = score;
					end
					
					if ( output ) then
						
						local str = L['Party Member Score'];
						
						if ( age < 30 ) then
							str = L['Party Member Score Fresh'];
						end
						
						if ( dest == "print" ) then
							str = self:Replace(str, 'score', self:FormatScore(score, items, true));
							str = self:Replace(str, 'ageLocal', self:AgeToText(age, true));
						else
							str = self:Replace(str, 'score', self:FormatScore(score, items, false));
							str = self:Replace(str, 'ageLocal', self:AgeToText(age, false));
						end
						
						str = self:Replace(str, 'name', self:Strpad(name, L["Max UnitName"]));
						
						self:PrintTo(str, dest, to);
					end
				else
					if ( output ) then
						local str = self:Replace(L['Party Member Score False'], 'name', self:Strpad(name, L["Max UnitName"]));
						self:PrintTo(str, dest, to);
					end
				end
			end
		end
		
		if ( partySize > 0 ) then
			local partyAverage = partyTotal / partySize;
			
			if ( output ) then
				self:PrintTo("------------------------", dest, to);
				
				local str = L['Party Score'];
				
				if ( dest == "print" ) then
					str = self:Replace(str, 'score', self:FormatScore(partyAverage, items, true));
				else
					str = self:Replace(str, 'score', self:FormatScore(partyAverage, items, false));
				end
				
				str = self:Replace(str, 'number', partySize);
				
				self:PrintTo(str, dest, to);
			end
			
			return partyAverage, partyTotal, partySize, partyMin, partyMax, party;
		else 
			return false;
		end
	else
		if ( output ) then
			self:Print(ERR_NOT_IN_GROUP);
		end
		
		return false;
	end
end

function SIL:Raid(output, dest, to)
	if not ( dest ) then dest = "print"; end
	local raid = {};
	
	if ( UnitInRaid("player") ) then
		local raidSize = 0;
		local raidTotal = 0;
		local raidMin = false;
		local raidMax = 0;
		
		for i = 1, 40 do
			name, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(i);
			
			if ( name ) then
				
				local guid = UnitGUID(name);
				local score = false;
				
				-- Start Inspecting if they are in range
				if ( CanInspect(name) ) then
					self:StartScore(name, true, false);
					score, age, items = self:ProcessInspect(guid, false);
				
				-- We couldn't inspect so try from the cache
				elseif ( self:HasScore(guid) ) then
					score, age, items = self:GetScore(guid);
				end
				
				-- They have a score so count them
				if ( score ) then
					raidSize = raidSize + 1;
					raidTotal = raidTotal + score;
					table.insert(raid, { ['name'] = name, ['score'] = score, ['age'] = age, ['level'] = level, });
					
					if not ( raidMin ) then
						raidMin = score;
					end
						
					if ( score < raidMin ) then
						raidMin = score;
					end
					
					if ( score > raidMax ) then
						raidMax = score;
					end
					
					if ( output ) then
						
						local str = L['Raid Member Score'];
						
						if ( age < 30 ) then
							str = L['Raid Member Score Fresh'];
						end
						
						if ( dest == "print" ) then
							str = self:Replace(str, 'score', self:FormatScore(score, items, true));
							str = self:Replace(str, 'ageLocal', self:AgeToText(age, true));
						else
							str = self:Replace(str, 'score', self:FormatScore(score, items, false));
							str = self:Replace(str, 'ageLocal', self:AgeToText(age, false));
						end
						
						str = self:Replace(str, 'name', self:Strpad(name, L["Max UnitName"]));
						
						self:PrintTo(str, dest, to);
					end
				else
					if ( output ) then
						self:PrintTo(self:Replace(L['Raid Member Score False'], 'name', self:Strpad(name, L["Max UnitName"])), dest, to);
					end
				end
			end
		end
		
		if ( raidSize > 0 ) then
			local raidAverage = raidTotal / raidSize;
			
			if ( output ) then
				self:PrintTo("------------------------", dest, to);
				
				local str = L['Raid Score'];
				
				if ( dest == "print" ) then
					str = self:Replace(str, 'score', self:FormatScore(raidAverage, 16, true));
				else
					str = self:Replace(str, 'score', self:FormatScore(raidAverage, 16, false));
				end
				
				str = self:Replace(str, 'number', raidSize);
				
				self:PrintTo(str, dest, to);
			end
			
			return raidAverage, raidTotal, raidSize, raidMin, raidMax, raid;
		else 
			return false;
		end
	else
		if ( output ) then
			self:Print(ERR_NOT_IN_RAID);
		end
		
		return false;
	end
end

function SIL:StartScore(target, refresh, tooltip)
	
	-- Incombat so we can't do anything
	if ( InCombatLockdown() ) then 
		return false;
	
	-- We can inspect the person
	elseif ( CanInspect(target) ) then
		local guid = UnitGUID(target);
		local name, realm = UnitName(target);
		
		-- We want to start from scratch
		if ( refresh ) then
			self:ClearScore(guid);
		end
		
		-- Check there score to get all usefull information
		local score, age, items = self:GetScore(guid);
		
		-- We have a score and its under age and has over 5 items
		if ( score ) and ( age < self.db.global.age ) and ( items > 5 ) then
			
			if ( tooltip ) then
				self:ShowTooltip();
			end
			
			return false;
		
		-- We can do something!
		else
			
			-- Start some information if we haven't seen them before
			if not ( SIL_CacheGUID[guid] ) then
				local class, classFileName = UnitClass(target);
				SIL_CacheGUID[guid] = {};
				SIL_CacheGUID[guid]['name'] = name;
				SIL_CacheGUID[guid]['realm'] = realm;
				SIL_CacheGUID[guid]['class'] = classFileName;
			end
			
			-- Update the target information for this person
			SIL_CacheGUID[guid]['target'] = target;
			SIL_CacheGUID[guid]['tooltip'] = tooltip;
			
			-- Start the inspect
			NotifyInspect(target);
			
			-- Pass 1 and 2nd pass will be after the event fires
			self:ProcessInspect(guid, tooltip);
			
			return true;
		end
	else
		return false;
	end
end

function SIL:ProcessInspect(guid, tooltip)
	
	-- Incombat so we can't do anything
	if ( InCombatLockdown() ) then 
		return false;
	
	else
		
		-- We have some more information about this person
		if ( SIL_CacheGUID[guid] ) then
			local name = self:GUIDtoName(guid);
			local target = SIL_CacheGUID[guid]['target'];
			
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
								itemLevel = self:Heirloom(UnitLevel(target));
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
				self:SetScore(totalItems, totalScore, guid);
				
				-- Get the score back, this is dumb but it avoids dupe code
				local score = self:GetScore(guid);
				
				if ( tooltip ) then
					self:ShowTooltip();
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

function SIL:PrintTo(message, channel, to)
	if ( channel == "print" ) then
		SIL:Print(message);
	elseif ( channel == "WHISPER" ) then
		SendChatMessage(message, WHISPER, to);
	elseif ( channel ) then
		SendChatMessage(message, channel);
	else
		SIL:Print(message);
	end
end






---- Settings ----
function SIL:ToggleAdvanced()
	if ( self.db.global.advanced ) then
		self.db.global.advanced = false;
	else
		self.db.global.advanced = true;
	end
end

function SIL:ToggleAutoscan()
	if ( self.db.global.autoscan ) then
		self.db.global.autoscan = false;
	else
		self.db.global.autoscan = true;
	end
	
	SIL:Autoscan(self.db.global.autoscan);
end

function SIL:ToggleMinimap()
	if ( self.db.global.minimap.hide ) then
		self.db.global.minimap.hide = false;
		SIL_LDBIcon:Show("SimpleILevel");
	else
		self.db.global.minimap.hide = true;
		SIL_LDBIcon:Hide("SimpleILevel");
	end
end

function SIL:SetAdvanced(v)
	self.db.global.advanced = v;
end

function SIL:SetAutoscan(v)
	self.db.global.autoscan = v;
	
	SIL:Autoscan(self.db.global.autoscan);
end

function SIL:SetMinimap(v)
	if ( v ) then
		self.db.global.minimap.hide = false;
	else 
		self.db.global.minimap.hide = true;
	end
	
	if ( self.db.global.minimap.hide ) then
		SIL_LDBIcon:Hide("SimpleILevel");
	else
		SIL_LDBIcon:Show("SimpleILevel");
	end
end

function SIL:SetPurge(hours)
	self.db.global.purge = hours;
	SIL_Options.args.purge.desc = SIL:Replace(L['Help Purge Desc'], 'num', self.db.global.purge / 24);
end

function SIL:Autoscan(toggle)
	if ( toggle ) then
		self:RegisterEvent("UNIT_PORTRAIT_UPDATE", "PLAYER_TARGET_CHANGED");
	else 
		self:UnregisterEvent("UNIT_PORTRAIT_UPDATE");
	end
	
	self.db.global.autoscan = toggle;
end

function SIL:GetAdvanced()
	return self.db.global.advanced;
end

function SIL:GetAutoscan()
	return self.db.global.autoscan;
end

function SIL:GetMinimap()
	return not self.db.global.minimap.hide;
end

function SIL:GetAge()
	return self.db.global.age;
end

function SIL:SetAge(sec)
	self.db.global.age = sec;
end

function SIL:GetPurge()
	return self.db.global.purge;
end






















-- Open the options window
function SIL:ShowOptions()
	SIL_ACD:Open("SimpleILevel");
end

-- From Skada
--
-- Current Layout
	-- Party
		-- Console
		-- Party
		-- Guild
		-- Say
	-- Raid
		-- Consols
		-- Party
		-- Guild
		-- Say
	-- ----
	-- Advanced
	-- AutoScan 
	-- ----
	-- My Score
function SIL:OpenMenu(window) 
	if not self.silmenu then
		self.silmenu = CreateFrame("Frame", "SILMenu")
	end
	local menu = self.silmenu
	
	-- Get the score started for the menu
	SIL:StartScore('player', true, false);
	local score, age, items = SIL:ProcessInspect(UnitGUID('player'), false);
	
	-- Party
	local partyAverage, partyTotal, partySize = false, false, false;
	local raidAverage, raidTotal, raidSize = false, false, false;
	if ( GetNumPartyMembers() > 0 ) then
		partyAverage, partyTotal, partySize = SIL:Party(false);
		partyAverage = SIL:FormatScore(partyAverage);
	
		if ( UnitInRaid("player") ) then
			raidAverage, raidTotal, raidSize = SIL:Raid(false);
			raidAverage = SIL:FormatScore(raidAverage);
		end
	end
	
	menu.displayMode = "MENU";
	local info = {};
	menu.initialize = function(self,level)
		if not level then return end
		wipe(info);
		if level == 1 then
			
			-- Title
			info.isTitle = 1;
			info.text = L["Addon Name"]..' '..SIL_Version;
			info.notCheckable = 1;
			UIDropDownMenu_AddButton(info, level);
			
			-- Spacer
			wipe(info);
			info.disabled = 1;
			info.notCheckable = 1;
			UIDropDownMenu_AddButton(info, level);
			
			if ( GetNumPartyMembers() > 0 ) then
				-- Party
				wipe(info);
				info.text = L["Help Party"]..' '..partyAverage;
				info.notCheckable = 1;
				info.hasArrow = 1;
				info.value = { title = L["Help Party"], type = "party", };
				UIDropDownMenu_AddButton(info, level);
				
				if ( UnitInRaid("player") ) then
					-- Raid
					wipe(info);
					info.text = L["Help Party"]..' '..raidAverage;
					info.notCheckable = 1;
					info.hasArrow = 1;
					info.value = { title = L["Help Raid"], type = "raid", };
					UIDropDownMenu_AddButton(info, level);
				end
				
				-- Spacer
				wipe(info);
				info.disabled = 1;
				info.notCheckable = 1;
				UIDropDownMenu_AddButton(info, level);
			end
			
			-- Advanced Tool tip
			wipe(info);
			info.text = L["Help Advanced"];
			info.func = function() SIL:ToggleAdvanced(); end;
			info.checked = SIL:GetAdvanced();
			UIDropDownMenu_AddButton(info, level);
			
			-- Autoscan
			wipe(info);
			info.text = L["Help Autoscan"];
			info.func = function() SIL:ToggleAutoscan(); end;
			info.checked = SIL:GetAutoscan();
			UIDropDownMenu_AddButton(info, level);
			
			-- Minimap
			wipe(info);
			info.text = L["Help Minimap"];
			info.func = function() SIL:ToggleMinimap(); end;
			info.checked = SIL:GetMinimap();
			UIDropDownMenu_AddButton(info, level);
			
			-- Spacer
			wipe(info);
			info.disabled = 1;
			info.notCheckable = 1;
			UIDropDownMenu_AddButton(info, level);
			
			-- Options
			wipe(info);
			info.text = L['Help Options'];
			info.func = function() SIL:ShowOptions(); end;
			info.notCheckable = 1;
			UIDropDownMenu_AddButton(info, level);
			
			-- My Score
			wipe(info);
			info.text = SIL:Replace(L['Your Score'], 'score', SIL:FormatScore(score, items));
			info.notClickable = 1;
			info.notCheckable = 1;
			UIDropDownMenu_AddButton(info, level);
			
		elseif level == 2 then
			if type(UIDROPDOWNMENU_MENU_VALUE) == "table" then
				local v = UIDROPDOWNMENU_MENU_VALUE;
				
				wipe(info)
		        info.isTitle = 1;
				info.notCheckable = 1;
		        info.text = v.title;
		        UIDropDownMenu_AddButton(info, level);
				
				-- Console - CHAT_MSG_SYSTEM 
				wipe(info);
				info.text = CHAT_MSG_SYSTEM;
				if ( v.type == "party" ) then
					info.func = function() SIL:Party(true, "print"); end;
				elseif ( v.type == "raid" ) then
					info.func = function() SIL:Raid(true, "print"); end;
				end
				info.notCheckable = 1;
				UIDropDownMenu_AddButton(info, level);
				
				-- Party - CHAT_MSG_PARTY
				wipe(info);
				info.text = CHAT_MSG_PARTY;
				if ( v.type == "party" ) then
					info.func = function() SIL:Party(true, "PARTY"); end;
				elseif ( v.type == "raid" ) then
					info.func = function() SIL:Raid(true, "PARTY"); end;
				end
				info.notCheckable = 1;
				UIDropDownMenu_AddButton(info, level);
				
				-- Raid - CHAT_MSG_RAID 
				if ( UnitInRaid("player") ) then
					wipe(info);
					info.text = CHAT_MSG_RAID;
					if ( v.type == "party" ) then
						info.func = function() SIL:Party(true, "RAID"); end;
					elseif ( v.type == "raid" ) then
						info.func = function() SIL:Raid(true, "RAID"); end;
					end
					info.notCheckable = 1;
					UIDropDownMenu_AddButton(info, level);
				end
				
				-- Guild - CHAT_MSG_GUILD 
				if ( IsInGuild() ) then
					wipe(info);
					info.text = CHAT_MSG_GUILD;
					if ( v.type == "party" ) then
						info.func = function() SIL:Party(true, "GUILD"); end;
					elseif ( v.type == "raid" ) then
						info.func = function() SIL:Raid(true, "GUILD"); end;
					end
					info.notCheckable = 1;
					UIDropDownMenu_AddButton(info, level);
				end
				
				-- Say - CHAT_MSG_SAY
				wipe(info);
				info.text = CHAT_MSG_SAY;
				if ( v.type == "party" ) then
					info.func = function() SIL:Party(true, "SAY"); end;
				elseif ( v.type == "raid" ) then
					info.func = function() SIL:Raid(true, "SAY"); end;
				end
				info.notCheckable = 1;
				UIDropDownMenu_AddButton(info, level);
				
				-- Spacer
				wipe(info);
				info.disabled = 1;
				info.notCheckable = 1;
				UIDropDownMenu_AddButton(info, level);
				
				-- Group Score
				wipe(info);
				if ( v.type == "party" ) then
					info.text = partyAverage..' / '..partySize;
				elseif ( v.type == "raid" ) then
					info.text = raidAverage..' / '..raidSize;
				end
				
				info.notClickable = 1;
				info.notCheckable = 1;
				UIDropDownMenu_AddButton(info, level);
			end
		end
	end
	
	local x,y = GetCursorPosition(UIParent);
	ToggleDropDownMenu(1, nil, menu, "UIParent", x / UIParent:GetEffectiveScale() , y / UIParent:GetEffectiveScale());
end