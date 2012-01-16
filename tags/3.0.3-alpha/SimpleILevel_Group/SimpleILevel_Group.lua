--[[

PARTY_MEMBER_ENABLED - someone came within range

PARTY_MEMBERRS_CHANGED - something in the party/raid updated (vary freequent)
RAID_ROSTER_UPDATE same as PMC

unitID = UNIT_INVENTORY_CHANGED - fired twice when in raid, partyX/player and raidX

if in raid only do UNIT_INVENTORY_CHANGED raidXXX


]]

local L = LibStub("AceLocale-3.0"):GetLocale("SimpleILevel", true);
SIL_Group = LibStub("AceAddon-3.0"):NewAddon('SIL_Group', "AceEvent-3.0", "AceConsole-3.0");
SIL_Group.group = {};  -- { guid, score }

-- Update SIL_Options table
SIL_Options.args.group = {
            name = L['Help Group'],
            desc = L['Help Group Desc'],
            type = "input",
            hidden = true,
            guiHidden = true,
            cmdHidden = false,
            set = function(i,v) dest, to = strsplit(' ', v, 2); SIL_Group:GroupOutput(dest, to); end,
            get = function() return ''; end,
        };
SIL_Options.args.party = SIL_Options.args.group;
SIL_Options.args.party.cmdHidden = true;
SIL_Options.args.party.set = function(i,v) SIL_Group:GroupOutput(v); end;
SIL_Options.args.raid = SIL_Options.args.group;
SIL_Options.args.raid.cmdHidden = true;
SIL_Options.args.raid.set = function(i,v) SIL_Group:GroupOutput(v); end;


function SIL_Group:OnInitialize()
    SIL:Print("Group Module Loaded", GetAddOnMetadata("SimpleILevel_Group", "Version"));
    
    -- Version Info
    self.version = GetAddOnMetadata("SimpleILevel_Group", "Version");
	self.versionMajor = 0.1;                    -- Used for setting versioning
	self.versionRev = 'r@project-revision@';    -- Used for information
    
    -- Add a new settings tab
    --SIL.aceConfig:RegisterOptionsTable('SIL_Group', SIL_Group_Options, {'silg', 'silgroup'});
    
    -- Nothing to register yet but saving this for the record
    --SIL.aceConfigDialog:AddToBlizOptions('SIL_Group', nil, SIL.L['Addon Name']);
    
    -- Add /silg or /silgroup for self:GroupOutput(dest, to);
    
    -- Keep our self.group sane
    self:RegisterEvent("PARTY_MEMBERRS_CHANGED", function() SIL_Group:UpdateGroup(false) end);
    self:RegisterEvent("SIL_HAVE_SCORE");
    
    self:UpdateGroup(false);
end

-- Popupdate SIL_Group.group
function SIL_Group:UpdateGroup(force)
    
    -- Reset the group table
    self.group = {};
    -- /run for i=1,25 do if UnitName('raid'..i) then print(i,UnitName('raid'..i),SIL:GetScore(UnitGUID('raid'..i), true, 'raid'..i)); end end
    -- /run for i=1,25 do t='raid'..i; if UnitName(t) then print(i,UnitName(t),SIL.inspect:RequestItems(t, true),SIL.inspect:GetAge(SIL.inspect.cache[UnitGUID('raid'..i)].time),CanInspect(t)); end end
    
    -- /run for i=1,25 do t='raid'..i;g=UnitGUID(t);ins=SIL.inspect; if UnitName(t) then print(i, UnitName(t), ins:RequestItems(t, true), CanInspect(t), ins.cache[g].data == false, ins.cache[g].time == 0, (time() - ins.cache[g].time) > ins.maxAge); end end
    
    -- /run for i=1,4 do t='party'..i;g=UnitGUID(t);ins=SIL.inspect; if UnitName(t) then print(i, NotifyInspect(t)); end end
    -- Start it off with ourself
    local yourGUID = UnitGUID('player');
    local yourScore = SIL:GetScoreTarget('player', force);
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
            if not UnitIsUnit('player', target) then
                local score = SIL:GetScoreTarget(target, force);
                
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
                local score = SIL:GetScoreTarget(target, force);
                
                if self:AddGroupMember(guid, target) then
                    groupSize = groupSize + 1;
                end
            end
        end
    end
end

function SIL_Group:AddGroupMember(guid, target)
   -- print('SIL_Group:AddGroupMember', SIL:GUIDtoName(guid), guid, SIL_CacheGUID[guid]);
    if guid and SIL_CacheGUID[guid] then
        local player = {};
        player.guid = guid;
        
        --print('SIL_Group:AddGroupMember', SIL_CacheGUID[guid].name, SIL_CacheGUID[guid].score);
        
        if SIL_CacheGUID[guid].score and SIL_CacheGUID[guid].items > 4 then
            player.score = SIL_CacheGUID[guid].score;
        else
            local score, items = SIL:RoughScore(target);
            player.score = score;
        end
        
        table.insert(self.group, player);
        
        if player.score then
            return true;
        else
            return false;
        end
    else
        return false;
    end
end

-- Update SIL_Group.group with a new score
function SIL_Group:SIL_HAVE_SCORE(e, guid, score)
    for i,player in pairs(self.group) do
        if player.guid == guid then
            self.group[i].score = score;
            
            -- Only update if there is a new score
            if player.score ~= score then
                SIL:UpdateLDB();
            end
        end
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
    
    for i,player in pairs(self.group) do
        if player.score and player.score ~= 0 then
            groupSize = groupSize + 1;
            totalScore = totalScore + player.score;
            
            if player.score < groupMin then groupMin = player.score; end
            if player.score > groupMax then groupMax = player.score; end
        end
    end
    
    local groupAvg = totalScore / groupSize;
    SIL:UpdateLDBText(groupName, groupAvg);
    return groupAvg, groupSize, groupMin, groupMax;
end

function SIL_Group:GroupOutput(dest, to)
    if InCombatLockdown() then return false; end
    
    self:UpdateGroup(true); -- Get the scores updated
    local groupAvg, groupSize, groupMin, groupMax = self:GroupScore(true);
    local dest, to, color = self:GroupDest(dest, to);
    local rough = false;
    
	groupAvgFmt = SIL:FormatScore(groupAvg, 16, color);
    
    local str = L['Group Score'];
	str = SIL:Replace(str, 'avg', groupAvgFmt);
	SIL:PrintTo(str, dest, to);
    
    -- Sort by score
    table.sort(self.group, function(...) return SIL_Group:SortScore(...); end);
    
    for i,player in ipairs(self.group) do
        local guid = player.guid;
		local name = SIL_CacheGUID[guid].name;
		local str = "%name (%score)";
		local score = player.score;
		local items = SIL_CacheGUID[guid].items;
        local class = SIL_CacheGUID[guid].class;
        
		if color then
            name = '|cFF'..SIL:RGBtoHex(RAID_CLASS_COLORS[class].r, RAID_CLASS_COLORS[class].g, RAID_CLASS_COLORS[class].b)..name..'|r';
        end
            
		if not score or score == 0 then
			str = L['Group Member Score False'];
            
		else
            score = SIL:FormatScore(score, items, color);
            str = SIL:Replace(str, 'score', score);
            
            if items < SIL.grayScore then
                str = str..' *';
                rough = true;
            end
        end
        
        str = SIL:Replace(str, 'name', name);
		SIL:PrintTo(str, dest, to);
	end
    
    if rough then
        SIL:PrintTo(L["Group Rough"], dest, to);
    end
end

-- Figure out the type of group we are in
function SIL_Group:GroupType()
    
    if UnitInBattleground("player") then
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
    scoreA = a.score;
    scoreB = b.score;
    
    if not scoreA then
        scoreA = 0;
    end
    
    if not scoreB then
        scoreB = 0;
    end
    
    return scoreA > scoreB;
end
