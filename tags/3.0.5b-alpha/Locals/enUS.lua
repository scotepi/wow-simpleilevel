-- Default localization - enUS
local L = LibStub("AceLocale-3.0"):NewLocale("SimpleILevel", "enUS", true);

L.core = {
	ageDays = "%s days",
	ageHours = "%s hours",
	ageMinutes = "%s minutes",
	ageSeconds = "%s seconds",
	desc = "Adds the Average iLevel (AiL) to the tool tip of other players",
	load = "Loading v%s",
	minimapClick = "Simple iLevel - Click for details",
	minimapClickDrag = "Click and drag to move the icon.",
	name = "Simple iLevel",
	purgeNotification = "Purging %s people from your cache",
	purgeNotificationFalse = "You do not have an auto purge set.",
	scoreDesc = "This is the Average iLevel of all of your equipped items.",
	scoreYour = "Your AiL is %s",
	slashClear = "Clearing settings",
	slashGetScore = "%s has a AiL of %s and the information is %s old",
	slashGetScoreFalse = "Sorry, there was a error getting a score for %s",
	slashTargetScore = "%s has an AiL of %s.",
	slashTargetScoreFalse = "Sorry, there was a error building a score for your target.",
	ttAdvanced = "%s old",
	ttLeft = "Average iLevel:",
	options = {
		autoscan = "Autoscan on Changes",
		autoscanDesc = "Automatically scan group members when there gear appears to change",
		clear = "Clear Settings",
		clearDesc = "Clear all settings and the cache",
		get = "Get Score",
		getDesc = "Gets the AiL of a name if it is cached.",
		ldb = "LDB Options",
		ldbRefresh = "Refresh Rate",
		ldbRefreshDesc = "How often should LDB be updated in seconds.",
		ldbSource = "Source Label",
		ldbSourceDesc = "Show a label of the source data for the LDB score.",
		ldbText = "LDB Text",
		ldbTextDesc = "Toggle LDB on and off, this will save a little resources.",
		maxAge = "Maximum Refresh Interval (Minutes)",
		maxAgeDesc = "Sets the amount of time between inspect refreshes in minutes",
		minimap = "Show Minimap Button",
		minimapDesc = "Toggles showing the minimap button",
		name = "Simple iLevel Options",
		open = "Open the SiL Options UI",
		options = "SiL Options",
		paperdoll = "Show on Character Info",
		paperdollDesc = "Shows your AiL on the Character Info window on the stats pane.",
		purge = "Purge Cache",
		purgeAuto = "Automatically Purge Cache",
		purgeAutoDesc = "Automatically purge the cache older then # days. 0 is never.",
		purgeDesc = "Clears all cached characters older then %s days",
		purgeError = "Please enter the number of days.",
		target = "Get Target Score",
		targetDesc = "Gets the AiL or your current target.",
		ttAdvanced = "Advanced Tooltip",
		ttAdvancedDesc = "Toggles advanced tooltips including the scores age",
		ttCombat = "Tooltip in Combat",
		ttCombatDesc = "Show the SiL information on the tooltip while in combat",
	},
}
L.group = {
	load = "Group Module Loaded",
	name = "SiL Group",
	nameShort = "Group",
	outputHeader = "Simple iLevel: Group average %s",
	outputNoScore = "%s is not available",
	outputRough = "* denotes an approximate score",
	options = {
		group = "Group Score",
		groupDesc = "Prints the score of your group to <%s>.",
	},
}
L.resil = {
	load = "Resilience Module Loaded",
	name = "SiL Resilience",
	nameShort = "Resilience",
	ttPaperdoll = "You have %s/%s items with a %s resilience rating.",
	ttPaperdollFalse = "You currently do not have any PvP items equiped.",
	options = {
		cinfo = "Show on Character Info",
		cinfoDesc = "Shows your SimpleiLevel Resilience score on the stats pane.",
		name = "SiL Resilience Options",
		pvpDesc = "Displayed the PvP gear of everyone in your group.",
		ttType = "Tooltip Type",
		ttZero = "Zero Tooltip",
		ttZeroDesc = "Shows information in the tooltip even if they have no PvP gear.",
	},
}
L.social = {
	load = "Social Module Loaded",
	name = "SiL Social",
	nameShort = "Social",
	options = {
		chatEvents = "Show Score On:",
		color = "Color Score",
		colorDesc = "Color the score in the chat windows.",
		enabled = "Enabled",
		enabledDesc = "Enable all features or SiL Social.",
		name = "SiL Social Options",
	},
}
