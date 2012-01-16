--[[
ToDo:
    - /sil pvp
    - Options: to disable tooltip, show 0% tooltip, independant paperdoll controls
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
    
    table.insert(PAPERDOLL_STATCATEGORIES["GENERAL"].stats, 'SIL_Resil');
	if SIL:GetPaperdoll() then
		PAPERDOLL_STATINFO['SIL_Resil'] = { updateFunc = function(...) SIL_Resil:UpdatePaperDollFrame(...); end };
	else
		PAPERDOLL_STATINFO['SIL_Resil'] = nil;
	end
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
    if guid and tonumber(guid) then
        local rItems, items = self:GetItemCount(guid);
        
        if rItems and 0 < rItems and SIL_CacheGUID[guid] and SIL_CacheGUID[guid].items then
            local percent = self:GetPercent(guid);
            local text = rItems..'/'..SIL_CacheGUID[guid].items..' '..percent..'%';
            SIL:AddTooltipText(GUILD_PVP_STATUS..':', '|cFFFFFFFF'..text..'|r');
        else
            return false;
        end
    else
        return false;
    end
end

function SIL_Resil:GetItemCount(guid)
    if guid and tonumber(guid) and SIL_Resilience[guid] and SIL_Resilience[guid] ~= 0 then
        local rItems = SIL_Resilience[guid];
        local items = SIL_CacheGUID[guid].items;
        return rItems, items;
    else
        return false;
    end
end

function SIL_Resil:GetItemCountName(name, realm) return self:GetItemCount(SIL:NameToGUID(name, realm)); end
function SIL_Resil:GetItemCountTarget(target) return self:GetItemCount(UnitGUID(target)); end

function SIL_Resil:GetPercent(guid)
    local count, items = self:GetItemCount(guid);
    
    if count then
        local percent = SIL:Round((count / items) * 100, 1);
        return percent;
    else
        return 0;
    end
end

function SIL_Resil:GetPercentName(name, realm) return self:GetPercent(SIL:NameToGUID(name, realm)); end
function SIL_Resil:GetPercentTarget(target) return self:GetPercent(UnitGUID(target)); end

function SIL_Resil:GroupOutput(dest, to)
    if not SIL_Group then return false; end
    
    SIL_Group:UpdateGroup(true);
    
    local group = {};
    
    for i,player in ipairs(SIL_Group.group) do
        local guid = player.guid;
    end
end

function SIL_Resil:UpdatePaperDollFrame(statFrame, unit)
    local percent = self:GetPercentTarget(unit);
    local rItems, items = self:GetItemCountTarget(unit);
    local rating = GetCombatRating(COMBAT_RATING_RESILIENCE_PLAYER_DAMAGE_TAKEN);
    
    PaperDollFrame_SetLabelAndText(statFrame, GUILD_PVP_STATUS, percent..'%', false);
    statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..GUILD_PVP_STATUS..FONT_COLOR_CODE_CLOSE;
    
    if rItems then
        statFrame.tooltip2 = format(L['Resil Paperdoll Tooltip True'], rItems, items, rating);
    else
        statFrame.tooltip2 = L['Resil Paperdoll Tooltip False'];
    end
    
    statFrame:Show();
end

function SIL_Resil:SetPaperdoll(s,v)
    if SIL:GetPaperdoll() then
		PAPERDOLL_STATINFO['SIL_Resil'] = { updateFunc = function(...) SIL_Resil:UpdatePaperDollFrame(...); end };
	else
		PAPERDOLL_STATINFO['SIL_Resil'] = nil;
	end
end

hooksecurefunc(SIL, 'SetPaperdoll', function(...) SIL_Resil:SetPaperdoll(...) end);