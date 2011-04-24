SIL = LibStub("AceAddon-3.0"):NewAddon("SimpleILevel", "AceEvent-3.0", "AceConsole-3.0")
SIL:SetEnabledState(true)

local L = LibStub("AceLocale-3.0"):GetLocale("SimpleILevel", true)
--LibStub("AceEvent-3.0"):Embed(SIL);

SIL_VersionMajor = 2.0;
SIL_VersionMinor = 1;
SIL_Version = SIL_VersionMajor..'-'..SIL_VersionMinor;

local options = {
	name = L['Help Options'],
	type = "group",
	args = {
		clear = {
			name = L['Help Clear'],
			desc = L['Help Clear Desc'],
			type = "execute",
			func = function(i) SIL:Reset(); end,
			confirm = true
		},
		advanced = {
			name = L['Help Advanced'],
			desc = L['Help Advanced Desc'],
			type = "toggle",
			set = function(i,v) SIL_Settings['advanced'] = v; end,
			get = function(i) return SIL_Settings['advanced']; end
		},
		autoscan = {
			name = L['Help Autoscan'],
			desc = L['Help Autoscan Desc'],
			type = "toggle",
			set = function(i,v) SIL:Autoscan(v); end,
			get = function(i) return SIL_Settings['autoscan']; end
		},
		purge = {
			name = L['Help Purge'],
			desc = L['Help Purge Desc'],
			type = "input",
			validate = function(i,v) 
				if not (tonumber(v)) then 
					SIL:Print(L['Help Purge Error']); return L['Help Purge Error'];
				else 
					local count = SIL:PurgeCache(number); 
						if not count then count = 0; end 
					SIL:Print(SIL:Replace(L['Purge Notification'], 'num', count));
				end; end,
		},
		age = {
			name = L['Help Age'],
			desc = L['Help Age Desc'],
			type = "range",
			min = 1,
			softMax = 240,
			step = 1,
			bigStep = 15,
			get = function(i) return (SIL_Settings['age'] / 60); end,
			set = function(i,v) SIL_Settings['age'] = tonumber(tonumber(v) * 60);  end
		},
		party = {
			name = L['Help Party'],
			desc = L['Help Party Desc'],
			type = "execute",
			hidden = true,
			guiHidden = true,
			func = function(i) SIL:Party(true); end
		},
		raid = {
			name = L['Help Raid'],
			desc = L['Help Raid Desc'],
			type = "execute",
			hidden = true,
			guiHidden = true,
			func = function(i) SIL:Raid(true); end
		},
		
		-- Console Only
		get = {
			name = L['Help Get'],
			desc = L['Help Get Desc'],
			type = "input",
			set = function(i) SIL:ForceGet(target); end,
			hidden = true,
			guiHidden = true,
			cmdHidden = false,
		},
		target = {
			name = L['Help Target'],
			desc = L['Help Target Desc'],
			type = "input",
			set = function(i) SIL:ForceGet(target); end,
			hidden = true,
			guiHidden = true,
			cmdHidden = false,
		},
	},
};
LibStub("AceConfig-3.0"):RegisterOptionsTable("SimpleILevel", options, {"sil", "silev", "simpleilevel"});
SILo = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("SimpleILevel");

-- Color constants
local SIL_ColorIndex = {0,200,333,378,390,1000};
local SIL_Colors = {
	-- White base color
	[0] = 		{['r']=255,	['g']=255,	['b']=255,	['p']=0,},
	-- Yellow for wrath dungeon gear
	[200] = 	{['r']=255,	['g']=204,	['b']=0,	['p']=0,},
	-- Green for cata dungeon
	[333] = 	{['r']=0,	['g']=204,	['b']=0,	['p']=200,},
	-- Blue for heroic t11 final gear
	[378] = 	{['r']=0,	['g']=102,	['b']=204,	['p']=333,},
	-- Purple for t11 on
	[390] = 	{['r']=163,	['g']=23,	['b']=238,	['p']=378,},
	-- Red for a max score
	[1000] = 	{['r']=255,	['g']=0,	['b']=0,	['p']=390},
};

function SIL:OnInitialize()
	
	-- Never been here before
	if not ( SIL_Settings ) or not ( SIL_CacheGUID ) then
		self:Reset();
	end
	
	-- Check for a newer version
	if ( SIL_VersionMajor > SIL_Settings['version'] ) then
		self:Update();
	end
	
	-- Tell the player we have been loaded
	self:Print(self:Replace(L['Loading Addon'], 'version', SIL_Version));
	
	-- Register Events
	self:RegisterEvent("PLAYER_TARGET_CHANGED");
	self:RegisterEvent("INSPECT_READY");
	self:RegisterEvent("UPDATE_MOUSEOVER_UNIT");
	self:Autoscan(SIL_Settings['autoscan']);
end

-- Fix events for auto scanning
function SIL:Autoscan(toggle)
	if ( toggle ) then
		self:RegisterEvent("UNIT_PORTRAIT_UPDATE", "PLAYER_TARGET_CHANGED");
	else 
		self:UnregisterEvent("UNIT_PORTRAIT_UPDATE");
	end
	
	SIL_Settings['autoscan'] = toggle;
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


-- Update to a newer version
function SIL:Update()

	-- Sorry but we can't support every old version
	if (SIL_Settings['version'] < 1.2) then
		self:Reset();
	end
end

-- Reset the settings
function SIL:Reset()
	self:Print(L["Slash Clear"]);
	SIL_CacheGUID = {};						-- Table if information about toons
	SIL_Settings = {}
	SIL_Settings['age'] = 1800;				-- How long till information is refreshed
	SIL_Settings['advanced'] = false;			-- Display extra information in the tooltips
	SIL_Settings['autoscan'] = true;			-- Automaticly scan for changes
	SIL_Settings['version'] = SIL_VersionMajor;-- Version for future referance
	SIL_Settings['versionMinor'] = SIL_VersionMinor;
end

-- Clear the cache
function SIL:PurgeCache(days)
	if ( tonumber(days) ) then
		local maxAge = time() - ( tonumber(days) * 86400 );
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
function SIL:FormatScore(score, items)
	local hexColor = self:ColorScore(score, items);
	local score = self:Round(score, 1);
	
	return '|cFF'..hexColor..score..'|r';
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
	if not ( target ) then
		target = 'target'
	end
	
	-- Call by name
	if ( target == 'target' ) then
		if ( CanInspect('target') ) then
			
		else
			self:Print(L['Slash Target Score False']);
		end
	elseif not ( target == '' ) then
		local score, age, items = SIL:GetScore(target);
		
		if ( score ) then
			age = self:AgeToText(age);
				
			local str = L['Slash Get Score True'];
			str = self:Replace(str, 'target', target);
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

function SIL:AgeToText(age)
	if ( type(age) == 'number' ) then
		if ( age > 86400 ) then
			age = self:Round(age / 86400, 2);
			return self:Replace(L['Age Days'], 'age', '|cFFff0000'..age..'|r');
		elseif ( age > 3600 ) then
			age = self:Round(age / 3600, 1)
			return self:Replace(L['Age Hours'], 'age', '|cFF33ccff'..age..'|r');
		elseif ( age > 60 ) then
			age = self:Round(age / 60, 1)
			return self:Replace(L['Age Minutes'], 'age', '|cFF00ff00'..age..'|r');
		else
			return self:Replace(L['Age Seconds'], 'age', '|cFF00ff00'..age..'|r');
		end
	else
		return 'n/a';
	end
end

function SIL:Party(output)
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
				
				str = self:Replace(str, 'name', self:Strpad(UnitName('player'), L["Max UnitName"]));
				str = self:Replace(str, 'score', self:FormatScore(score, items));
				str = self:Replace(str, 'ageLocal', self:AgeToText(age));
				
				self:Print(str);
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
						
						str = self:Replace(str, 'name', self:Strpad(name, L["Max UnitName"]));
						str = self:Replace(str, 'score', self:FormatScore(score, items));
						str = self:Replace(str, 'ageLocal', self:AgeToText(age));
						
						self:Print(str);
					end
				else
					if ( output ) then
						self:Print(self:Replace(L['Party Member Score False'], 'name', self:Strpad(name, L["Max UnitName"])));
					end
				end
			end
		end
		
		if ( partySize > 0 ) then
			local partyAverage = partyTotal / partySize;
			
			if ( output ) then
				self:Print("------------------------");
				
				local str = self:Replace(L['Party Score'], 'score', self:FormatScore(partyAverage));
				str = self:Replace(str, 'number', partySize);
				
				self:Print(str);
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

function SIL:Raid(output)
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
						
						str = self:Replace(str, 'name', self:Strpad(name, L["Max UnitName"]));
						str = self:Replace(str, 'score', self:FormatScore(score, items));
						str = self:Replace(str, 'ageLocal', self:AgeToText(age));
						
						self:Print(str);
					end
				else
					if ( output ) then
						self:Print(self:Replace(L['Raid Member Score False'], 'name', self:Strpad(name, L["Max UnitName"])));
					end
				end
			end
		end
		
		if ( raidSize > 0 ) then
			local raidAverage = raidTotal / raidSize;
			
			if ( output ) then
				self:Print("------------------------");
				
				local str = self:Replace(L['Raid Score'], 'score', self:FormatScore(raidAverage));
				str = self:Replace(str, 'number', raidSize);
				
				self:Print(str);
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
		if ( score ) and ( age < SIL_Settings['age'] ) and ( items > 5 ) then
			
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










