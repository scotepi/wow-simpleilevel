--[[
ToDo:
    - /sil pvp
]]

local L = LibStub("AceLocale-3.0"):GetLocale("SimpleILevel", true);
SIL_Resil = LibStub("AceAddon-3.0"):NewAddon('SIL_Resil', "AceEvent-3.0");

-- Add /sil pvp
if SIL_Group then
    SIL_Options.args.pvp = {
                name = L.group.options.group,
                desc = L.group.options.groupDesc,
                type = "input",
                guiHidden = true,
                set = function(i,v) dest, to = strsplit(' ', v, 2); SIL_Resil:GroupOutput(dest, to); end,
                get = function() return ''; end,
            };
end

function SIL_Resil:OnInitialize()
    SIL:Print(L.resil.load, GetAddOnMetadata("SimpleILevel_Resilience", "Version"));
    
    self.db = LibStub("AceDB-3.0"):New("SIL_ResilSettings", SILResil_Defaults, true);
    SIL.aceConfig:RegisterOptionsTable(L.resil.name, SILResil_Options, {"sir", "silr", "sip", "silp", "simpleilevelresilience", "simpleilevelpvp"});
    SIL.aceConfigDialog:AddToBlizOptions(L.resil.name, RESILIENCE, L.core.name);
    
    -- Hooks
    SIL:AddHook('tooltip', function(...) SIL_Resil:Tooltip(...); end);
    SIL:AddHook('inspect', function(...) SIL_Resil:Inspect(...); end);
    
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
	
	SIL.cache[guid].resil = rItems;
end

function SIL_Resil:Tooltip(guid)
    if guid and tonumber(guid) and self:GetTooltip() ~= 0 then
        local rItems = SIL:Cache(guid, 'resil') or 0;
        local items = SIL:Cache(guid, 'items');
        
        if (rItems and 0 < rItems and items) or (self:GetTooltipZero() and items) then
            local preferance = self:FormatScore(rItems, items, true)
            
            SIL:AddTooltipText(GUILD_PVP_STATUS..':', '|cFFFFFFFF'..preferance..'|r');
        end
    end
end

function SIL_Resil:GetItemCount(guid)
    if guid and tonumber(guid) and SIL:Cache(guid) and SIL:Cache(guid, 'resil') then
        local rItems = SIL:Cache(guid, 'resil');
        local items = SIL:Cache(guid, 'items');
        return rItems, items;
    else
        return false, false;
    end
end

function SIL_Resil:FormatScore(rItems, items, color)
    if not rItems or not tonumber(rItems) then rItems = 0 end
    if not items or not tonumber(items) then items = 1 end
    
    local hexColor = self:ColorScore(rItems / items, items)
    local percent = SIL:Round((rItems / items) * 100, 1);
    local slash = rItems..'/'..items;
    
    if color then
        percent = '|cFF'..hexColor..percent..'|r';
        slash = '|cFF'..hexColor..slash..'|r';
    end
    
    percent = percent..'%';
    
    -- User preferance
    local preferance = slash..' '..percent;
    if self:GetTooltip() == 2 then
        preferance = slash;
    elseif self:GetTooltip() == 3 then
        preferance = percent;
    end
    
    return preferance, percent, slash;
end

function SIL_Resil:ColorScore(percent, items)
	-- /run for i=1,17 do print(i,SIL_Resil:FormatScore(i,17,true)); end
    
    -- There are some missing items so gray
	if items and items <= SIL.grayScore then
		return SIL:RGBtoHex(0.5,0.5,0.5), 0.5,0.5,0.5;
    end
    
    return SIL:RGBtoHex(1 - percent, 1, 1 - percent);
end

function SIL_Resil:GroupOutput(dest, to)
    if not SIL_Group then return false; end
    
    local dest, to, color = SIL_Group:GroupDest(dest, to);
    SIL_Group:UpdateGroup(true);
    
    local totalResil = 0;
    local totalItems = 0;
    
    for _,guid in ipairs(SIL_Group.group) do
        local resil = SIL:Cache(guid, 'resil') or 0;
        local items = SIL:Cache(guid, 'items') or 1;
        
        if resil and resil > 0 then
            totalResil = resil + totalResil;
        end
        
        totalItems = items + totalItems;
    end
    
    local _, groupPercent =  self:FormatScore(totalResil, totalItems, color);
    SIL:PrintTo(format(L.group.outputHeader, groupPercent), dest, to);
    
    table.sort(SIL_Group.group, function(...) return SIL_Resil:SortScore(...); end);
    
    local rough = false;
    for _,guid in ipairs(SIL_Group.group) do
		local name = SIL:Cache(guid, 'name');
		local items = SIL:Cache(guid, 'items');
		local rItems = SIL:Cache(guid, 'resil') or 0;
		local score = SIL:Cache(guid, 'score');
        local class = SIL:Cache(guid, 'class');
        local str = '';
        
		if color then
            name = '|cFF'..SIL:RGBtoHex(RAID_CLASS_COLORS[class].r, RAID_CLASS_COLORS[class].g, RAID_CLASS_COLORS[class].b)..name..'|r';
        end
            
		if score and tonumber(score) and 0 < score then
            -- print(name, SIL:FormatScore(score, items, color), self:FormatScore(rItems, items, color));
            local preferance, percent, slash =  self:FormatScore(rItems, items, color);
            str = format('%s (%s) %s %s', name, SIL:FormatScore(score, items, color), percent, slash);
            
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

function SIL_Resil:SortScore(a,b)
    -- Get everything we need
    local scoreA = SIL:Cache(a, 'score') or 0;
    local scoreB = SIL:Cache(b, 'score') or 0;
    local resilA = SIL:Cache(a, 'resil') or 0;
    local resilB = SIL:Cache(b, 'resil') or 0;
    local itemsA = SIL:Cache(a, 'items') or 1;
    local itemsB = SIL:Cache(b, 'items') or 1;
    
    -- Do a little math
    local percentA = resilA / itemsA;
    local percentB = resilB / itemsB;
    
    -- If percents match then do score
    if percentA == percentB then
        return scoreA > scoreB;
    else
        return percentA > percentB;
    end
end

function SIL_Resil:UpdatePaperDollFrame(statFrame, unit)
    local guid = UnitGUID(unit);
    local rItems = SIL:Cache(guid, 'resil') or 0;
    local items = SIL:Cache(guid, 'items') or 0;
    local preferance, percent, slash = self:FormatScore(rItems, items, false);
    local rating = GetCombatRating(COMBAT_RATING_RESILIENCE_PLAYER_DAMAGE_TAKEN);
    
    PaperDollFrame_SetLabelAndText(statFrame, GUILD_PVP_STATUS, percent, false);
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