--[[
ToDo:
    - 
]]

--[[
    MoP Colors:
        White 0, #FFFFFF, 255, 255, 255
        Yellow 463, #FFFF00, 255, 255, 0
        Green 463, #00FF00, 0, 255, 0
        Teal 518, #00FFFF, 0, 255, 255
        Blue H T17, #0066ff, 0, 102, 255 - Raw Blue was to dark
        Purple H T18, #FF00FF, 255, 0, 255
        Red H T19, #FF0000, 255, 0, 0
]]--

-- This should bump the day the expantion goes live
-- local expansionID = GetExpansionLevel();

SIL_ColorIndex = {0,30,58,100,130,145,1000};
SIL_Colors = {
	-- White base color
	[0] =       {['r']=255,     ['g']=255,      ['b']=255,      ['rgb']='FFFFFF',   ['p']=0,},
	-- Yellow, Level 25, old Level 60
	[30] =     {['r']=255,     ['g']=255,      ['b']=0,        ['rgb']='FFFF00',   ['p']=0,},
	-- Green, Level 50, old Level 120
	[58] =     {['r']=0,       ['g']=255,      ['b']=0,        ['rgb']='00FF00',   ['p']=30,},
	-- Teal, Level 50 full epic, used to be 445
	[100] =     {['r']=0,       ['g']=255,      ['b']=255,      ['rgb']='00FFFF',   ['p']=58,},
	-- Blue, Was 475 ish
	[130] =     {['r']=0,       ['g']=102,      ['b']=255,      ['rgb']='0066ff',   ['p']=100,},
	-- Purple, was 510 ish
	[145] =     {['r']=255,     ['g']=0,        ['b']=255,      ['rgb']='FF00FF',   ['p']=130,},
	-- Red for a max score
	[1000] =    {['r']=255,     ['g']=0,        ['b']=0,        ['rgb']='FF0000',   ['p']=145,},
};