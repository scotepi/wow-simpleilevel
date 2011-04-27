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
			get = function(i) return SIL_Settings['advanced']; end,
			order = 1,
		},
		autoscan = {
			name = L['Help Autoscan'],
			desc = L['Help Autoscan Desc'],
			type = "toggle",
			set = function(i,v) SIL:SetAutoscan(v); end,
			get = function(i) return SIL_Settings['autoscan']; end,
			order = 2,
		},
		minimap = {
			name = L['Help Minimap'],
			desc = L['Help Minimap Desc'],
			type = "toggle",
			set = function(i,v) SIL:SetMinimap(v); end,
			get = function(i) return not SIL_Settings['minimap']['hide']; end,
			order = 3,
		},
		
		age = {
			name = L['Help Age'],
			desc = L['Help Age Desc'],
			type = "range",
			min = 1,
			softMax = 240,
			step = 1,
			get = function(i) return (SIL_Settings['age'] / 60); end,
			set = function(i,v) SIL_Settings['age'] = tonumber(tonumber(v) * 60);  end,
			order = 20,
			width = "full",
		},
		
		clear = {
			name = L['Help Clear'],
			desc = L['Help Clear Desc'],
			type = "execute",
			func = function(i) SIL:Reset(); end,
			confirm = true,
			order = 50,
			width = "full",
		},
		
		purge = {
			name = L['Help Purge'],
			desc = L['Help Purge Desc'],
			type = "input",
			validate = function(i,v) 
				if not (tonumber(v)) then 
					SIL:Print(L['Help Purge Error']); return L['Help Purge Error'];
				else 
					local count = SIL:PurgeCache(number); 
						if not count then count = 0; end 
					SIL:Print(SIL:Replace(L['Purge Notification'], 'num', count));
				end; end,
			order = 49,
			width = "full",
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