--[[
ToDo:
    - /sil pvp
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
    SIL:Print(RESILIENCE.." Module Loaded", GetAddOnMetadata("SimpleILevel_Resilience", "Version"));
    
    if not type(SIL_Resilience) == 'table' then SIL_Resilience = {}; end
    
    self.db = LibStub("AceDB-3.0"):New("SIL_ResilSettings", SILResil_Defaults, true);
    SIL.aceConfig:RegisterOptionsTable("SimpleILevel_Resilience", SILResil_Options, {"sir", "silr", "sip", "silp", "simpleilevelresilience", "simpleilevelpvp"});
    SIL.aceConfigDialog:AddToBlizOptions("SimpleILevel_Resilience", RESILIENCE, L['Addon Name']);
    
    SIL:AddHook('tooltip', function(...) SIL_Resil:Tooltip(...); end);
    SIL:AddHook('inspect', function(...) SIL_Resil:Inspect(...); end);
    SIL:AddHook('purge', function(...) SIL_Resil:Purge(...); end);
    
    table.insert(PAPERDOLL_STATCATEGORIES["GENERAL"].stats, 'SIL_Resil');
	if self:GetPaperdoll() then
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
    if guid and tonumber(guid) and self:GetTooltip() ~= 0 then
        local rItems, items = self:GetItemCount(guid);
        
        if (rItems and 0 < rItems and items) or (self:GetTooltipZero() and items) then
            local percent = self:GetPercent(guid)..'%';
            local slash = rItems..'/'..items;
            local text = '';
            
            if self:GetTooltip() == 2 then
                text = slash;
            elseif self:GetTooltip() == 3 then
                text = percent;
            else
                text = slash..' '..percent;
            end
            
            SIL:AddTooltipText(GUILD_PVP_STATUS..':', '|cFFFFFFFF'..text..'|r');
        end
    end
end

function SIL_Resil:Purge(guid)
    SIL_Resilience[guid] = nil;
end

function SIL_Resil:GetItemCount(guid)
    if guid and tonumber(guid) and SIL_Resilience[guid] and SIL_CacheGUID[guid] then
        local rItems = SIL_Resilience[guid];
        local items = SIL_CacheGUID[guid].items;
        return rItems, items;
    else
        return false, false;
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

--[[
    Setters, Getters and Togglers
]]
function SIL_Resil:GetTooltip() return self.db.global.tooltip; end
function SIL_Resil:GetTooltipZero() return self.db.global.tooltipZero; end
function SIL_Resil:GetPaperdoll() return self.db.global.paperdoll; end

function SIL_Resil:ToggleTooltip() if self:GetTooltip() then self:SetTooltip(0); else self:SetTooltip(1); end end
function SIL_Resil:ToggleTooltipZero() self:SetTooltipZero(not self:GetTooltipZero()); end
function SIL_Resil:TogglePaperdoll() self:SetPaperdoll(not self:GetPaperdoll()); end

function SIL_Resil:SetTooltip(v) self.db.global.tooltip = v; end
function SIL_Resil:SetTooltipZero(v) self.db.global.tooltipZero = v; end

function SIL_Resil:SetPaperdoll(v) 
    self.db.global.paperdoll = v; 
    
    if v then
		PAPERDOLL_STATINFO['SIL_Resil'] = { updateFunc = function(...) SIL_Resil:UpdatePaperDollFrame(...); end };
	else
		PAPERDOLL_STATINFO['SIL_Resil'] = nil;
	end
end

SILResil_Options = {
	name = 'SIL Social Options',
	desc = 'Options for SIL Social',
	type = "group",
	args = {
        cinfo = {
            name = 'Show on Character Info',
            desc = 'Shows your SIL '..RESILIENCE..' score on the stats pane.',
            type = "toggle",
            set = function(i,v) SIL_Resil:SetPaperdoll(v); end,
            get = function(i) return SIL_Resil:GetPaperdoll(); end,
            order = 1,
        },
        
        tooltip = {
            name = 'Tooltip Type',
            desc = nil,
            type = "select",
            values = {
                [0] = 'Off',
                [1] = '9/17 52.9%',
                [2] = '9/17',
                [3] = '52.9%',
            },
            set = function(i,v) SIL_Resil:SetTooltip(v); end,
            get = function() return SIL_Resil:GetTooltip(); end,
            order = 10,
        },
        tooltipZero = {
            name = 'Zero Tooltip',
            desc = 'Show the tooltip is they have no PvP gear.',
            type = "toggle",
            set = function(i,v) SIL_Resil:SetTooltipZero(v); end,
            get = function(i) return SIL_Resil:GetTooltipZero(); end,
            order = 11,
        },
    }
}

SILResil_Defaults = {
    global = {
        tooltip = 1;
        tooltipZero = false;
        paperdoll = true;
    },
};