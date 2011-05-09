local L = LibStub("AceLocale-3.0"):GetLocale("SimpleILevel", true);
SIL = LibStub("AceAddon-3.0"):NewAddon(L['Addon Name'], "AceEvent-3.0", "AceConsole-3.0")
local aceConfig = LibStub:GetLibrary("AceConfig-3.0");
local aceConfigDialog = LibStub:GetLibrary("AceConfigDialog-3.0");
local LDB = LibStub:GetLibrary("LibDataBroker-1.1");
local LDBIcon = LDB and LibStub("LibDBIcon-1.0");
SIL_Version = GetAddOnMetadata("SimpleILevel", "Version");

function SIL:OnInitialize()
	
	-- Pull in some meta data
	self.version = GetAddOnMetadata("SimpleILevel", "Version");
	self.category = GetAddOnMetadata("SimpleILevel", "X-Category");
	
	-- Tell the player we are being loaded
	self:Print(self:Replace(L['Loading Addon'], 'version', self.version));
	
	-- Version Info
	self.versionMajor = 2.1;
	self.versionMinor = 3;
	
	-- Load the DB
	self.db = LibStub("AceDB-3.0"):New("SIL_Settings", SIL_Defaults, true);
	self:Update();
	self.db.global.version = self.versionMajor;
	self.db.global.versionMinor = self.versionMinor;
	
	-- Make sure we can cache
	if not ( type(SIL_CacheGUID) == 'table' ) then
		SIL_CacheGUID = {};
	end
	
	local ldbObj = {
		type = "data source",
		icon = "Interface\\Icons\\inv_misc_armorkit_24",
		label = L['Addon Name'],
		text = "n/a",
		category = self.category,
		version = self.version,
		OnClick = function(f,b)
					SIL:OpenMenu();
			end,
		OnTooltipShow = function(tt)
							tt:AddLine(L['Minimap Click']);
							tt:AddLine(L['Minimap Click Drag']);
			end,
		};
	
	-- Set back to a launcher if text is off
	if not (self.db.global.ldbText ) then
		ldbObj.type = 'launcher';
		ldbObj.text = nil;
	else
		self:RegisterEvent("PARTY_MEMBERS_CHANGED"); -- I would like to find something lighter then this
	end
	
	-- Start LDB
	self.ldb = LDB:NewDataObject(L['Addon Name'], ldbObj);
	self.ldbUpdated = 0;
	self.ldbLable = '';
	SIL:UpdateLDB(); -- This may cause excesive loading time...
	
	-- Start the minimap icon
	LDBIcon:Register(L['Addon Name'], self.ldb, self.db.global.minimap);
	
	-- Register Options
	SIL_Options.args.purge.desc = SIL:Replace(L['Help Purge Desc'], 'num', self.db.global.purge / 24);
	aceConfig:RegisterOptionsTable(L['Addon Name'], SIL_Options, {"sil", "silev", "simpleilevel"});
	aceConfigDialog:AddToBlizOptions(L['Addon Name']);
	
	-- Register Events
	self:RegisterEvent("PLAYER_TARGET_CHANGED");
	self:RegisterEvent("INSPECT_READY");
	self:RegisterEvent("UPDATE_MOUSEOVER_UNIT");
	self:Autoscan(self.db.global.autoscan);
	
	-- Auto Purge the cache
	SIL:AutoPurge(true);
end

function SIL:Update()

	-- Add a score for everyone in the DB
	if not ( self.db.global.version ) or ( self.db.global.version < 2.1 ) then
		for guid,info in pairs(SIL_CacheGUID) do
			if not ( info.score ) and ( info.items ) and ( info.total ) then
				SIL_CacheGUID[guid]['score'] = info.total / info.items;
			else
				SIL_CacheGUID[guid]['score'] = 0;
			end
		end
	end
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

function SIL:UNIT_PORTRAIT_UPDATE(e, unitID)
	
	-- Don't do anything in combat
	if ( InCombatLockdown() ) then return end
	
	if ( unitID ) and ( CanInspect(unitID) ) then
		self:StartScore(unitID, true, false);
		
		self:UpdateLDB();
	end
end

function SIL:PARTY_MEMBERS_CHANGED()
	self:UpdateLDB();
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
			self:Print(self:Replace(L['Purge Notification'], 'num', count));
		end
		
		return count;
	else
		if not ( silent ) then
			self:Print(L['Purge Notification False']);
		end
		
		return false;
	end
end

function SIL:PurgeCache(hours)
	if ( tonumber(hours) ) then
		local maxAge = time() - ( tonumber(hours) * 3600 );
		local count = 0;
		
		for guid,info in pairs(SIL_CacheGUID) do
			if ( type(info['time']) == "number" ) and( info['time'] < maxAge ) then
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


function SIL:AddPlayer(guid, name, realm, class)
	if ( guid ) and ( name ) and ( class ) then
		if not ( SIL_CacheGUID[guid] ) then
			SIL_CacheGUID[guid] = {};
		end
		
		SIL_CacheGUID[guid]['name'] = name;
		SIL_CacheGUID[guid]['realm'] = realm;
		SIL_CacheGUID[guid]['class'] = class;
		
		if not ( SIL_CacheGUID[guid]['score'] ) then
			SIL_CacheGUID[guid]['score'] = 0;
		end
	end
end

-- Get someones score
function SIL:GetScore(target, force)
	
	-- If a score is forced the input becomes unitId, true
	if ( force ) then
		self:StartScore(target, true, false);
		self:ProcessInspect(UnitGUID(target), false);
		target = UnitGUID(target);
	end
	
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
		SIL_CacheGUID[guid]['score'] = total / items;
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
			self:StartScore('target', true, false);
			local score, age, items = SIL:ProcessInspect(UnitGUID('target'), false);
			
			if ( score ) then
				local str = SIL:Replace(L['Slash Target Score True'], 'target', UnitName('target'));
				str = SIL:Replace(str, 'score', SIL:FormatScore(score, items));
				
				self:Print(str);
				
			else
				self:Print(L['Slash Target Score False']);
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
			self:Print(self:Replace(L['Slash Get Score False'], 'target', value));
		end
	else 
		self:Print(L['Slash Get Score False']);
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
		self:Print(self:FormatScore(i));
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
			local _,class = UnitClass(target);
			self:AddPlayer(guid, name, realm, class);
			
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
			
			-- Can we still inspect them?
			if ( target ) and ( CanInspect(target) ) then
			
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
		else
			return false;
		end
	end
end

function SIL:PrintTo(message, channel, to)
	if ( channel == "print" ) or ( channel == "SYSTEM" ) then
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

function SIL:ToggleLabel()
	if ( self.db.global.showLabel ) then
		self.db.global.showLabel = false;
	else
		self.db.global.showLabel = true;
	end
	
	self:UpdateLDB();
end

function SIL:ToggleAutoscan()
	if ( self.db.global.autoscan ) then
		self.db.global.autoscan = false;
	else
		self.db.global.autoscan = true;
	end
	
	self:Autoscan(self.db.global.autoscan);
end

function SIL:ToggleMinimap()
	if ( self.db.global.minimap.hide ) then
		self.db.global.minimap.hide = false;
		LDBIcon:Show(L['Addon Name']);
	else
		self.db.global.minimap.hide = true;
		LDBIcon:Hide(L['Addon Name']);
	end
end

function SIL:SetAdvanced(v)
	self.db.global.advanced = v;
end

function SIL:SetLabel(v)
	self.db.global.showLabel = v;
	self:UpdateLDB();
end

function SIL:SetAutoscan(v)
	self.db.global.autoscan = v;
	
	self:Autoscan(self.db.global.autoscan);
end

function SIL:SetMinimap(v)
	if ( v ) then
		self.db.global.minimap.hide = false;
	else 
		self.db.global.minimap.hide = true;
	end
	
	if ( self.db.global.minimap.hide ) then
		LDBIcon:Hide(L['Addon Name']);
	else
		LDBIcon:Show(L['Addon Name']);
	end
end

function SIL:SetPurge(hours)
	self.db.global.purge = hours;
	SIL_Options.args.purge.desc = SIL:Replace(L['Help Purge Desc'], 'num', self.db.global.purge / 24);
end

function SIL:Autoscan(toggle)
	if ( toggle ) then
		self:RegisterEvent("UNIT_PORTRAIT_UPDATE");
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

function SIL:GetLabel()
	return self.db.global.showLabel;
end

function SIL:GetLDB()
	return self.db.global.ldbText;
end

function SIL:GetLDBlabel()
	return self.db.global.ldbLabel;
end

function SIL:GetLDBrefresh()
	return self.db.global.ldbRefresh;
end

function SIL:SetLDB(v)
	self.db.global.ldbText = v;
	
	if ( v ) then
		self:RegisterEvent("PARTY_MEMBERS_CHANGED");
		self.ldb.type = 'data source';
	else
		self:UnregisterEvent("PARTY_MEMBERS_CHANGED");
		self.ldb.type = 'launcher';
		self.ldb.text = nil;
	end
	
	self:UpdateLDB(true);
end

function SIL:SetLDBlabel(v)
	self.db.global.ldbLabel = v;
	self:UpdateLDB(true);
end

function SIL:SetLDBrefresh(v)
	self.db.global.ldbRefresh = v;
end

function SIL:ToggleLDBlabel()
	if ( self.db.global.ldbLabel ) then
		self.db.global.ldbLabel = false;
	else
		self.db.global.ldbLabel = true;
	end
	
	self:UpdateLDB(true);
end














-- Open the options window
function SIL:ShowOptions()
	aceConfigDialog:Open(L['Addon Name']);
end

function SIL:OpenMenu(window)
	
	-- Don't do anything in combat
	if ( InCombatLockdown() ) then return end
	
	if not self.silmenu then
		self.silmenu = CreateFrame("Frame", "SILMenu")
	end
	local menu = self.silmenu
	
	
	-- Get the score started for the menu
	local score, age, items = self:GetScore('player', true);
	
	-- Party
	local groupScore, groupCount = self:GroupScore(false);
	groupScore = self:FormatScore(groupScore);
	
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
			
				wipe(info);
				info.notCheckable = 1;
				info.hasArrow = 1;
				info.func = function() SIL:GroupOutput("SYSTEM"); end;
				
				
				-- Party
				info.text = L["Help Group"]..' '..groupScore;
				info.value = { title = L["Help Group"], type = "party", };
				
				-- Raid
				if ( UnitInRaid("player") ) then
					info.text = L["Help Group"]..' '..groupScore;
					info.value = { title = L["Help Group"], type = "raid", };
				end
				
				UIDropDownMenu_AddButton(info, level);
				
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
			
			-- Label Text
			wipe(info);
			info.text = L['Help LDB Source'];
			info.func = function() SIL:ToggleLDBlabel(); end;
			info.checked = SIL:GetLDBlabel();
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
				info.func = function() SIL:GroupOutput("SYSTEM"); end;
				info.notCheckable = 1;
				UIDropDownMenu_AddButton(info, level);
				
				-- Spacer
				wipe(info);
				info.disabled = 1;
				info.notCheckable = 1;
				UIDropDownMenu_AddButton(info, level);
				
				-- Party - CHAT_MSG_PARTY
				wipe(info);
				info.text = CHAT_MSG_PARTY;
				info.func = function() SIL:GroupOutput("PARTY"); end;
				info.notCheckable = 1;
				UIDropDownMenu_AddButton(info, level);
				
				-- Raid - CHAT_MSG_RAID 
				if ( UnitInRaid("player") ) then
					wipe(info);
					info.text = CHAT_MSG_RAID;
					info.func = function() SIL:GroupOutput("RAID"); end;
					info.notCheckable = 1;
					UIDropDownMenu_AddButton(info, level);
				end
				
				-- Guild - CHAT_MSG_GUILD 
				if ( IsInGuild() ) then
					wipe(info);
					info.text = CHAT_MSG_GUILD;
					info.func = function() SIL:GroupOutput("GUILD"); end;
					info.notCheckable = 1;
					UIDropDownMenu_AddButton(info, level);
				end
				
				-- Say - CHAT_MSG_SAY
				wipe(info);
				info.text = CHAT_MSG_SAY;
				info.func = function() SIL:GroupOutput("SAY"); end;
				info.notCheckable = 1;
				UIDropDownMenu_AddButton(info, level);
				
				-- Spacer
				wipe(info);
				info.disabled = 1;
				info.notCheckable = 1;
				UIDropDownMenu_AddButton(info, level);
				
				-- Group Score
				wipe(info);
				info.text = groupScore..' / '..groupCount;
				info.notClickable = 1;
				info.notCheckable = 1;
				UIDropDownMenu_AddButton(info, level);
			end
		end
	end
	
	local x,y = GetCursorPosition(UIParent);
	ToggleDropDownMenu(1, nil, menu, "UIParent", x / UIParent:GetEffectiveScale() , y / UIParent:GetEffectiveScale());
end


function SIL:UpdateLDB(force)
	
	if ( self.db.global.ldbText ) then
		local label = '';
		
		if ( UnitInRaid("player") ) then
			label = CHAT_MSG_RAID;
		elseif ( GetNumPartyMembers() > 0 ) then
			label = CHAT_MSG_PARTY;
		else
			label = UnitName('player');
		end
		

		-- Do we really need to update LDB?
		if ( force ) or ( label ~= self.ldbLable ) or ( (self.ldbUpdated + self.db.global.ldbRefresh) < time() ) then
		
			local score = SIL:GroupScore(false);
			
			if ( tonumber(score) ) then
				text = self:FormatScore(score);
				
				-- print("Updating LDB:", label, text);
				-- Log it
				self.ldbUpdated = time();
				self.ldbLable = label;
				
				if ( self.db.global.ldbLabel ) then
					text = label..": "..text;
				end
				
				self.ldb.text = text;
			end
		end
	else
		self.ldb.type = 'launcher';
		self.ldb.text = nil;
		
		-- Make sure we arn't still somehow registered
		self:UnregisterEvent("PARTY_MEMBERS_CHANGED");
	end
end

-- 
function SIL:GroupScore(force)
	if InCombatLockdown() then return false; end
	
	local group = {};
	local totalScore = 0;
	local groupSize = 0;
	local groupMin = 0;
	local groupMax = 0;
	
	-- Add yourself
	local score = 0;
	local yourGUID = UnitGUID('player');
	
	if ( force ) then 
		score = self:GetScore('player', true);
	else
		score = self:GetScore(yourGUID);
	end
	
	table.insert(group, SIL_CacheGUID[yourGUID]);
	
	if ( score ) then
		totalScore = totalScore + score;
		groupSize = groupSize + 1;
		groupMin = score;
		groupMax = score;
	end
	
	-- Raid
	if ( UnitInRaid("player") ) then
		for i = 1, 40 do
			_, rank, subgroup, level, class, fileName, zone, online, isDead, role, isML = GetRaidRosterInfo(i);
			local target = 'raid'..i;
			local guid = UnitGUID(target);
			local name, realm = UnitName(target);
			local _,class = UnitClass(target);
			
			self:AddPlayer(guid, name, realm, class);
			
			-- Skip yourself
			if not ( guid == yourGUID ) then
				if ( force ) then 
					score = self:GetScore(target, true);
				else
					score = self:GetScore(guid);
				end
				
				table.insert(group, SIL_CacheGUID[guid]);
				
				if ( score ) then
					totalScore = totalScore + score;
					groupSize = groupSize + 1;
					
					if ( score < groupMin ) then groupMin = score; end
					if ( score > groupMax ) then groupMax = score; end
				end
			end
		end
	
	-- Party
	elseif ( GetNumPartyMembers() > 0 ) then
		for i = 1,4 do
			if ( GetPartyMember(i) ) then
				local target = 'party'..i;
				local guid = UnitGUID(target);
				local name, realm = UnitName(target);
				local _,class = UnitClass(target);
				self:AddPlayer(guid, name, realm, class);
				
				if ( force ) then 
					score = self:GetScore(target, true);
				else
					score = self:GetScore(guid);
				end
				
				table.insert(group, SIL_CacheGUID[guid]);
				
				if ( score ) then
					totalScore = totalScore + score;
					groupSize = groupSize + 1;
					
					if ( score < groupMin ) then groupMin = score; end
					if ( score > groupMax ) then groupMax = score; end
				end
			end
		end	
	end
	
	-- Sort by score, not sure if this will be perserved but its worth a shot
	sort(group, function(a,b) return a.score>b.score end );
	
	local groupAvg = totalScore / groupSize;
	return groupAvg, groupSize, group, groupMin, groupMax;
end

function SIL:GroupOutput(dest, to)	
	local groupAvg, groupSize, group, groupMin, groupMax = self:GroupScore(true);
	local valid = false;
	
	if not ( dest ) then dest = "SYSTEM"; valid = true; end
	if ( dest == '' ) then dest = "SYSTEM"; valid = true; end
	dest = string.upper(dest);
	
	-- Some short codes
	if ( dest == 'P' ) then dest = 'PARTY'; valid = true; end
	if ( dest == 'R' ) then dest = 'RAID' valid = true; end
	if ( dest == 'BG' ) then dest = 'BATTLEGROUND' valid = true; end
	if ( dest == 'G' ) then dest = 'GUILD' valid = true; end
	if ( dest == 'O' ) then dest = 'OFFICER' valid = true; end
	if ( dest == 'S' ) then dest = 'SAY' valid = true; end
	
	-- Find out if its a valid dest
	for fixed,loc in pairs(SIL_Channels) do
		if ( dest == string.upper(loc) ) then
			dest = fixed;
			valid = true;
		elseif ( dest == string.upper(fixed) ) then
			dest = fixed;
			valid = true;
		end
	end
	
	-- Default to system
	if not ( valid ) then
		dest = "SYSTEM";
	end
	
	-- Output the header
	if ( dest == "SYSTEM" ) then
		groupAvgFmt = self:FormatScore(groupAvg, 16, true);
	else
		groupAvgFmt = self:FormatScore(groupAvg, 16, false);
	end
	
	local str = L['Group Score'];
	str = self:Replace(str, 'avg', groupAvgFmt);
	self:PrintTo(str, dest, to);
	
	-- Sort by score
	sort(group, function(a,b) return a.score>b.score end );
	
	-- Loop everyone
	for i,info in pairs(group) do
		local name = info.name;
		local str = "%name (%score)";
		local score = 0;
		local items = 0;
		
		if ( info.score ) then
			items = info.items;
			score = info.score;
		else 
			str = L['Group Member Score False'];
		end
		
		if ( dest == "SYSTEM" ) then
			score = self:FormatScore(score, items, true);
			name = '|cFF'..self:RGBtoHex(RAID_CLASS_COLORS[info.class].r, RAID_CLASS_COLORS[info.class].g, RAID_CLASS_COLORS[info.class].b)..name..'|r';
		else
			score = self:FormatScore(score, items, false);
		end
		
		str = self:Replace(str, 'score', score);
		str = self:Replace(str, 'name', name);
		
		self:PrintTo(str, dest, to);
	end
	
	-- Update LDB
	self:UpdateLDB(true);
end