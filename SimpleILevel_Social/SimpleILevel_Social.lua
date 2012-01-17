--[[
ToDo:
    - 
]]
local L = LibStub("AceLocale-3.0"):GetLocale("SimpleILevel", true);
SIL_Soc = LibStub("AceAddon-3.0"):NewAddon('SIL_Soc', "AceEvent-3.0");
SIL_Soc.eventNames = {}; -- [event] = name;

function SIL_Soc:OnInitialize()
    SIL:Print("Social Module Loaded", GetAddOnMetadata("SimpleILevel_Social", "Version"));
    
    self.db = LibStub("AceDB-3.0"):New("SIL_Social", SILSoc_Defaults, true);
    SIL.aceConfig:RegisterOptionsTable("SimpleILevel_Social", SILSoc_Options, {"sis", "silsoc", "simpleilevelsocial"});
    SIL.aceConfigDialog:AddToBlizOptions("SimpleILevel_Social", "Social", L['Addon Name']);
    
    -- Build the event name table
    for event,enabled in pairs(self.db.global.chatEvents) do 
        self.eventNames[event] = _G[event];
    end
    
    self:ChatHook();
end

function SIL_Soc:ChatHook()
	for event,enabled in pairs(self.db.global.chatEvents) do
        if enabled and self:GetEnabled() then
            self:ChatHookEvent(event);
        end
	end
end

function SIL_Soc:ChatUnhook()
	for event,enabled in pairs(self.db.global.chatEvents) do
        if not enabled or not self:GetEnabled() then
            self:ChatUnhookEvent(event);
        end
	end
end

function SIL_Soc:ChatHookEvent(event) ChatFrame_AddMessageEventFilter(event, SILSoc_ChatFilter); end
function SIL_Soc:ChatUnhookEvent(event) ChatFrame_RemoveMessageEventFilter(event, SILSoc_ChatFilter); end

function SIL_Soc:ChatFilter(s, event, msg, name,...)
    if self:GetEnabled() then
        local score, age, items = SIL:GetScoreName(name);
        
        if score then
            local formated = SIL:FormatScore(score, items, self:GetColorScore());
            local newMsg = '('..formated..') '..msg;
            
            return false, newMsg, name, ...;
        else
            return false, msg, name, ...;
        end
    else
        self:ChatUnhook();
    end
end

-- Static version for chat hooks
SILSoc_ChatFilter = function(...) return SIL_Soc:ChatFilter(...); end;

--[[
    Setters, Getters and Togglers
]]
function SIL_Soc:SetColorScore(v) self.db.global.color = v; end

function SIL_Soc:GetColorScore() return self.db.global.color; end
function SIL_Soc:GetEnabled() return self.db.global.enabled; end
function SIL_Soc:GetChatEvent(e) return self.db.global.chatEvents[e]; end

function SIL_Soc:ToggleColorScore() self:SetColorScore(not self:GetColorScore()); end
function SIL_Soc:ToggleEnabled() self:SetEnabled(not self:GetEnabled()); end
function SIL_Soc:ToggleChatEvent(e) self:SetChatEvent(e, not self:GetChatEvent(e)); end

-- More advanced ones
function SIL_Soc:SetChatEvent(e, v) 
    self.db.global.chatEvents[e] = v; 
    
    if v then
        self:ChatHookEvent(e);
    else
        self:ChatUnhookEvent(e);
    end
end

function SIL_Soc:SetEnabled(v) 
    self.db.global.enabled = v;
    
    if v then
        self:ChatHook();
    else
        self:ChatUnhook();
    end
end

SILSoc_Options = {
	name = 'SIL Social Options',
	desc = 'Options for SIL Social',
	type = "group",
	args = {
        enabled = {
            name = 'Enabled',
            desc = 'Toggle all features of SIL Social.',
            type = "toggle",
            set = function(i,v) SIL_Soc:SetEnabled(v); end,
            get = function(i) return SIL_Soc:GetEnabled(); end,
            order = 1,
        },
        color = {
            name = 'Color Score',
            desc = 'Color the score in the chat messages.',
            type = "toggle",
            set = function(i,v) SIL_Soc:SetColorScore(v); end,
            get = function(i) return SIL_Soc:GetColorScore(); end,
            disabled = function() return not SIL_Soc:GetEnabled(); end,
            order = 5,
        },
        
        chatEvents = {
            name = 'Show Score On',
            desc = nil,
            type = 'multiselect',
            values = function() return SIL_Soc.eventNames; end;
            get = function(s,e) return SIL_Soc:GetChatEvent(e) end;
            set = function(s,e,v) return SIL_Soc:SetChatEvent(e, v) end;
            disabled = function() return not SIL_Soc:GetEnabled(); end,
            order = 100,
        },
    }
}

SILSoc_Defaults = {
    global = {
        enabled = true, -- Enabled the whole addon
        color = true,	-- Color the score in the chat frame
        chatEvents = {  -- Event and the status
            CHAT_MSG_PARTY                  = true,
            CHAT_MSG_PARTY_LEADER           = true,
            CHAT_MSG_RAID                   = true,
            CHAT_MSG_RAID_LEADER            = true,
            CHAT_MSG_GUILD                  = false,
            CHAT_MSG_OFFICER                = false,
            CHAT_MSG_BATTLEGROUND           = true,
            CHAT_MSG_BATTLEGROUND_LEADER    = true,
            CHAT_MSG_CHANNEL                = false,
            CHAT_MSG_SAY                    = true,
            CHAT_MSG_YELL                   = true,
            CHAT_MSG_WHISPER                = false,
        },
    },
};