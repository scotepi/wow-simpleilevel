--[[
ToDo:
    - /sil pvp
]]

local L = LibStub("AceLocale-3.0"):GetLocale("SimpleILevel", true);
SIL_Resil = LibStub("AceAddon-3.0"):NewAddon('SIL_Resil', "AceEvent-3.0");
SIL_Resil.cache = SIL_Resilience;

-- Add /sil pvp
if SIL_Group and false then
    SIL_Options.args.pvp = {
                name = GUILD_PVP_STATUS,
                desc = L.resil.options.pvpDesc,
                type = "input",
                hidden = true,
                guiHidden = true,
                cmdHidden = false,
                set = function(i,v) dest, to = strsplit(' ', v, 2); SIL_Resil:GroupOutput(dest, to); end,
                get = function() return ''; end,
            };
end

function SIL_Resil:OnInitialize()
    SIL:Print(L.resil.load, GetAddOnMetadata("SimpleILevel_Resilience", "Version"));
    
    if not self.cache or type(self.cache) ~= 'table' then self.cache = {}; end
    
    self.db = LibStub("AceDB-3.0"):New("SIL_ResilSettings", SILResil_Defaults, true);
    SIL.aceConfig:RegisterOptionsTable(L.resil.name, SILResil_Options, {"sir", "silr", "sip", "silp", "simpleilevelresilience", "simpleilevelpvp"});
    SIL.aceConfigDialog:AddToBlizOptions(L.resil.name, RESILIENCE, L.core.name);
    
    -- Hooks
    SIL:AddHook('tooltip', function(...) SIL_Resil:Tooltip(...); end);
    SIL:AddHook('inspect', function(...) SIL_Resil:Inspect(...); end);
    SIL:AddHook('purge', function(...) SIL_Resil:Purge(...); end);
    SIL:AddHook('clear', function(...) self.cache = {}; end);
    
    -- Paperdoll
    table.insert(PAPERDOLL_STATCATEGORIES["GENERAL"].stats, 'SIL_Resil');
	if self:GetPaperdoll() then
		PAPERDOLL_STATINFO['SIL_Resil'] = { updateFunc = function(...) SIL_Resil:UpdatePaperDollFrame(...); end };
	else
		PAPERDOLL_STATINFO['SIL_Resil'] = nil;
	end
    
    -- GuildMemberInfo
    if GMI then
        GMI:Register("SimpleILevel_Resilience", {
            lines = {
                    SIL_Resil = {
                        label = GUILD_PVP_STATUS,
                        default = 'n/a',
                        callback = function(name) return SIL_Resil:GMICallback(name); end,
                    },
                },
            }); 
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
	
	self.cache[guid] = rItems;
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
    self.cache[guid] = nil;
end

function SIL_Resil:GetItemCount(guid)
    if guid and tonumber(guid) and self.cache[guid] and SIL:Cache(guid) then
        local rItems = self.cache[guid];
        local items = SIL:Cache(guid, 'items');
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
    statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..L.resil.name..FONT_COLOR_CODE_CLOSE;
    
    if rItems then
        statFrame.tooltip2 = format(L.resil.ttPaperdoll, rItems, items, rating);
    else
        statFrame.tooltip2 = L.resil.PaperdollFalse;
    end
    
    statFrame:Show();
end

function SIL_Resil:GMICallback(name)
    local guid = SIL:NameToGUID(name);

    if guid and tonumber(guid) then
        local rItems, items = self:GetItemCount(guid);
        
        if rItems and items then
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
            
            return text;
        end
    end
    
    return 'n/a';
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
	name = L.resil.options.name,
	type = "group",
	args = {
        cinfo = {
            name = L.resil.options.cinfo,
            desc = L.resil.options.cinfoDesc,
            type = "toggle",
            set = function(i,v) SIL_Resil:SetPaperdoll(v); end,
            get = function(i) return SIL_Resil:GetPaperdoll(); end,
            order = 1,
        },
        
        tooltip = {
            name = L.resil.options.ttType,
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
            name = L.resil.options.ttZero,
            desc = L.resil.options.ttZeroDesc,
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