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
	-- Purple for t11 on
	[390] = 	{['r']=163,	['g']=23,	['b']=238,	['p']=378,},
	-- Red for a max score
	[1000] = 	{['r']=255,	['g']=0,	['b']=0,	['p']=390},
};

-- Options for AceOptions
SIL_Options = {
	name = L['Help Options'],
	type = "group",
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
		
		party = {
			name = L['Help Party'],
			desc = L['Help Party Desc'],
			type = "execute",
			hidden = true,
			guiHidden = true,
			func = function(i) SIL:Party(true); end
		},
		raid = {
			name = L['Help Raid'],
			desc = L['Help Raid Desc'],
			type = "execute",
			hidden = true,
			guiHidden = true,
			func = function(i) SIL:Raid(true); end
		},
		
		-- Console Only
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
		
	},
};

SIL_Defaults = {
	global = {
		age = 1800,				-- How long till information is refreshed
		purge = 0,				-- How often to automaticly purge
		advanced = false,		-- Display extra information in the tooltips
		autoscan = true,		-- Automaticly scan for changes
		minimap = {
			hide = false,		-- Minimap Icon
		},
		version = 1,			-- Version for future referance
		versionMinor = 1,
	},
};
