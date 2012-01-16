--[[
ToDo:
    - Play with UnitName() and GetRealmName() in instances

]]
local L = LibStub("AceLocale-3.0"):GetLocale("SimpleILevel", true);

-- Start SIL
SIL = LibStub("AceAddon-3.0"):NewAddon(L['Addon Name'], "AceEvent-3.0", "AceConsole-3.0");
SIL.category = GetAddOnMetadata("SimpleILevel", "X-Category");
SIL.version = GetAddOnMetadata("SimpleILevel", "Version");
SIL.versionMajor = 2.4;                    -- Used for cache DB versioning
SIL.versionRev = 'r@project-revision@';    -- Used for version information
SIL.action = {};        -- DB of unitGUID->function to run when a update comes through
SIL.hookInspect = {};   -- List of functions to call when a inspect update is required
SIL.hookTooltip = {};   -- List of functions to call when a tooltip update is required
SIL.autoscan = 0;       -- time() value of last autoscan, must be more then 1sec
SIL.lastScan = {};      -- target = time();
SIL.grayScore = 6;      -- Number of items to consider gray/aprox

-- Load Libs
SIL.aceConfig = LibStub:GetLibrary("AceConfig-3.0");
SIL.aceConfigDialog = LibStub:GetLibrary("AceConfigDialog-3.0");
SIL.inspect = LibStub:GetLibrary("LibInspect");
SIL.ldb = LibStub:GetLibrary("LibDataBroker-1.1");
SIL.ldbIcon = LibStub:GetLibrary("LibDBIcon-1.0");
SIL.callback = LibStub("CallbackHandler-1.0"):New(SIL);

-- OnLoad
function SIL:OnInitialize()
    
    -- Make sure everything is ok with the settings
    if not type(SIL_CacheGUID) == 'table' then SIL_CacheGUID = {}; end
    
    -- Tell the player we are being loaded
	self:Print(self:Replace(L['Loading Addon'], 'version', self.version));
    
    -- Load settings
    self.db = LibStub("AceDB-3.0"):New("SIL_Settings", SIL_Defaults, true);
	self:UpdateSettings();
	
    -- Set Up LDB
    local ldbObj = {
        type = "data source",
        icon = "Interface\\Icons\\inv_misc_armorkit_24",
        label = L['Addon Name'],
        text = L["Unknown Score"],
        category = self.category,
        version = self.version,
        OnClick = function(...) SIL:OpenMenu(...); end,
        OnTooltipShow = function(tt)
                            tt:AddLine(L['Minimap Click']);
                            tt:AddLine(L['Minimap Click Drag']);
            end,
    };
    
    -- Set back to a launcher if text is off
	if not self:GetLDB() then
		ldbObj.type = 'launcher';
		ldbObj.text = nil;
	else
		--self:RegisterEvent("PARTY_MEMBERS_CHANGED"); -- I would like to find something lighter then this
	end
    
    -- Start LDB
	self.ldb = self.ldb:NewDataObject(L['Addon Name'], ldbObj);
	self.ldbUpdated = 0;
	self.ldbLable = '';
    
    -- Start the minimap icon
	self.ldbIcon:Register(L['Addon Name'], self.ldb, self.db.global.minimap);
    
    -- Register Options
	SIL_Options.args.purge.desc = SIL:Replace(L['Help Purge Desc'], 'num', self:GetPurge() / 24);
	self.aceConfig:RegisterOptionsTable(L['Addon Name'], SIL_Options, {"sil", "silev", "simpleilevel"});
	self.aceConfigDialog:AddToBlizOptions(L['Addon Name']);
    
    -- Add Hooks
    self.inspect:AddHook('SimpleILevel', 'items', function(...) SIL:ProcessInspect(...); end);
    GameTooltip:HookScript("OnTooltipSetUnit", function(...) SIL:TooltipHook(...); end);
    self:Autoscan(self:GetAutoscan());
    self:RegisterEvent("PLAYER_TARGET_CHANGED");
    self:RegisterEvent("UPDATE_MOUSEOVER_UNIT");
    self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED");
    
    -- Add to Paperdoll - not relevent as of 4.3, well see
    table.insert(PAPERDOLL_STATCATEGORIES["GENERAL"].stats, L['Addon Name']);
	if self:GetPaperdoll() then
		PAPERDOLL_STATINFO[L['Addon Name']] = { updateFunc = function(...) SIL:UpdatePaperDollFrame(...); end };
	else
		PAPERDOLL_STATINFO[L['Addon Name']] = nil;
	end
    
    -- Clear the cache
	self:AutoPurge(true);
    
    -- Get working on a score for the player
    self:StartScore('player');
    self:UpdateLDB(); -- This may cause excesive loading time...
end

-- Make sure the database is the latest version
function SIL:UpdateSettings()
    
    if self.db.global.version == self.versionMajor then
        -- Save version
    elseif self.db.global.version < 2.4 then
        for guid,info in pairs(SIL_CacheGUID) do
            SIL_CacheGUID[guid].total = nil;
            SIL_CacheGUID[guid].tooltip = nil;
            
            SIL_CacheGUID[guid].level = 85;
            SIL_CacheGUID[guid].guid = guid;
        end
    end
    
    -- Update version information
    self.db.global.version = self.versionMajor;
end

function SIL:AutoPurge(silent)
	if self:GetPurge() > 0 then
		local count = self:PurgeCache(self:GetPurge());
		
		if not silent then
			self:Print(self:Replace(L['Purge Notification'], 'num', count));
		end
		
		return count;
	else
		if not silent then
			self:Print(L['Purge Notification False']);
		end
		
		return false;
	end
end

function SIL:PurgeCache(hours)
	if tonumber(hours) then
		local maxAge = time() - (tonumber(hours) * 3600);
		local count = 0;
		
		for guid,info in pairs(SIL_CacheGUID) do
			if type(info.time) == "number" and info.time < maxAge then
				SIL_CacheGUID[guid] = nil;
				count = 1 + count;
			end
		end
		
		return count;
	else
		return false;
	end
end

function SIL:AddHook(hookType, callback)
	hookType = strlower(hookType);
	
	if hookType == 'tooltip' then
		table.insert(self.hookTooltip, callback);
    elseif hookType == 'inspect' then
		table.insert(self.hookInspect, callback);
	end
end

--[[
    
    Event Handlers
    
]]
function SIL:PLAYER_TARGET_CHANGED(e, target)
    if not target then target = 'target'; end

    if CanInspect(target) then
        self:GetScoreTarget(target, false);
    end
end

function SIL:UPDATE_MOUSEOVER_UNIT()
	self:ShowTooltip();
end

function SIL:PLAYER_EQUIPMENT_CHANGED()
    --print('PLAYER_EQUIPMENT_CHANGED'); 
    self:StartScore('player');
end

-- Used for autoscaning the group when people change gear
function SIL:UNIT_INVENTORY_CHANGED(e, unitID)
    --print('UNIT_INVENTORY_CHANGED'); 
	if InCombatLockdown() then return end
	
	if unitID and CanInspect(unitID) and not UnitIsUnit('player', unitID) and self.autoscan ~= time() then
        self.autoscan = time();
        
		self:StartScore(unitID);
	end
end

-- Used to hook the tooltip to avoid the full tooltip function
function SIL:TooltipHook()
	local name, unit = GameTooltip:GetUnit();
	local guid = false;
	
	if unit then
		guid = UnitGUID(unit);
	elseif name then
		guid = SIL:NameToGUID(name);
	end
	
	if tonumber(guid) and tonumber(guid) > 0 then
		self:ShowTooltip(guid);
    end
end

function SIL:Autoscan(toggle)
	if toggle then
		self:RegisterEvent("UNIT_INVENTORY_CHANGED");
	else 
		self:UnregisterEvent("UNIT_INVENTORY_CHANGED");
	end
	
	self.db.global.autoscan = toggle;
end

--[[

    Slash Handlers
    
]]
-- Reset the settings
function SIL:SlashReset()
	self:Print(L["Slash Clear"]);
	self.db:RegisterDefaults(SIL_Defaults);
	self.db:ResetDB('Default');
	self:SetMinimap(true);
    
    -- Clear the cache
    SIL_CacheGUID = {};
    self:GetScoreTarget('player', true);
    
    -- Update version information
    self.db.global.version = self.versionMajor;
end

function SIL:SlashGet(name)
    
    -- Get score by name
    if name and not (name == '' or name == 'target') then
        local score, age, items = self:GetScoreName(name);
        
        if score then
            age = self:AgeToText(age);
            
            local str = L['Slash Get Score True'];
			str = self:Replace(str, 'target', SIL_CacheGUID[SIL:NameToGUID(name)]['name']);
			str = self:Replace(str, 'score', self:FormatScore(score, items));
			str = self:Replace(str, 'ageLocal', age);
			
			self:Print(str);
            
        -- Nothing :(
        else
            local str = L['Slash Get Score False'];
            str = self:Replace(str, 'target', name);
            
            self:Print(str);
        end
    
    -- no name but we can inspect the current target
    elseif CanInspect('target') then
        self:SlashTarget();
    
    -- why do you ask so much of me but make no sence
    else
        self:Print(L["Slash Target Score False"]);
    end
end

function SIL:SlashTarget()
    self:StartScore('target', function(...) SIL:SlashTargetPrint(...); end);
end

function SIL:SlashTargetPrint(guid, score, items, age)
    if guid and score then
        local str = SIL:Replace(L['Slash Target Score True'], 'target', self:GUIDtoName(guid));
        str = self:Replace(str, 'score', self:FormatScore(score, items));
        
        self:Print(str);
    else
        self:Print(L['Slash Target Score False']);
    end
end

--[[

    Genaric LUA functions

]]
function SIL:Strpad(str, length, pad)
	if not pad then pad = ' '; end
	length = tonumber(length);
	
	if type(length) == "number" then
		while string.len(str) < length do
			str = str..pad;
		end
	end
	
	return str;
end

function SIL:Replace(str, var, value)
	if str and var and value then
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

--[[

    Basic Functions

]]
function SIL:GUIDtoName(guid)
	if SIL_CacheGUID[guid] then
		return SIL_CacheGUID[guid].name, SIL_CacheGUID[guid].realm;
	else
		return false;
	end
end

function SIL:NameToGUID(name, realm)
	if not name then return false end
	
	-- Try and get the realm from the name-realm
	if not realm then
		name, realm = strsplit('-', name, 2);
	end
	
	-- If no realm then set it to current realm
	if not realm or realm == '' then
		realm = GetRealmName();
	end
	
	if name then
		name = strlower(name);
		
		for guid,info in pairs(SIL_CacheGUID) do
			if strlower(info['name']) == name and info['realm'] == realm then
				return guid;
			end
		end
	end
	
	return false;
end

-- Get a GUID from just about anything
function SIL:GetGUID(target)
    if target then
        if tonumber(target) then
            return target;
        elseif UnitGUID(target) then
            return UnitGUID(target);
        else
            return SIL:NameToGUID(target);
        end
    else
        return false;
    end
end

-- Clear score
function SIL:ClearScore(target)
	local guid = self:GetGUID(target);
	
	if SIL_CacheGUID[guid] then
		SIL_CacheGUID[guid].score = false;
		SIL_CacheGUID[guid].items = false;
		SIL_CacheGUID[guid].time = false;
		
		return true;
	else
		return false;
	end
end;

function SIL:AgeToText(age, color)
	if type(color) == "nul" then color = false; end
	
	if type(age) == 'number' then
		if age > 86400 then
			age = self:Round(age / 86400, 2);
			str = L['Age Days'];
			hex = "ff0000";
		elseif age > 3600 then
			age = self:Round(age / 3600, 1);
			str = L['Age Hours'];
			hex = "33ccff";
		elseif age > 60 then
			age = self:Round(age / 60, 1);
			str = L['Age Minutes'];
			hex = "00ff00";
		else
			age = age;
			str = L['Age Seconds'];
			hex = "00ff00";
		end
		
		if color then
			return self:Replace(str, 'age', '|cFF'..hex..age..'|r');
		else
			return self:Replace(str, 'age', age);
		end
	else
		return 'n/a';
	end
end

-- Play around with to test how color changes will work
function SIL:ColorTest(l,h)
	for i = l,h do
		self:Print(self:FormatScore(i));
	end
end

-- print a message to channel or whisper player/channel
function SIL:PrintTo(message, channel, to)
	if channel == "print" or channel == "SYSTEM" then
		self:Print(message);
	elseif channel == "WHISPER" then
		SendChatMessage(message, 'WHISPER', nil, to);
	elseif channel == "CHANNEL" then
		SendChatMessage(message, 'CHANNEL', nil, to);
	elseif channel then
		SendChatMessage(message, channel);
	else
		self:Print(message);
	end
end

function SIL:CanOfficerChat()
	GuildControlSetRank(select(3,GetGuildInfo("player")));
	local flags = self:Flags2Table(GuildControlGetRankFlags());
	return flags[4];
end

function SIL:Flags2Table(...)
	local ret = {}
	for i = 1, select("#", ...) do
		if (select(i, ...)) then
			ret[i] = true;
		else
			ret[i] = false;
		end
	end
	return ret;
end

function SIL:Debug(...)
	if SIL_Debug then
		print('SIL Debug: ', ...);
	end
end

--[[

    Core Functionality
    
]]
-- Get someones score
function SIL:GetScore(guid, attemptUpdate, target)
    if not tonumber(guid) then return false; end
    
	if SIL_CacheGUID[guid] and SIL_CacheGUID[guid].score then
		local score = SIL_CacheGUID[guid].score;
		local age = time() - SIL_CacheGUID[guid].time;
		local items = SIL_CacheGUID[guid].items;
		
        -- If a target was passed and we are over age
        if target and (attemptUpdate or self:GetAge() < age) then
            self:StartScore(target);
        end
        
		return score, age, items;
	else
        
        -- If a target was passed
        if target then
            self:StartScore(target);
        end
        
        return false;
	end
end

-- Wrapers for get score, more specialized code may come
function SIL:GetScoreName(name)
    local guid = self:NameToGUID(name);
    return self:GetScore(guid);
end

function SIL:GetScoreTarget(target, force)
    local guid = UnitGUID(target);
    return self:GetScore(guid, force, target);
end

function SIL:GetScoreGUID(guid)
    return self:GetScore(guid);
end

-- Request items to update a score
function SIL:StartScore(target, callback)
    if InCombatLockdown() then return false; end
    if not CanInspect(target) then return false; end
    
    local guid = self:AddPlayer(target);
    
    if not self.lastScan[target] or self.lastScan[target] ~= time() then
        if guid then
            self.action[guid] = callback;
            self.lastScan[target] = time();
            
            local canInspect = self.inspect:RequestItems(target, true);
            
            if not canInspect and callback then
                callback(false);
            else
                return true;
            end
        elseif callback then
            callback(false);
        end
    elseif callback then
        callback(false);
    end
    
    return false;
end

function SIL:ProcessInspect(guid, data, age)
    if guid and SIL_CacheGUID[guid] and type(data) == 'table' and type(data.items) == 'table' then
        
        local totalScore, totalItems = self:GearSum(data.items, SIL_CacheGUID[guid].level);
        
        if totalItems and totalItems > 0 then
            
            -- Update the DB
            local score = totalScore / totalItems;
            self:SetScore(guid, score, totalItems, age)
            
            self:Debug('SIL:ProcessInspect time', SIL_CacheGUID[guid].time, time(), age);
            
            -- Update LDB
            if self:GetLDB() and guid == UnitGUID('player') then
                self:UpdateLDB(true);
            end
            
            -- Run Hooks
            if self.hookInspect and type(self.hookInspect) == 'table' then
                for i,callback in pairs(self.hookInspect) do
                    callback(guid, score, totalItems, age, data.items);
                end
            end
            
            -- Run any callbacks for this event
            if self.action[guid] then
                self.action[guid](guid, score, items, age);
                self.action[guid] = false;
            end
            
            -- Update the Tooltip
            self:ShowTooltip();
            
            return true;
        end
    end
end

function SIL:GearSum(items, level)
    if items and level and type(items) == 'table' then
        local totalItems = 0;
        local totalScore = 0;
        
        for i,itemLink in pairs(items) do
            if i ~= INVSLOT_BODY and itemLink then
                local _, _, itemRarity , itemLevel = GetItemInfo(itemLink);
                
                if itemLevel then
                    
                    -- Fix for heirlooms
                    if itemRarity == 7 then
                        itemLevel = self:Heirloom(level, itemLink);
                    end
                    
                    totalItems = totalItems + 1;
                    totalScore = totalScore + itemLevel;
                end
            end
        end
        
        return totalScore, totalItems;
    else
        return false;
    end
end

-- /run for i=1,25 do t='raid'..i; if UnitExists(t) then print(i, UnitName(t), CanInspect(t), SIL:RoughScore(t)); end end
function SIL:RoughScore(target)
    if not target then return false; end
    if not CanInspect(target) then return false; end
    
    -- Get stuff in order
    local guid = self:AddPlayer(target)
    self.inspect:AddCharacter(target);
    NotifyInspect(target);
    
    -- Get items and sum
    local items = self.inspect:GetItems(target);
    local totalScore, totalItems = self:GearSum(items, UnitLevel(target));
    
    if totalItems and totalItems > 0 then
        local score = totalScore / totalItems;
        self:Debug('SIL:RoughScore', UnitName(target), score, totalItems);
        
        -- Set a score even tho its crap
        if guid and SIL_CacheGUID[guid] and not SIL_CacheGUID[guid].score then
            self:SetScore(UnitGUID(target), score, 1, self:GetAge() + 1);
        end
        
        return score, totalItems, 0;
    else
        return false;
    end
end

-- Start or update the DB for a player
function SIL:AddPlayer(target)  
    local guid = UnitGUID(target);
    
    if guid then
        local name, realm = UnitName(target);
        local _, class = UnitClass(target);
        local level = UnitLevel(target);
        
        if not realm then
            realm = GetRealmName();
        end
        
        if name and realm and class and level then
            
            -- Start a table for them
            if not SIL_CacheGUID[guid] then
                SIL_CacheGUID[guid] = {};
            end
            
            SIL_CacheGUID[guid].name = name;
            SIL_CacheGUID[guid].realm = realm;
            SIL_CacheGUID[guid].guid = guid;
            SIL_CacheGUID[guid].class = class;
            SIL_CacheGUID[guid].level = level;
            SIL_CacheGUID[guid].target = target;
            
            if not SIL_CacheGUID[guid].score or SIL_CacheGUID[guid].score == 0 then
                SIL_CacheGUID[guid].score = false;
                SIL_CacheGUID[guid].items = false;
                SIL_CacheGUID[guid].time = false;
            end
            
            return guid;
        else
            return false;
        end
    else
        return false;
    end
end

function SIL:SetScore(guid, score, items, age)
    local t = age;
    
    if age and type(age) == 'number' and age < 86400 then
        t = time() - age; 
    end
    
    SIL_CacheGUID[guid].score = score;
    SIL_CacheGUID[guid].items = items;
    SIL_CacheGUID[guid].time = t;
end

-- Get a relative iLevel on Heirlooms
function SIL:Heirloom(level, itemLink)
	--[[
		Here is how I came to the level 81-85 bracket
		200 = level of 80 instance gear
		333 = level of 85 instance gear
		333 - 200 = 133 iLevels / 5 levels = 26.6 iLevel per level
		so then that means for a level 83
		83 - 80 = 3 * 26.6 = 79.8 + 200 = 279.8 iLevel
	]]
	
	-- Check for Wrath Heirlooms that max at 80
	if level > 80 then
		local _, _, _, _, itemId = string.find(itemLink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?");
		itemId = tonumber(itemId);
		
		-- Downgrade it to 80 if found
		for k,iid in pairs(SIL_Heirlooms[80]) do
			if iid == itemId then
				level = 80;
			end
		end
	end
	
	if level > 80 then
		return (( level - 80) * 26.6) + 200;
	elseif level > 70 then
		return (( level - 70) * 10) + 100;
	elseif level > 60 then
		return (( level - 60) * 4) + 60;
	else
		return level;
	end
end

-- Format the score for color and round it to xxx.x
function SIL:FormatScore(score, items, color)
	if type(color) == "nil" then color = true; end
	
	if tonumber(score) then
		local score = tonumber(score);
		local hexColor = self:ColorScore(score, items);
		local score = self:Round(score, 1);
		
		if color then
			return '|cFF'..hexColor..score..'|r';
		else
			return score;
		end
	else
		return L["Unknown Score"];
	end
end

-- Return the hex, r, g, b of a score
function SIL:ColorScore(score, items)
	
    -- There are some missing items so gray
	if items and items < self.grayScore then
		return self:RGBtoHex(0.5,0.5,0.5), 0.5,0.5,0.5;
    end
    
    -- Default to white
	local r,g,b = 1,1,1;
	
	local found = false;
	
	for i,maxScore in pairs(SIL_ColorIndex) do
		if score < maxScore and not found then
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
	
	-- Nothing was found so max
	if not found then
		r = SIL_Colors[1000]['r'];
		g = SIL_Colors[1000]['g'];
		b = SIL_Colors[1000]['b'];
	end
	
    local hex = self:RGBtoHex(r,g,b);
	return hex, r, g, b;
end

function SIL:ShowTooltip(guid)
	if not guid then
		guid = UnitGUID("mouseover");
	end
	
	if SIL_CacheGUID[guid] and SIL_CacheGUID[guid].score then
		
		local score, age, items = self:GetScore(guid);
		
		-- Build the tooltip text
		local textLeft = '|cFF216bff'..L['Tool Tip Left']..'|r ';
		local textRight = self:Replace(L['Tool Tip Right'], 'score', self:FormatScore(score, items));
		
		local textAdvanced = self:Replace(L['Tool Tip Advanced'], 'localizedAge', self:AgeToText(age, true));
		
		self:AddTooltipText(textLeft, textRight, textAdvanced);
		
		-- Run Hooks
        if self.hookTooltip and type(self.hookTooltip) == 'table' then
            for i,callback in pairs(self.hookTooltip) do
                callback(guid);
            end
        end
		
		return true;
	else
		return false;
	end
end

-- Add lines to the tooltip, testLeft must be the same
function SIL:AddTooltipText(textLeft, textRight, textAdvanced, textAdvancedRight)
	
	-- Loop tooltip text to check if its alredy there
	local ttLines = GameTooltip:NumLines();
	local ttUpdated = false;
	
	for i = 1,ttLines do
        
		-- If the static text matches
		if _G["GameTooltipTextLeft"..i]:GetText() == textLeft then
			
			-- Update the text
			_G["GameTooltipTextLeft"..i]:SetText(textLeft);
			_G["GameTooltipTextRight"..i]:SetText(textRight);
			GameTooltip:Show();
			
			-- Update the advanced info too
			if self.db.global.advanced and textAdvanced then
                
                if textAdvancedRight then
                    _G["GameTooltipTextLeft"..i]:SetText(textAdvanced);
                    _G["GameTooltipTextRight"..i]:SetText(textAdvancedRight);
                else
                    _G["GameTooltipTextLeft"..i+1]:SetText(textAdvanced);
                end
                
				GameTooltip:Show();
			end
			
			-- Rember that we have updated the tool tip so we wont again
			ttUpdated = true;
			break;
		end
	end
	
	-- Tooltip is new
	if not ttUpdated then
		
		GameTooltip:AddDoubleLine(textLeft, textRight);
		GameTooltip:Show();
		
		if self.db.global.advanced and textAdvanced then
            if textAdvancedRight then
                GameTooltip:AddDoubleLine(textAdvanced, textAdvancedRight);
            else
                GameTooltip:AddLine(textAdvanced);
            end
            
			GameTooltip:Show();
		end
	end
end

function SIL:UpdatePaperDollFrame(statFrame, unit)
    local score, age, items = self:GetScoreTarget(unit, true);
    local formated = self:FormatScore(score, items, false);
    
    PaperDollFrame_SetLabelAndText(statFrame, L["Addon Name"], formated, false);
    statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..L["Addon Name"]..FONT_COLOR_CODE_CLOSE;
    statFrame.tooltip2 = L["Score Desc"];
    
    statFrame:Show();
end

--[[

    Setters, Getter and Togglers

]]

-- Set
function SIL:SetAdvanced(v) self.db.global.advanced = v; end
function SIL:SetLabel(v) self.db.global.showLabel = v; self:UpdateLDB(); end
function SIL:SetAutoscan(v) self.db.global.autoscan = v; self:Autoscan(v); end
function SIL:SetAge(seconds) self.db.global.age = seconds; end
function SIL:SetLDBlabel(v) self.db.global.ldbLabel = v; self:UpdateLDB(true); end
function SIL:SetLDBrefresh(v) self.db.global.ldbRefresh = v; end

-- Get
function SIL:GetAdvanced() return self.db.global.advanced; end
function SIL:GetMinimap() return not self.db.global.minimap.hide; end
function SIL:GetAutoscan() return self.db.global.autoscan; end
function SIL:GetPaperdoll() return self.db.global.cinfo; end
function SIL:GetAge() return self.db.global.age; end
function SIL:GetPurge() return self.db.global.purge; end
function SIL:GetLabel() return self.db.global.showLabel; end
function SIL:GetLDB() return self.db.global.ldbText; end
function SIL:GetLDBlabel() return self.db.global.ldbLabel; end
function SIL:GetLDBrefresh() return self.db.global.ldbRefresh; end

-- Toggle
function SIL:ToggleAdvanced() self:SetAdvanced(not self:GetAdvanced()); end
function SIL:ToggleMinimap() self:SetMinimap(not self:GetMinimap()); end
function SIL:ToggleAutoscan() self:SetAutoscan(not self:GetAutoscan()); end
function SIL:TogglePaperdoll() self:SetPaperdoll(not self:GetPaperdoll()); end
function SIL:ToggleLabel() self:SetLabel(not self:GetLabel()); end
function SIL:ToggleLDBlabel() self:SetLDBlabel(not self:GetLDBlabel()); end

-- Advanced sets
function SIL:SetPurge(hours) 
    self.db.global.purge = hours; 
    SIL_Options.args.purge.desc = SIL:Replace(L['Help Purge Desc'], 'num', self.db.global.purge / 24); 
end

function SIL:SetMinimap(v) 
    self.db.global.minimap.hide = not v;
	
	if not v then
		self.ldbIcon:Hide(L['Addon Name']);
	else
		self.ldbIcon:Show(L['Addon Name']);
	end
end

function SIL:SetPaperdoll(v)
	self.db.global.cinfo = v;
	
	if v then
		PAPERDOLL_STATINFO[L['Addon Name']] = { updateFunc = function(...) SIL:UpdatePaperDollFrame(...); end };
	else
		PAPERDOLL_STATINFO[L['Addon Name']] = nil;
	end
end

function SIL:SetLDB(v)
	self.db.global.ldbText = v;
	
	if v then
		--self:RegisterEvent("PARTY_MEMBERS_CHANGED");
		self.ldb.type = 'data source';
	else
		--self:UnregisterEvent("PARTY_MEMBERS_CHANGED");
		self.ldb.type = 'launcher';
		self.ldb.text = nil;
	end
	
	self:UpdateLDB(true);
end

--[[
    
    GUI Functions
    
]]

-- Open the options window
function SIL:ShowOptions()
    InterfaceOptionsFrame_OpenToCategory(L['Addon Name']);
end


function SIL:OpenMenu(window)
	
	-- Don't do anything in combat
	if InCombatLockdown() then return end
	
	if not self.silmenu then
		self.silmenu = CreateFrame("Frame", "SILMenu")
	end
	local menu = self.silmenu
	
	
	-- This will try and update but nothing will be shown until the menu is opened again
	local score, age, items = self:GetScoreTarget('player', true);
	
	-- Start a group score
    local groupScore, groupCount = false;
    if SIL_Group then
        groupScore, groupCount = SIL_Group:GroupScore(false);
        groupScore = self:FormatScore(groupScore);
    end
	
    -- Start the menu
	menu.displayMode = "MENU";
	local info = {};
	menu.initialize = function(self,level)
		if not level then return end
		wipe(info);
        
		if level == 1 then
			
			-- Title
			info.isTitle = 1;
			info.text = L["Addon Name"]..' '..SIL.version;
			info.notCheckable = 1;
			UIDropDownMenu_AddButton(info, level);
			
			-- Spacer
			wipe(info);
			info.disabled = 1;
			info.notCheckable = 1;
			UIDropDownMenu_AddButton(info, level);
			
			-- Some sort of group
			if GetNumPartyMembers() > 0 and SIL_Group then
				wipe(info);
				info.notCheckable = 1;
				info.hasArrow = 1;
				info.text = L["Help Group"]..' '..groupScore;
				info.value = {};
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
			if type(UIDROPDOWNMENU_MENU_VALUE) == "table" and SIL_Group then
				local v = UIDROPDOWNMENU_MENU_VALUE;
				
				wipe(info)
		        info.isTitle = 1;
				info.notCheckable = 1;
		        info.text = L["Help Group"];
		        UIDropDownMenu_AddButton(info, level);
				
				-- Console - CHAT_MSG_SYSTEM 
				wipe(info);
				info.text = CHAT_MSG_SYSTEM;
				info.func = function() SIL_Group:GroupOutput("SYSTEM"); end;
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
				info.func = function() SIL_Group:GroupOutput("PARTY"); end;
				info.notCheckable = 1;
				UIDropDownMenu_AddButton(info, level);
				
				-- Raid - CHAT_MSG_RAID 
				if UnitInRaid("player") then
					wipe(info);
					info.text = CHAT_MSG_RAID;
					info.func = function() SIL_Group:GroupOutput("RAID"); end;
					info.notCheckable = 1;
					UIDropDownMenu_AddButton(info, level);
				end
				
				-- BG - CHAT_MSG_RAID 
				if UnitInBattleground("player") then
					wipe(info);
					info.text = CHAT_MSG_BATTLEGROUND;
					info.func = function() SIL_Group:GroupOutput("BG"); end;
					info.notCheckable = 1;
					UIDropDownMenu_AddButton(info, level);
				end
				
				-- Guild - CHAT_MSG_GUILD 
				if IsInGuild() then
					wipe(info);
					info.text = CHAT_MSG_GUILD;
					info.func = function() SIL_Group:GroupOutput("GUILD"); end;
					info.notCheckable = 1;
					UIDropDownMenu_AddButton(info, level);
					
					-- Officer - CHAT_MSG_OFFICER
					if SIL:CanOfficerChat() then
						wipe(info);
						info.text = CHAT_MSG_OFFICER;
						info.func = function() SIL_Group:GroupOutput("OFFICER"); end;
						info.notCheckable = 1;
						UIDropDownMenu_AddButton(info, level);
					end
				end
				
				-- Say - CHAT_MSG_SAY
				wipe(info);
				info.text = CHAT_MSG_SAY;
				info.func = function() SIL_Group:GroupOutput("SAY"); end;
				info.notCheckable = 1;
				UIDropDownMenu_AddButton(info, level);
			end
		end
	end
	
	local x,y = GetCursorPosition(UIParent);
	ToggleDropDownMenu(1, nil, menu, "UIParent", x / UIParent:GetEffectiveScale() , y / UIParent:GetEffectiveScale());
end

function SIL:UpdateLDB(force)
    
	if self:GetLDB() then
		local label = UnitName('player');
		
        if SIL_Group then
            _,label = SIL_Group:GroupType();
		end
        
		-- Do we really need to update LDB?
		if force or label ~= self.ldbLable or (self.ldbUpdated + self:GetLDBrefresh()) < time() then
            
            local score = L["Unknown Score"];
            
            if SIL_Group then
                score = SIL_Group:GroupScore(false);
            elseif UnitGUID('player') then
                score = self:GetScoreTarget('player');
            end
			
			self:UpdateLDBText(label, score)
		end
	else
		self.ldb.type = 'launcher';
		self.ldb.text = nil;
		
		-- Make sure we arn't still somehow registered
		self:UnregisterEvent("PARTY_MEMBERS_CHANGED");
	end
end

function SIL:UpdateLDBText(label, text)
    if not self:GetLDB() then return false; end
    
    -- A score was passed
    if tonumber(text) then
        text = self:FormatScore(text);
    end
    
    -- Add the label
    if self:GetLDBlabel() then
        text = label..": "..text;
    end
    
    self.ldb.text = text;
    self.ldbUpdated = time();
    self.ldbLable = label;
end


