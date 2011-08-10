-- Option Tables
local L = LibStub("AceLocale-3.0"):GetLocale("SimpleILevel", true);

-- Coloring
SIL_ColorIndex = {0,200,333,378,390,1000};
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
	[1000] = 	{['r']=255,	['g']=0,	['b']=0,	['p']=390},
};

-- Suported channel localization table
SIL_Channels = {};
SIL_Channels['SYSTEM'] = string.lower(CHAT_MSG_SYSTEM);
SIL_Channels['GROUP'] = string.lower(GROUP);
SIL_Channels['PARTY'] = string.lower(CHAT_MSG_PARTY);
SIL_Channels['RAID'] = string.lower(CHAT_MSG_RAID);
SIL_Channels['GUILD'] = string.lower(CHAT_MSG_GUILD);
SIL_Channels['SAY'] = string.lower(CHAT_MSG_SAY);
SIL_Channels['BATTLEGROUND'] = string.lower(CHAT_MSG_BATTLEGROUND);
SIL_Channels['OFFICER'] = string.lower(CHAT_MSG_OFFICER);
SIL_ChannelsString = 'system,group,party,raid,guild,say,battleground,officer';
L['Help Group Desc'] = string.gsub(L['Help Group Desc'], '%%local', SIL_ChannelsString);

-- Options for AceOptions
SIL_Options = {
	name = L['Help Options'],
	desc = L['Addon Description'],
	type = "group",
	args = {
		general = {
			name = L['Help General'],
			type = "group",
			inline = true,
			order = 1,
			args = {
					advanced = {
					name = L['Help Advanced'],
					desc = L['Help Advanced Desc'],
					type = "toggle",
					set = function(i,v) SIL:SetAdvanced(v); end,
					get = function(i) return SIL:GetAdvanced(); end,
					order = 1,
				},
				autoscan = {
					name = L['Help Autoscan'],
					desc = L['Help Autoscan Desc'],
					type = "toggle",
					set = function(i,v) SIL:SetAutoscan(v); end,
					get = function(i) return SIL:GetAutoscan(); end,
					order = 2,
				},
				minimap = {
					name = L['Help Minimap'],
					desc = L['Help Minimap Desc'],
					type = "toggle",
					set = function(i,v) SIL:SetMinimap(v); end,
					get = function(i) return SIL:GetMinimap(); end,
					order = 3,
				},
				cinfo = {
					name = L['Help Paperdoll'],
					desc = L['Help Paperdoll Desc'],
					type = "toggle",
					set = function(i,v) SIL:SetPaperdoll(v); end,
					get = function(i) return SIL:GetPaperdoll(); end,
					order = 3,
				},
				age = {
					name = L['Help Age'],
					desc = L['Help Age Desc'],
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
					name = L['Help Purge Auto'],
					desc = L['Help Purge Auto Desc'],
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
			name = L['Help LDB'],
			type = "group",
			inline = true,
			order = 2,
			args = {
				ldbText = {
					name = L['Help LDB Text'],
					desc = L['Help LDB Text Desc'],
					type = "toggle",
					get = function(i) return SIL:GetLDB(); end,
					set = function(i,v) SIL:SetLDB(v); end,
					order = 1,
				},
				ldbLabel = {
					name = L['Help LDB Source'],
					desc = L['Help LDB Source Desc'],
					type = "toggle",
					get = function(i) return SIL:GetLDBlabel(); end,
					set = function(i,v) SIL:SetLDBlabel(v); end,
					order = 2,
				},
				ldbRefresh = {
					name = L['Help LDB Refresh'],
					desc = L['Help LDB Refresh Desc'],
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
			name = L['Help Purge'],
			desc = L['Help Purge Desc'],
			type = "execute",
			func = function(i) SIL:AutoPurge(false); end,
			confirm = true,
			order = 49,
		},
		clear = {
			name = L['Help Clear'],
			desc = L['Help Clear Desc'],
			type = "execute",
			func = function(i) SIL:Reset(); end,
			confirm = true,
			order = 50,
		},
		
		-- Console Only
		party = {
			name = L['Help Group'],
			desc = L['Help Group Desc'],
			type = "input",
			hidden = true,
			set = function(i,v) SIL:GroupOutput(v); end,
			get = function() return ''; end,
		},
		raid = {
			name = L['Help Group'],
			desc = L['Help Group Desc'],
			type = "input",
			hidden = true,
			set = function(i,v) SIL:GroupOutput(v); end,
			get = function() return ''; end,
		},
		group = {
			name = L['Help Group'],
			desc = L['Help Group Desc'],
			type = "input",
			hidden = true,
			guiHidden = true,
			cmdHidden = false,
			set = function(i,v) dest, to = strsplit(' ', v, 2); SIL:GroupOutput(dest, to); end,
			get = function() return ''; end,
		},
		get = {
			name = L['Help Get'],
			desc = L['Help Get Desc'],
			type = "input",
			set = function(i,v) SIL:ForceGet(v); end,
			hidden = true,
			guiHidden = true,
			cmdHidden = false,
		},
		target = {
			name = L['Help Target'],
			desc = L['Help Target Desc'],
			type = "input",
			set = function(i) SIL:ForceGet(); end,
			hidden = true,
			guiHidden = true,
			cmdHidden = false,
		},
		options = {
			name = L['Help Options'],
			desc = L['Help Options Desc'],
			type = "input",
			set = function(i) SIL:ShowOptions(); end,
			hidden = true,
			guiHidden = true,
			cmdHidden = false,
		},
		
	},
};

SIL_Defaults = {
	global = {
		age = 1800,				-- How long till information is refreshed
		purge = 0,				-- How often to automaticly purge
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
	},
};

-- From http://www.wowhead.com/items?filter=qu=7;sl=16:18:5:8:11:10:1:23:7:21:2:22:13:24:15:28:14:4:3:19:25:12:17:6:9;minle=1;maxle=1;cr=166;crs=3;crv=0
SIL_Heirlooms = {
	[80] = {44102,42944,44096,42943,42950,48677,42946,42948,42947,42992,50255,44103,44107,44095,44098,44097,44105,42951,48683,48685,42949,48687,42984,44100,44101,44092,48718,44091,42952,48689,44099,42991,42985,48691,44094,44093,42945,48716},
};
