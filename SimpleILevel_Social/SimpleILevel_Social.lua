--[[
ToDo:
    - Everything
    - Options
]]
local L = LibStub("AceLocale-3.0"):GetLocale("SimpleILevel", true);
SIL_Soc = LibStub("AceAddon-3.0"):NewAddon('SIL_Soc', "AceEvent-3.0");

function SIL_Soc:OnInitialize()
    SIL:Print("Social Module Loaded", GetAddOnMetadata("SimpleILevel_Social", "Version"));
    
    if not type(SIL_Social) == 'table' then SIL_Resilience = {}; end
    
    
end