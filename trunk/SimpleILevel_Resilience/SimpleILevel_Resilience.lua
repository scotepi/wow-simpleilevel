--[[

PARTY_MEMBER_ENABLED - someone came within range

PARTY_MEMBERRS_CHANGED - something in the party/raid updated (vary freequent)
RAID_ROSTER_UPDATE same as PMC

unitID = UNIT_INVENTORY_CHANGED - fired twice when in raid, partyX/player and raidX

if in raid only do UNIT_INVENTORY_CHANGED raidXXX


]]

local L = LibStub("AceLocale-3.0"):GetLocale("SimpleILevel", true);
SIL_Resil = LibStub("AceAddon-3.0"):NewAddon('SIL_Resil', "AceEvent-3.0");

-- Add /sil pvp
if SIL_Group and false then
    SIL_Options.args.pvp = {
                name = GUILD_PVP_STATUS,
                desc = "Displayed the PvP gear of everyone in your group.",
                type = "input",
                hidden = true,
                guiHidden = true,
                cmdHidden = false,
                set = function(i,v) dest, to = strsplit(' ', v, 2); SIL_Resil:GroupOutput(dest, to); end,
                get = function() return ''; end,
            };
end

function SIL_Resil:OnInitialize()
    SIL:Print("Resilience Module Loaded", GetAddOnMetadata("SimpleILevel_Resilience", "Version"));
    
    if not type(SIL_Resilience) == 'table' then SIL_Resilience = {}; end
    
    SIL_Resilience.version = 0.1;
    
    SIL:AddHook('tooltip', function(...) SIL_Resil:Tooltip(...); end);
    SIL:AddHook('inspect', function(...) SIL_Resil:Inspect(...); end);
end

function SIL_Resil:Inspect(guid, score, itemCount, age, itemTable)
    -- print(guid, score, itemCount, age, itemTable);
	local resilience = 0;
	local rItems = 0;
	local total = 0;
	
	if itemTable and type(itemTable) == 'table' then
		for i,itemLink in pairs(itemTable) do
			local stats = GetItemStats(itemLink);
            
			if stats['ITEM_MOD_RESILIENCE_RATING_SHORT'] then
				local raw = stats['ITEM_MOD_RESILIENCE_RATING_SHORT'];
				
				resilience = resilience + raw;
				rItems = rItems + 1;
			end
			
			total = total + 1;
		end
	end
	
	SIL_Resilience[guid] = rItems;
end

function SIL_Resil:Tooltip(guid)
    local rItems = self:GetItemCount(guid);
	
	if rItems and 0 < rItems and SIL_CacheGUID[guid] and SIL_CacheGUID[guid].items then
        local per = SIL:Round((rItems / SIL_CacheGUID[guid].items) * 100, 1);
        local text = rItems..'/'..SIL_CacheGUID[guid].items..' '..per..'%';
		SIL:AddTooltipText(GUILD_PVP_STATUS..':', '|cFFFFFFFF'..text..'|r');
	end
end

function SIL_Resil:GetItemCount(guid)
    if SIL_Resilience[guid] and SIL_Resilience[guid] ~= 0 then
        return SIL_Resilience[guid];
    else
        return false;
    end
end

function SIL_Resil:GetItemCountName(name)
    local guid = SIL:NameToGUID(name);
    return self:GetItemCount(guid);
end

function SIL_Resil:GroupOutput(dest, to)
    if not SIL_Group then return false; end
    
    SIL_Group:UpdateGroup(true);
    
    local group = {};
    
    for i,player in ipairs(SIL_Group.group) do
        local guid = player.guid;
    end
end