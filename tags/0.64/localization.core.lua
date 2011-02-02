-- Default localization - enUS
local addonName, L = ...;

L["Addon Description"] = "Adds the Average iLevel (AiL) to the tool tip of other players"
L["Addon Name"] = "Simple Item Level"
L["Addon Short Name"] = "SiL"
L["Age Days"] = "%age days"
L["Age Hours"] = "%age hours"
L["Age Minutes"] = "%age minutes"
L["Age Seconds"] = "%age seconds"
L["Help Advanced"] = "/sil advanced: toggles advanced tool tips inc. age"
L["Help Age"] = "/sil age <seconds>: Sets the amount of time between inspect refreshes"
L["Help Clear"] = "/sil clear: cleared all settings and the cache"
L["Help Get"] = "/sil get <name>: Gets the AiL of name if its cached"
L["Help Help"] = "/sil help: for this message"
L["Help Party"] = "/sil party: Shows the AiL of everyone in your party"
L["Help Raid"] = "/sil raid: Shows the AiL of everyone in your raid"
L["Help Target"] = "/sil target: Gets the AiL or your current target"
L["Loading Addon"] = "Loading v%version"
L["Party False"] = "Not in a party"
L["Party Member Score"] = "%name - AiL: %score %ageLocal old"
L["Party Member Score False"] = "%name - Out of range"
L["Party Score"] = "Party AiL: %score over %number members"
L["Raid False"] = "Not in a raid"
L["Raid Member Score"] = "%name - AiL: %score %ageLocal old"
L["Raid Member Score False"] = "%name - Out of range"
L["Raid Score"] = "Raid AiL: %score over %number members"
L["Slash Advanced Off"] = "Advanced tool tips Off"
L["Slash Advanced On"] = "Advanced tool tips On"
L["Slash Age Change"] = "Setting the Cache Age to %timeInSeconds"
L["Slash Clear"] = "Clearing settings"
L["Slash Get Score False"] = "Sorry, there was a error getting a score for %target"
L["Slash Get Score True"] = "%target has a AiL of %score with and the information is %ageLocal old"
L["Slash Target Score False"] = "Sorry, there was a error building a score for your target"
L["Slash Target Score True"] = "%target has a AiL of %score"
L["Tool Tip Left 1"] = "Average iLevel:"
L["Tool Tip Left 2"] = " "
L["Tool Tip Right 1"] = "%score"
L["Tool Tip Right 2"] = "%localizedAge old"
L["Your Score"] = "Your AiL is %score"



local function defaultFunc(L, key)
	--print('SiL: Missing localization for '..key);
	return key;
end
setmetatable(L, {__index=defaultFunc});
