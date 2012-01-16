--[[
ToDo:
    - Options to enable/disable specific channels, toggle coloring
]]
local L = LibStub("AceLocale-3.0"):GetLocale("SimpleILevel", true);
SIL_Soc = LibStub("AceAddon-3.0"):NewAddon('SIL_Soc', "AceEvent-3.0");
SIL_Soc.events = {
    'CHAT_MSG_PARTY',
    'CHAT_MSG_PARTY_LEADER',
    'CHAT_MSG_RAID',
    'CHAT_MSG_RAID_LEADER',
    'CHAT_MSG_GUILD',
    'CHAT_MSG_OFFICER',
    'CHAT_MSG_BATTLEGROUND',
    'CHAT_MSG_BATTLEGROUND_LEADER',
    'CHAT_MSG_CHANNEL',
    'CHAT_MSG_SAY',
    'CHAT_MSG_YELL',
}


function SIL_Soc:OnInitialize()
    SIL:Print("Social Module Loaded", GetAddOnMetadata("SimpleILevel_Social", "Version"));
    
    if not type(SIL_Social) == 'table' then SIL_Social = {}; end
    
    self:ChatHook();
end

function SIL_Soc:ChatHook()
	for _,event in pairs(self.events) do
		self:ChatHookEvent(event);
	end
end

function SIL_Soc:ChatUnhook()
	for _,event in pairs(self.events) do
		self:ChatUnhookEvent(event);
	end
end

function SIL_Soc:ChatHookEvent(event) ChatFrame_AddMessageEventFilter(event, SILSoc_ChatFilter); end
function SIL_Soc:ChatUnhookEvent(event) ChatFrame_RemoveMessageEventFilter(event, SILSoc_ChatFilter); end

function SIL_Soc:ChatFilter(s, event, msg, name,...)
	local score, age, items = SIL:GetScoreName(name);
	
	if score then
		local formated = SIL:FormatScore(score, items, self:GetColorScore());
		local newMsg = '('..formated..') '..msg;
		
		return false, newMsg, name, ...;
	else
		return false, msg, name, ...;
	end
end

-- Static version
SILSoc_ChatFilter = function(...) return SIL_Soc:ChatFilter(...); end;

function SIL_Soc:SetColorScore(v) return v; end
function SIL_Soc:GetColorScore() return true; end
function SIL_Soc:ToggleColorScore() self:SetColorScore(not self:GetColorScore()); end