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

--[[
    There must be a 0 and 1000


    Updated from https://www.wowhead.com/news=319344/how-to-gear-in-the-first-two-week-of-shadowlands-rewards-and-item-level
]]--

SIL_Colors = {
	-- White base color
	[0] =       'FFFFFF',
	-- Yellow, end of BfA epic gear
	[100] =     'FFFF00',
	-- Green, Normal dungeon gear
	[158] =     '00FF00',
	-- Teal, Legendary rank 2
    [235] =     '00FFFF',
    
	-- Blue, TBD Legendary rank, may get tweeked
	[312] =     '0066ff',
	-- Purple, TBD Legendary rank
	[389] =     'FF00FF',
	-- Red for a max score
	[1000] =    'FF0000',
};

-- Build the index
SIL_ColorIndex = {}
local i = 1
for scoreStep,_ in pairs(SIL_Colors) do
    SIL_ColorIndex[i] = scoreStep
    
    i = i + 1
end

-- Sort the index
table.sort(SIL_ColorIndex)
