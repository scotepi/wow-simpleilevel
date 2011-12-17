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
    print("SIL Group Loaded");
    
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
    self:RegisterEvent("RAID_ROSTER_UPDATE", function() SIL_Group:UpdateGroup() end);
    self:RegisterEvent("PARTY_MEMBERS_CHANGED", function() SIL_Group:UpdateGroup() end);
    self:RegisterEvent("SIL_HAVE_SCORE");
    
    self:UpdateGroup(false);
end

-- Popupdate SIL_Group.group
function SIL_Group:UpdateGroup(force)
    
    -- Reset the group table
    self.group = {};
    
    -- Start it off with ourself
    local yourGUID = UnitGUID('player');
    local yourScore = SIL:GetScore('player', force);
    local groupSize = 0;
    
    if self:AddGroupMember(yourGUID) then
        groupSize = groupSize + 1;
    end
    
    local groupType = self:GroupType();
    
    if groupType == 'raid' or groupType == 'battleground' then
        for i = 1, 40 do
            local target = 'raid'..i;
            local guid = SIL:AddPlayer(target);
            
            -- Skip ourself
            if guid and guid ~= yourGUID then
                local score = SIL:GetScore(target, force);
                
                if self:AddGroupMember(guid) then
                    groupSize = groupSize + 1;
                end
            end
        end
    elseif groupType == 'party' then
        for i = 1,4 do
			if GetPartyMember(i) then
				local target = 'party'..i;
                local guid = SIL:AddPlayer(target);
                local score = SIL:GetScore(target, force);
                
                if self:AddGroupMember(guid) then
                    groupSize = groupSize + 1;
                end
            end
        end
    end
end

function SIL_Group:AddGroupMember(guid)
   -- print('SIL_Group:AddGroupMember', SIL:GUIDtoName(guid), guid, SIL_CacheGUID[guid]);
    if guid and SIL_CacheGUID[guid] then
        local player = {};
        player.guid = guid;
        player.score = SIL_CacheGUID[guid].score;
        
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
    local dest, to = self:GroupDest(dest, to);
    
    --print(dest, to, groupAvg, self.group);
    
    if dest == "SYSTEM" then
		groupAvgFmt = SIL:FormatScore(groupAvg, 16, true);
	else
		groupAvgFmt = SIL:FormatScore(groupAvg, 16, false);
	end
    
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
		
		if not score or score == 0 then
			str = L['Group Member Score False'];
		end
		
		if dest == "SYSTEM" then
			score = SIL:FormatScore(score, items, true);
			name = '|cFF'..SIL:RGBtoHex(RAID_CLASS_COLORS[class].r, RAID_CLASS_COLORS[class].g, RAID_CLASS_COLORS[class].b)..name..'|r';
		else
			score = SIL:FormatScore(score, items, false);
		end
		
		str = SIL:Replace(str, 'score', score);
		str = SIL:Replace(str, 'name', name);
		
		SIL:PrintTo(str, dest, to);
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
	
	return dest, to;
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