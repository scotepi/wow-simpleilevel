--[[
ToDo:
    - Hide unnecicary options from the command line
]]
local L = LibStub("AceLocale-3.0"):GetLocale("SimpleILevel", true);

-- Coloring
SIL_ColorIndex = {0,200,333,378,390,416,1000};
SIL_Colors = {
	-- White base color
	[0] = 		{['r']=255,	['g']=255,	['b']=255,	['p']=0,},
	-- Yellow for wrath dungeon gear
	[200] = 	{['r']=255,	['g']=204,	['b']=0,	['p']=0,},
	-- Green for cata dungeon
	[333] = 	{['r']=0,	['g']=204,	['b']=0,	['p']=200,},
	-- Blue for heroic t11 final gear
	[378] = 	{['r']=0,	['g']=102,	['b']=204,	['p']=333,},
	-- Purple for t12
	[390] = 	{['r']=163,	['g']=23,	['b']=238,	['p']=378,},
	-- Red for a max score
	[416] = 	{['r']=255,	['g']=0,	['b']=0,	['p']=390},
	[1000] = 	{['r']=0,	['g']=0,	['b']=0,	['p']=416},
};

-- Suported channel localization table
SIL_Channels = {
    SYSTEM = string.lower(CHAT_MSG_SYSTEM),
    GROUP = string.lower(GROUP),
    PARTY = string.lower(CHAT_MSG_PARTY),
    RAID = string.lower(CHAT_MSG_RAID),
    GUILD = string.lower(CHAT_MSG_GUILD),
    SAY = string.lower(CHAT_MSG_SAY),
    BATTLEGROUND = string.lower(CHAT_MSG_BATTLEGROUND),
    OFFICER = string.lower(CHAT_MSG_OFFICER),
}
SIL_ChannelsString = '';
local i = 0;
for _,s in pairs(SIL_Channels) do
    if i == 0 then
        SIL_ChannelsString = s;
    else
        SIL_ChannelsString = SIL_ChannelsString..','..s;
    end
    i = i + 1;
end
L.group.options.groupDesc = format(L.group.options.groupDesc, SIL_ChannelsString);

-- Options for AceOptions
SIL_Options = {
	name = L.core.options.name,
	desc = L.core.desc,
	type = "group",
	args = {
		general = {
			name = L.core.options.options,
			type = "group",
			inline = true,
			order = 1,
			args = {
				advanced = {
					name = L.core.options.ttAdvanced,
					desc = L.core.options.ttAdvancedDesc,
					type = "toggle",
					set = function(i,v) SIL:SetAdvanced(v); end,
					get = function(i) return SIL:GetAdvanced(); end,
					order = 1,
				},
				autoscan = {
					name = L.core.options.autoscan,
					desc = L.core.options.autoscanDesc,
					type = "toggle",
					set = function(i,v) SIL:SetAutoscan(v); end,
					get = function(i) return SIL:GetAutoscan(); end,
					order = 2,
				},
				minimap = {
					name = L.core.options.minimap,
					desc = L.core.options.minimapDesc,
					type = "toggle",
					set = function(i,v) SIL:SetMinimap(v); end,
					get = function(i) return SIL:GetMinimap(); end,
					order = 3,
				},
				cinfo = {
					name = L.core.options.paperdoll,
					desc = L.core.options.paperdollDesc,
					type = "toggle",
					set = function(i,v) SIL:SetPaperdoll(v); end,
					get = function(i) return SIL:GetPaperdoll(); end,
					order = 3,
				},
				age = {
					name = L.core.options.maxAge,
					desc = L.core.options.maxAgeDesc,
					type = "range",
					min = 1,
					softMax = 240,
					step = 1,
					get = function(i) return (SIL:GetAge() / 60); end,
					set = function(i,v) v = tonumber(tonumber(v) * 60); SIL:SetAge(v); end,
					order = 20,
					width = "full",
				},
				
				autoPurge = {
					name = L.core.options.purgeAuto,
					desc = L.core.options.purgeAutoDesc,
					type = "range",
					min = 0,
					softMax = 30,
					step = 1,
					get = function(i) return (SIL:GetPurge() / 24); end,
					set = function(i,v) SIL:SetPurge(v * 24);  end,
					order = 21,
					width = "full",
				},
			},
		},
		
		
		ldbOpt = {
			name = L.core.options.ldb,
			type = "group",
			inline = true,
			order = 2,
			args = {
				ldbText = {
					name = L.core.options.ldbText,
					desc = L.core.options.ldbTextDesc,
					type = "toggle",
					get = function(i) return SIL:GetLDB(); end,
					set = function(i,v) SIL:SetLDB(v); end,
					order = 1,
				},
				ldbLabel = {
					name = L.core.options.ldbSource,
					desc = L.core.options.ldbSourceDesc,
					type = "toggle",
					get = function(i) return SIL:GetLDBlabel(); end,
					set = function(i,v) SIL:SetLDBlabel(v); end,
					order = 2,
				},
				ldbRefresh = {
					name = L.core.options.ldbRefresh,
					desc = L.core.options.ldbRefreshDesc,
					type = "range",
					min = 1,
					softMax = 300,
					step = 1,
					get = function(i) return SIL:GetLDBrefresh(); end,
					set = function(i,v) SIL:SetLDBrefresh(v); end,
					order = 20,
					width = "full",
				},
			},
		},
		
		
		
		
		
		purge = {
			name = L.core.options.purge,
			desc = L.core.options.purgeDesc,
			type = "execute",
			func = function(i) SIL:AutoPurge(false); end,
			confirm = true,
			order = 49,
		},
		clear = {
			name = L.core.options.clear,
			desc = L.core.options.clearDesc,
			type = "execute",
			func = function(i) SIL:SlashReset(); end,
			confirm = true,
			order = 50,
		},
		
		-- Console Only
		get = {
			name = L.core.options.get,
			desc = L.core.options.getDesc,
			type = "input",
			set = function(i,v) SIL:SlashGet(v); end,
			hidden = true,
			guiHidden = true,
			cmdHidden = false,
		},
		target = {
			name = L.core.options.target,
			desc = L.core.options.targetDesc,
			type = "input",
			set = function(i) SIL:SlashTarget(); end,
			hidden = true,
			guiHidden = true,
			cmdHidden = false,
		},
		options = {
			name = L.core.options.options,
			desc = L.core.options.open,
			type = "input",
			set = function(i) SIL:ShowOptions(); end,
			hidden = true,
			guiHidden = true,
			cmdHidden = false,
		},
		
        debug = {
			name = 'Debug Mode',
			type = "toggle",
			set = function(i,v) SIL.debug = v; SIL:Print('Setting Dubug', v); end,
            get = function() return SIL.debug; end,
			hidden = true,
			guiHidden = true,
			cmdHidden = true,
		},
	},
};

SIL_Defaults = {
	global = {
		age = 1800,				-- How long till information is refreshed
		purge = 360,				-- How often to automaticly purge
		advanced = false,		-- Display extra information in the tooltips
		autoscan = true,		-- Automaticly scan for changes
		cinfo = true,			-- Character Info/Paperdoll info
		minimap = {
			hide = false,		-- Minimap Icon
		},
		version = 1,			-- Version for future referance
--		versionMinor = 1,
		ldbText = true,			-- LDB Text
		ldbLabel = true,		-- LDB Label
		ldbRefresh = 30,		-- LDB Refresh Rate
        ttCombat = true;        -- Tooltip in combat
	},
};

-- From http://www.wowhead.com/items?filter=qu=7;sl=16:18:5:8:11:10:1:23:7:21:2:22:13:24:15:28:14:4:3:19:25:12:17:6:9;minle=1;maxle=1;cr=166;crs=3;crv=0
SIL_Heirlooms = {
	[80] = {44102,42944,44096,42943,42950,48677,42946,42948,42947,42992,50255,44103,44107,44095,44098,44097,44105,42951,48683,48685,42949,48687,42984,44100,44101,44092,48718,44091,42952,48689,44099,42991,42985,48691,44094,44093,42945,48716},
};