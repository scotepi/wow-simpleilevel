-- Methods
SIL:PurgeCache(hours)
SIL:AddHook(hookType, callback) -- hookType = tooltip, callback(guid)
SIL:StartScore(target, callback)
SIL:AddTooltipText(textLeft, textRight, textAdvanced, textAdvancedRight) -- textLeft must always be the same
SIL:UpdateLDB(force) -- Uses proper channels to update text
SIL:UpdateLDBText(label, text) -- force text update (may be removed)

-- Data
name, realm = SIL:GUIDtoName(guid) 
guid = SIL:NameToGUID(name, realm)
UnitGUID = SIL:GetGUID(UnitID|UnitName|UnitGUID)
guid = SIL:AddPlayer(UnitID) -- Sets up SIL_CacheGUID information
score, age, items = SIL:GetScore(target, attemptUpdate) -- requires a target to attemptUpdate
score, age, items = SIL:GetScore(unitGUID)
bool = SIL:StartScore(UnitID, callback) -- callback(guid, score, items, age) or false
iLevel = SIL:Heirloom(level, itemLink) -- Can also get recomended AiL

-- Formating
string = SIL:FormatScore(score, itemCount, color); -- color = true
string = SIL:AgeToText(age, color) -- color = true
hex, r, g, b = SIL:ColorScore(score, items);

-- Misc
SIL:ColorTest(low, high)
SIL:PrintTo(message, channel, to) 

-- Cache Structure, old name ><
SIL_CacheGUID[guid] = {
    name = 'Scotepi',
    realm = 'Undermine',
    level = 85,
    class = 'HUNTER',
    target = 'player',
    guid = '0x05.....', -- I know its redundant
    score = false, -- 356.5
    items = false, -- 17
    time = false, -- 1323562432, translates to 12:13:52 am UTC Sunday, December 11, 2011, time() - time for age
};

-- Hooks
tooltipHook(guid);

-- Events
SIL_HAVE_SCORE
    guid, score, totalItems, age, items



