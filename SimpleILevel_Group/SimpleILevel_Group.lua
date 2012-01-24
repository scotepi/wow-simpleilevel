--[[
ToDo:
    - 
]]

local L = LibStub("AceLocale-3.0"):GetLocale("SimpleILevel", true);
SIL_Group = LibStub("AceAddon-3.0"):NewAddon('SIL_Group', "AceEvent-3.0", "AceTimer-3.0");
SIL_Group.group = {};  -- { guid, score }
SIL_Group.autoscan = false;
SIL_Group.autoscanFailed = 0;
SIL_Group.autoscanLog = {};

-- Update SIL_Options table
SIL_Options.args.group = {
            name = L.group.options.group,
            desc = L.group.options.groupDesc,
            type = "input",
            guiHidden = true,
            set = function(i,v) dest, to = strsplit(' ', v, 2); SIL_Group:GroupOutput(dest, to); end,
            get = function() return ''; end,
        };
SIL_Options.args.party = {
            name = L.group.options.group,
            desc = L.group.options.groupDesc,
            type = "input",
            hidden = true,
            set = function(i,v) dest, to = strsplit(' ', v, 2); SIL_Group:GroupOutput(dest, to); end,
            get = function() return ''; end,
        };
SIL_Options.args.raid = SIL_Options.args.party;


function SIL_Group:OnInitialize()
    SIL:Print(L.group.load, GetAddOnMetadata("SimpleILevel_Group", "Version"));
    
    -- Keep our self.group sane
    self:RegisterEvent("PARTY_MEMBERRS_CHANGED", function() SIL_Group:UpdateGroup(false) end);
    
    self:UpdateGroup(false);
end

-- Popupdate SIL_Group.group
function SIL_Group:UpdateGroup()
    
    -- Reset the group table
    self.group = {};

    local yourGUID = UnitGUID('player');
    local yourScore = SIL:GetScoreTarget('player');
    local groupSize = 0;
    
    if self:AddGroupMember(yourGUID, 'player') then
        groupSize = groupSize + 1;
    end
    
    local groupType = self:GroupType();
    
    if groupType == 'raid' or groupType == 'battleground' then
        for i = 1, 40 do
            local target = 'raid'..i;
            local guid = SIL:AddPlayer(target);
            
            -- Skip ourself
            if guid and not UnitIsUnit('player', target) then
                local score = SIL:GetScoreTarget(target);
                
                if self:AddGroupMember(guid, target) then
                    groupSize = groupSize + 1;
                end
            end
        end
    elseif groupType == 'party' then
        for i = 1,4 do
			if GetPartyMember(i) then
				local target = 'party'..i;
                local guid = SIL:AddPlayer(target);
                local score = SIL:GetScoreTarget(target);
                
                if guid and self:AddGroupMember(guid, target) then
                    groupSize = groupSize + 1;
                end
            end
        end
    end
    
    -- Make sure we are in a group
    if 1 < #self.group and SIL:GetAutoscan() then
        
        -- Start autoscan
        if not self.autoscan then
            self:AutoscanStart();
        else
            self:Autoscan();
        end
    end
end

function SIL_Group:AddGroupMember(guid, target)
    if guid and SIL:Cache(guid) and not self:InTable(self.group, guid) then
        
        -- Set the autoscan log
        if not self.autoscanLog[guid] then
            self.autoscanLog[guid] = 0;
        end
        
        table.insert(self.group, guid);
        
        if SIL:Cache('guid', 'score') then
            return true;
        else
            return false;
        end
    else
        return false;
    end
end

-- Sumerize SIL_Group
function SIL_Group:GroupScore()
    self:UpdateGroup(false);
    
    local groupSize = 0;
    local totalScore = 0;
    local groupMin = totalScore;
    local groupMax = totalScore;
    local groupType, groupName = self:GroupType();
    
    for _,guid in pairs(self.group) do
        local score = SIL:Cache(guid, 'score');
        
        if score and score ~= 0 then
            groupSize = groupSize + 1;
            totalScore = totalScore + score;
            
            if score < groupMin then groupMin = score; end
            if score > groupMax then groupMax = score; end
        end
    end
    
    local groupAvg = totalScore / groupSize;
    SIL:UpdateLDBText(groupName, groupAvg);
    return groupAvg, groupSize, groupMin, groupMax;
end

function SIL_Group:GroupOutput(dest, to)
    --if InCombatLockdown() then return false; end
    
    self:UpdateGroup(true); -- Get the scores updated
    local groupAvg, groupSize, groupMin, groupMax = self:GroupScore(true);
    local dest, to, color = self:GroupDest(dest, to);
    local rough = false;
    
	groupAvgFmt = SIL:FormatScore(groupAvg, 16, color);
    
	SIL:PrintTo(format(L.group.outputHeader, groupAvgFmt), dest, to);
    
    -- Sort by score
    table.sort(self.group, function(...) return SIL_Group:SortScore(...); end);
    
    for _,guid in ipairs(self.group) do
		local name = SIL:Cache(guid, 'name');
		local items = SIL:Cache(guid, 'items');
		local score = SIL:Cache(guid, 'score');
        local class = SIL:Cache(guid, 'class');
        local str = '';
        
		if color then
            name = '|cFF'..SIL:RGBtoHex(RAID_CLASS_COLORS[class].r, RAID_CLASS_COLORS[class].g, RAID_CLASS_COLORS[class].b)..name..'|r';
        end
            
		if score and tonumber(score) and 0 < score then
            str = format('%s (%s)', name, SIL:FormatScore(score, items, color));
            
            if items <= SIL.grayScore then
                str = str..' *';
                rough = true;
            end
		else
            str = format(L.group.outputNoScore, name);
        end
        
		SIL:PrintTo(str, dest, to);
	end
    
    if rough then
        SIL:PrintTo(L.group.outputRough, dest, to);
    end
end

-- Figure out the type of group we are in
function SIL_Group:GroupType()
    local _, itype = GetInstanceInfo();
    
    if itype == 'arena' then
        return 'arena', ARENA;
    elseif UnitInBattleground("player") then
        return 'battleground', CHAT_MSG_BATTLEGROUND;
    elseif UnitInRaid("player") then
        return 'raid', CHAT_MSG_RAID;
    elseif GetNumPartyMembers() > 0 then
        return 'party', CHAT_MSG_PARTY;
    else
        return 'solo', UnitName('player');
    end
end

function SIL_Group:GroupDest(dest, to)
	local valid = false;
	local color = false;
    
	if not ( dest ) then dest = "SYSTEM"; valid = true; end
	if ( dest == '' ) then dest = "SYSTEM"; valid = true; end
	dest = string.upper(dest);
	
	-- Some short codes
	if ( dest == 'P' ) then dest = 'PARTY'; valid = true; end
	if ( dest == 'R' ) then dest = 'RAID'; valid = true; end
	if ( dest == 'BG' ) then dest = 'BATTLEGROUND'; valid = true; end
	if ( dest == 'G' ) then dest = 'GUILD'; valid = true; end
	if ( dest == 'U' ) then dest = 'GROUP'; valid = true; end
	if ( dest == 'O' ) then dest = 'OFFICER'; valid = true; end
	if ( dest == 'S' ) then dest = 'SAY'; valid = true; end
	if ( dest == 'T' ) then dest = 'WHISPER'; valid = true; end
	if ( dest == 'W' ) then dest = 'WHISPER'; valid = true; end
	if ( dest == 'TELL' ) then dest = 'WHISPER'; valid = true; end
	if ( dest == 'C' ) then dest = 'CHANNEL'; valid = true; end
	
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
	
	-- Figure out GROUP
	if ( dest == 'GROUP' ) then
		if ( UnitInRaid("player") ) then
			dest = 'RAID';
		elseif ( GetNumPartyMembers() > 0 ) then
			dest = 'PARTY';
		else
			dest = 'SAY';
		end
	end
	
    if dest == "SYSTEM" then
        color = true;
    end
    
	return dest, to, color;
end

function SIL_Group:SortScore(a, b)
    scoreA = SIL:Cache(a, 'score') or 0;
    scoreB = SIL:Cache(b, 'score') or 0;
    
    return scoreA > scoreB;
end

--[[
    Automatic scanning methods
]]
function SIL_Group:Autoscan(autoscan)
    if InCombatLockdown() then return end
    
    -- Check that we have a good group values
    if type(self.group) ~= 'table' or #self.group == 0 then
        self:UpdateGroup();
    end
    
    -- Stop if we are all alone :(
    if autoscan and 1 == #self.group then self:AutoscanStop(); end
    
    -- Get the worst score in the group
    local target, reason, value = self:AutoscanNext(autoscan);
    
    if target then
        local guid = UnitGUID(target);
        self.autoscanLog[guid] = self.autoscanLog[guid] + 1;
        
        SIL:Debug('Found someone to Scan!', UnitName(target), target, reason, value);
        
        SIL:GetScoreTarget(target, true, function(...) SIL_Group:AutoscanCallback(...); end);
        
        -- Reset failed
        self.autoscanFailed = 0;
        
    -- Bummer :(
    else
        SIL:Debug('Cant find anyone to scan :(');
        
        if autoscan then
            self.autoscanFailed = self.autoscanFailed + 1;
            
            if self.autoscanFailed >= 2 then
                SIL:Debug('Autscan Failed', self.autoscanFailed);
                self:AutoscanStop();
            end
        end
    end
end

-- Not sure what to do with this yet other then debug
function SIL_Group:AutoscanCallback(guid, score, items, age)
    if guid then
        SIL:Debug('AutoscanCallback', SIL:Cache(guid, 'name'), guid, score, items, age);
    else
        SIL:Debug('AutoscanCallback');
    end
end

function SIL_Group:AutoscanNext()
    
    -- Macro to clear the score of everyone in your group and reset SIL_Group
    -- /run for _,g in pairs(SIL_Group.group) do SIL.cache[g]=nil; end SIL_Group.group={}; SIL_Group.autoscanLog={}; SIL.debug=true; SIL_Group:UpdateGroup();
    
    local yourScore = SIL:GetScoreTarget('player', false);
    
    -- Set some high min values
    local lowItems = SIL.grayScore * 1.5;            -- currently 8 * 1.5 = 12 items
    local lowScore = yourScore / 2;                  -- this should scale well leveling
    local oldScore = time() - (SIL:GetAge() * 0.75); -- 75% of max age
    
    local lowItemsT = false;
    local lowScoreT = false;
    local oldScoreT = false;
    
    -- Loop
    for _,guid in pairs(self.group) do
        local target = SIL:Cache(guid, 'target');
        
        if CanInspect(target) and self.autoscanLog[guid] <= 3 and not UnitIsUnit('player', target) then
            
            local items = SIL:Cache(guid, 'items') or 0;
            local score = SIL:Cache(guid, 'score') or 0;
            local time = SIL:Cache(guid, 'time') or 0;
            
            -- SIL:Debug(SIL:Cache(guid, 'name'), SIL:Cache(guid, 'items'), items, SIL:Cache(guid, 'score'), score, SIL:Cache(guid, 'time'), time);
            
            -- Items
            if items < lowItems then
                lowItems = items;
                lowItemsT = target;
            end
            
            -- Score
            if score < lowScore then
                lowScore = score;
                lowScoreT = target;
            end
            
            -- Age
            if time < oldScore then
                oldScore = time;
                oldScoreT = target;
            end
        end
    end
    
    -- Figure out the person
    if lowItemsT then
        return lowItemsT, 'items', lowItems;
    elseif lowScoreT then
        return lowScoreT, 'score', lowScore;
    elseif oldScoreT then
        return oldScoreT, 'age', oldScore;
    else
        return false;
    end
end

function SIL_Group:AutoscanStart()
    if not self.autoscan and SIL:GetAutoscan() then 
        self.autoscan = self:ScheduleRepeatingTimer(function() 
            if not InCombatLockdown() then 
                SIL:Debug('Autoscaning...'); 
                SIL_Group:Autoscan(true); 
            end 
        end, 5);
    end
end

function SIL_Group:AutoscanStop()
    if self.autoscan then
        self:CancelTimer(self.autoscan, true);
        self.autoscan = false;
        self.autoscanFailed = 0;
    end
end

function SIL_Group:InTable(tabl, value, continue)
    local found = false;
    local keys = {};
    
    for i,v in pairs(tabl) do
        if v == s then
            
            if continue then
                found = true;
                keys = i;
                
                return true, i;
            else
                found = true;
                table.insert(keys, i);
            end
        end
    end
    
    return found, keys;
end