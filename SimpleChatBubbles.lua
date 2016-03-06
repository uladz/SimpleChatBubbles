-- Simple Chat Bubbles - By Dio Revived by RibbedStoic  (v1.0.4) -
-- http://www.esoui.com/downloads/author-1518.html

local SCB = {
	name = "SimpleChatBubbles",
	title = "SCB - Revived",
	dbVersion = 1,
	channelNames = {
		"MONSTER_EMOTE",
		"MONSTER_SAY",
		"MONSTER_WHISPER",
		"MONSTER_YELL",
		"EMOTE",
		"SAY",
		"YELL",
		"ZONE",
		"PARTY",
		"GUILD_1",
		"GUILD_2",
		"GUILD_3",
		"GUILD_4",
		"GUILD_5",
		"OFFICER_1",
		"OFFICER_2",
		"OFFICER_3",
		"OFFICER_4",
		"OFFICER_5"
	},
	otherChannels = {
		{
			name = "WHISPER",
			channelId = CHAT_CHANNEL_WHISPER,
			categoryId = CHAT_CATEGORY_WHISPER_INCOMING
		},
		{
			name = "ZONE (ENGLISH)",
			channelId = CHAT_CHANNEL_ZONE_LANGUAGE_1,
			categoryId = CHAT_CATEGORY_ZONE_ENGLISH
		},
		{
			name = "ZONE (FRENCH)",
			channelId = CHAT_CHANNEL_ZONE_LANGUAGE_2,
			categoryId = CHAT_CATEGORY_ZONE_FRENCH
		},
		{
			name = "ZONE (GERMAN)",
			channelId = CHAT_CHANNEL_ZONE_LANGUAGE_3,
			categoryId = CHAT_CATEGORY_ZONE_GERMAN
		}
	},
	spamFilters = {
		-- Straight up no http(s) or wwws:

		"https?",
		"www%.",

		-- The following patterns were copied from SpamFilter:
		-- http://www.esoui.com/downloads/info89-SpamFilter.html

		"%s*[vw]+%.%w-g[o0][l1]d%w*%.c[o0]m%s*",
		"g[o0][l1]dah%.c[o0]m",
		"g[o0][l1]dce[o0]%.c[o0]m",
		"tesg[o0][l1]dma[l1][l1]",
		"currency[o0]ffer",

		-- The following patterns were copied from BadGoldSpammer:
		-- http://www.esoui.com/downloads/info95-BadGoldSpammer.html

		"[wWV]+%.%w*[gG][oO0][lL1][dD]%w*%.[cC][oO0][mM]"
	}
}

local AM = GetAnimationManager()
local LMP = LibStub:GetLibrary("LibMediaProvider-1.0")
local UTF8 = GetUTF8()

function SCB:Init()
	local defaults = {
		opacity = .85,
		noCombat = false,
		hideOnMenu = true,
		animatePop = true,
		showCharacterName = false,
		maxBubbles = 6,
		headerFont = "Trajan Pro",
		bodyFont = "ESO Cartographer",
		maxDuration = 7000,
		showMyChat = false,
		minDuration = 3000,
		playerNameFontSize = 23,
		bodyFontSize = 14,
		showBackdrop = false,
		showTextShadow = true,
		overrideBodyColor = false,
		headerColor = {
			r = 0.93,
			g = 0.92,
			b = 0.74
		},
		bodyColor = {
			r = 1,
			g = 1,
			b = 1
		},
		channels = {
			[CHAT_CHANNEL_EMOTE] = true,
			[CHAT_CHANNEL_SAY] = true,
			[CHAT_CHANNEL_YELL] = true,
			[CHAT_CHANNEL_WHISPER] = true
		}
	}

	self.db = ZO_SavedVars:New("SCB_DB", self.dbVersion, nil, defaults)

	self:GetChannels()
	self:MakeControls()
	self:MakeConfig()
	self:GetCharacterNames()

	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_CHAT_MESSAGE_CHANNEL, function(_, type, from, text)
		self:ParseChat(type, from, text)
	end)

	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_SCREEN_RESIZED, function()
		self:AnchorTLW()
	end)

	if self.db.noCombat then
		self:RegisterCombat()
	end

	if self.db.hideOnMenu then
		ZO_PreHookHandler(ZO_MainMenuCategoryBar, "OnShow", function()
			self:ToggleBubbles(true)
		end)

		ZO_PreHookHandler(ZO_MainMenuCategoryBar, "OnHide", function()
			self:ToggleBubbles(false)
		end)
	end
end

function SCB:RegisterCombat()
	EVENT_MANAGER:RegisterForEvent(self.name, EVENT_PLAYER_COMBAT_STATE, function()
		self:HideBubblesInCombat()
	end)
end

function SCB:UnregisterCombat()
	EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_PLAYER_COMBAT_STATE)
end

function SCB:HideBubblesInCombat()
	if IsUnitInCombat("player") then
		self:ToggleBubbles()
	end
end

function SCB:ToggleBubbles(hide)
	for _, bubble in ipairs(self.controls.bubbles) do
		if hide == nil and bubble.control:IsAnimating() then
			bubble.control:AnimateStop()
		else
			bubble.control:SetHidden(hide)
		end
	end
end

function SCB:GetCharacterNames()
	self.characterNames = {}

	for x = 1, GetNumGuilds() do
		for y = 1, GetNumGuildMembers(1) do
			local accountName = GetGuildMemberInfo(x, y)
			local hasCharacter, characterName = GetGuildMemberCharacterInfo(x, y)

			if hasCharacter and characterName then
				self.characterNames[self:CleanName(accountName)] = self:CleanName(characterName)
			end
		end
	end
end

function SCB:GetChannels()
	self.channels = {}
	self.sortedChannels = {}

	for _, channelName in ipairs(self.channelNames) do
		local channelId = GetChatChannelId(channelName)

		self.channels[channelId] = {
			id = channelId,
			name = channelName:gsub("_", " "),
			color = {GetChatCategoryColor(_G["CHAT_CATEGORY_" .. channelName])}
		}

		table.insert(self.sortedChannels, self.channels[channelId])
	end

	for _, channel in pairs(self.otherChannels) do
		self.channels[channel.channelId] = {
			id = channel.channelId,
			name = channel.name,
			color = {GetChatCategoryColor(channel.categoryId)}
		}

		table.insert(self.sortedChannels, self.channels[channel.channelId])
	end

	table.sort(self.sortedChannels, function(a, b)
		return a.name < b.name
	end)
end

function SCB:IsSpam(text)
	for _, filter in ipairs(self.spamFilters) do
		if text:lower():find(filter) then
			return true
		end
	end
end

function SCB:CleanName(name)
	return name:gsub("%^.+", ""):gsub("Mx$", "")
end

function SCB:ParseChat(type, from, text)
	from = self:CleanName(from)
	local guildCharName = self.characterNames[from]

	if self.db.showCharacterName and guildCharName then
		from = guildCharName
	end

	local unitName = GetUnitName("player")

	if not self.db.channels[type]
		or self:IsSpam(text)
		or not self.channels[type]
		or (
			self.db.noCombat
			and IsUnitInCombat("player")
		) or (
			not self.db.showMyChat
			and (
				from == unitName
				or guildCharName == unitName
			)
		)
	then
		return
	end

	self:ShowChat(from, text, self.channels[type].color)
end

function SCB:ShowChat(from, text, color)
	local newBubble = nil

	for i = 1, self.db.maxBubbles do
		local bubble = self.controls.bubbles[i]

		if not bubble.control:IsAnimating() then
			newBubble = bubble
			break
		end

		if not newBubble or bubble.control:GetProgress() > newBubble.control:GetProgress() then
			newBubble = bubble
		end
	end

	local duration = self.db.minDuration + (UTF8.len(text) * 30)

	if duration > self.db.maxDuration then
		duration = self.db.maxDuration
	end

	local animateBubble = function()
		newBubble.labelPlayer:SetText(from)
		newBubble.labelChat:SetText(text)
		if self.db.overrideBodyColor == false then
			newBubble.labelChat:SetColor(unpack(color))
		end
		local bgWidth = newBubble.labelChat:GetTextWidth()
		if newBubble.labelPlayer:GetTextWidth() > newBubble.labelChat:GetTextWidth() then bgWidth = newBubble.labelPlayer:GetTextWidth() end
		newBubble.bg:SetDimensions(bgWidth + 50, (newBubble.labelPlayer:GetTextHeight() + newBubble.labelChat:GetTextHeight()) + 30)
		newBubble.control:Animate(duration)
		
	end

	if newBubble.control:IsAnimating() then
		newBubble.control:AnimateStop(animateBubble)
	else
		animateBubble()
	end
end

function SCB:MakeConfig()
	local panel = {
		type = "panel", 
		name = self.title,
		registerForRefresh = true
	}
	local LAM2 = LibStub("LibAddonMenu-2.0")
	LAM2:RegisterAddonPanel(self.title, panel)
	
	local generalOptions = {
		[1] = {
			type = "header",
			name = "General"
		},
		[2] = {
		  type = "checkbox",
		  name = "Show My Chat",
		  tooltip = "Your chat will show as a bubble.",
		  width = "half",
		  getFunc = function() return self.db.showMyChat end,
		  setFunc = function(value) self.db.showMyChat = value end
		},
		[3] = {
			type = "checkbox",
			name = "Show Character Name",
			width = "half",
			tooltip = "When available, show character names instead of account name. This only works if the character is in one of your guilds.",
			getFunc = function() return self.db.showCharacterName end,
			setFunc = function(value) self.db.showCharacterName = value end
		},
		[4] = {
			type = "checkbox",
			name = "Not in Combat",
			width = "half",
			tooltip = "Hide bubbles upon combat, and prevent new bubbled until out of combat.",
			getFunc = function() return self.db.noCombat end,
			setFunc = function(value) self.db.noCombat = value end
		},
		[5] = {
			type = "checkbox",
			name = "Hide on Menus",
			width = "half",
			tooltip = "Hide bubbles while any character menu is open. Does not apply to system menus.",
			getFunc = function() return self.db.hideOnMenu end,
			setFunc = function(value) self.db.hideOnMenu = value end,
			warning = "Requires reloading the UI."
		},
		[6] = {
			type = "checkbox",
			name = "Show Pop Animation",
			width = "half",
			tooltip = "Bubbles will be more obvious.",
			getFunc = function() return self.db.animatePop end,
			setFunc = function(value) self.db.animatePop = value end,
			warning = "Requires reloading the UI."
		},
		[7] = {
			type = "checkbox",
			name = "Show Background",
			width = "half",
			tooltip = "Show a black background behind text",
			getFunc = function() return self.db.showBackdrop end,
			setFunc = function(value) self.db.showBackdrop = value end,
			warning = "Requires reloading the UI."
		},
		[8] = {
			type = "checkbox",
			name = "Show Text Shadow",
			width = "half",
			tooltip = "Adds a text shadow to make text easier to see",
			getFunc = function() return self.db.showTextShadow end,
			setFunc = function(value) self.db.showTextShadow = value end,
			warning = "Requires reloading the UI."
		},
		[9] = {
			type = "dropdown",
			name = "Player Name Font",
			width = "half",
			tooltip = "Text font for the player name",
			choices = LMP:List('font'),
			getFunc = function() return self.db.headerFont end,
			setFunc = function(value) self.db.headerFont = value end,
			warning = "Requires reloading the UI."
		},
		[10] = {
			type = "dropdown",
			name = "Body Font",
			width = "half",
			tooltip = "Bubble text body font",
			choices = LMP:List('font'),
			getFunc = function() return self.db.bodyFont end,
			setFunc = function(value) self.db.bodyFont = value end,
			warning = "Requires reloading the UI."
		},
		[11] = {
			type = "colorpicker",
			name = "Player Name Font Color",
			width = "half",
			tooltip = "Color of the player name",
			getFunc = function() 
				return self.db.headerColor.r, self.db.headerColor.g, self.db.headerColor.b 
			end,
			setFunc = function(r, g, b)
				self.db.headerColor.r = r
				self.db.headerColor.g = g
				self.db.headerColor.b = b
			end,
			warning = "Requires reloading the UI."
		},
		[12] = {
			type = "checkbox",
			name = "Override Default Body Color",
			width = "half",
			getFunc = function() return self.db.overrideBodyColor end,
			setFunc = function(value) self.db.overrideBodyColor = value end
			
		},
		[13] = {
			type = "colorpicker",
			name = "Body Font Color",
			width = "half",
			tooltip = "Color of the body",
			getFunc = function() 
				return self.db.bodyColor.r, self.db.bodyColor.g, self.db.bodyColor.b 
			end,
			setFunc = function(r, g, b)
				self.db.bodyColor.r = r
				self.db.bodyColor.g = g
				self.db.bodyColor.b = b
			end,
			disabled = function() 
				if self.db.overrideBodyColor then
					return false
				else
					return true
				end
			end,
			warning = "Requires reloading the UI."
		},
		[14] = {
			type = "slider",
			name = "Player Name Font Size",
			width = "half",
			min = 5,
			max = 30,
			step = 1,
			getFunc = function() return self.db.playerNameFontSize end,
			setFunc = function(value) self.db.playerNameFontSize = value end,
			warning = "Requires reloading the UI."
		},
		[15] = {
			type = "slider",
			name = "Body Text Font Size",
			width = "half",
			min = 1,
			max = 20,
			step = 1,
			getFunc = function() return self.db.bodyFontSize end,
			setFunc = function(value) self.db.bodyFontSize = value end,
			warning = "Requires reloading the UI."
		},
		[16] = {
			type = "slider",
			name = "Opacity",
			tooltip = "Set the opacity of the bubbles.",
			width = "half",
			min = 50,
			max = 100,
			step = 5,
			getFunc = function() return self.db.opacity * 100 end,
			setFunc = function(value) self.db.opacity = value / 100 end
		},
		[17] = {
			type = "slider",
			name = "Max Bubbles",
			tooltip = "More bubbles means less chance of chat overwriting.",
			width = "half",
			min = 1,
			max = 6,
			step = 1,
			getFunc = function() return self.db.maxBubbles end,
			setFunc = function(value) self.db.maxBubbles = value end
		},	
		[18] = {
			type = "slider",
			name = "Max Duration (Seconds)",
			width = "half",
			tooltip = "The maximum seconds a bubble will stay unless overwritten. Bubble duration depends on the length of the full message.",
			min = 5,
			max = 12,
			step = 1,
			getFunc = function() return self.db.maxDuration / 1000 end,
			setFunc = function(value) self.db.maxDuration = value * 1000 end
		},	
		[19] = {
			type = "slider",
			name = "Min Duration (Seconds))",
			width = "half",
			tooltip = "The minimum seconds a bubble will stay on screen",
			min = 5,
			max = 12,
			step = 1,
			getFunc = function() return self.db.minDuration / 1000 end,
			setFunc = function(value) self.db.minDuration = value * 1000 end
		},
		[20] = {
			type = "description",
			text = "\nMake sure to reload the ui if applicable!\n"
		},
		[21] = {
			type = "button",
			name = "Reload UI",
			tooltip = "Reloads the UI",
			func = function() ReloadUI() end
		},
		[22] = {
			type = "header",
			name = "Channels\n"
		}
	}
	for _, channel in ipairs(self.sortedChannels) do
			local newChannel = {
				type = "checkbox",
				name = channel.name,
				getFunc = function() return self.db.channels[channel.id] end,
				setFunc = function(value) self.db.channels[channel.id] = value end
			}
			table.insert(generalOptions, newChannel)
	end
	
	LAM2:RegisterOptionControls(self.title, generalOptions)
end

function SCB:AnimateBubble(bubble, duration)
	local timeline = AM:CreateTimeline()

	timeline.fadeIn = timeline:InsertAnimation(ANIMATION_ALPHA, bubble)
	timeline.fadeIn:SetDuration(duration)

	if self.db.animatePop then
		timeline.scaleOut = timeline:InsertAnimation(ANIMATION_SCALE, bubble)
		timeline.scaleOut:SetDuration(duration)

		timeline.scaleIn = timeline:InsertAnimation(ANIMATION_SCALE, bubble, duration)
		timeline.scaleIn:SetDuration(duration / 2)
	end

	timeline.fadeOut = timeline:InsertAnimation(ANIMATION_ALPHA, bubble)
	timeline.fadeOut:SetDuration(duration)

	return timeline
end

function SCB:AnchorTLW()
	self.controls.tlw:ClearAnchors()
	self.controls.tlw:SetAnchor(CENTER, GuiRoot, TOP, 0, GuiRoot:GetHeight() / 4)
end

function SCB:MakeControls()
	local WM = GetWindowManager()
	local maxVertical, bubbleHeight, labelVertical = 125, 300, -5

	local bubbles = {
		{0, -15},
		{-350, -15},
		{350, -15},
		{-350, maxVertical},
		{350, maxVertical},
		{0, maxVertical}
	}

	self.controls = {
		bubbles = {}
	}

	self.controls.tlw = WM:CreateTopLevelWindow(self.name)
	self.controls.tlw:SetDrawLayer(DL_BACKGROUND)
	self.controls.tlw:SetDrawTier(DT_LOW)
	self.controls.tlw:SetDrawLevel(0)
	self:AnchorTLW()

	for _, offsets in ipairs(bubbles) do
		local control = WM:CreateControl(nil, self.controls.tlw, CT_CONTROL)
		control:SetDimensions(175, bubbleHeight)
		control:SetAnchor(CENTER, self.controls.tlw, nil, offsets[1], offsets[2])
		control:SetAlpha(0)

		local timeline = self:AnimateBubble(control, 500)

		function control:AnimateStop(callback)
			if callback then
				timeline:SetHandler("OnStop", callback)
			end

			timeline:PlayInstantlyToStart()
		end

		function control:IsAnimating()
			return timeline:IsPlaying()
		end

		function control:GetProgress()
			return timeline:GetProgress()
		end

		function control:Animate(duration)
			local scale, toScale = self:GetScale(), 1.2
			local alpha, toAlpha = self:GetAlpha(), SCB.db.opacity

			if timeline:GetHandler("OnStop") then
				timeline:SetHandler("OnStop", nil)
			end

			timeline.fadeIn:SetAlphaValues(alpha, toAlpha)

			if SCB.db.animatePop then
				timeline.scaleOut:SetScaleValues(scale, toScale)
				timeline.scaleIn:SetScaleValues(toScale, scale)
			end

			timeline.fadeOut:SetAlphaValues(toAlpha, alpha)
			timeline:SetAnimationOffset(timeline.fadeOut, duration)
			timeline:PlayFromStart()
		end

		local bg = WM:CreateControl(nil, control, CT_BACKDROP)
		
		if SCB.db.showBackdrop then
			bg:SetCenterTexture(LMP:Fetch('background', "ESO Chat"))
			bg:SetEdgeTexture(LMP:Fetch('border', "ESO Chat"), 256, 32, 16)
			bg:SetInsets(16,16,-(16),-(16))
		else
			bg:SetAlpha(0)
			bg:SetEdgeColor(0, 0, 0, 0)
		end
		
		bg:SetAnchor(TOP, control)
		
		local headerfont = LMP:Fetch('font', self.db.headerFont) .. "|" .. self.db.playerNameFontSize
		local bodyFont = LMP:Fetch('font', self.db.bodyFont) .. "|" .. self.db.bodyFontSize
		
		if SCB.db.showTextShadow then
			headerfont = headerfont .. "|" .. "soft-shadow-thick"
			bodyFont = bodyFont .. "|" .. "soft-shadow-thick"
		end
		
		local labelPlayer = WM:CreateControl(nil, control, CT_LABEL)
		labelPlayer:SetFont(headerfont)
		labelPlayer:SetAnchor(TOP, control, nil, 0, labelVertical)
		labelPlayer:SetColor(self.db.headerColor.r, self.db.headerColor.g, self.db.headerColor.b)
		labelPlayer:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
		labelPlayer:SetVerticalAlignment(TEXT_ALIGN_TOP)

		local labelChat = WM:CreateControl(nil, control, CT_LABEL)
		labelChat:SetFont(bodyFont)
		labelChat:SetAnchor(CENTER, control)
		labelChat:SetColor(self.db.bodyColor.r, self.db.bodyColor.g, self.db.bodyColor.b)
		labelChat:SetDimensions(control:GetWidth(), control:GetHeight() - 60)
		labelChat:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
		labelChat:SetVerticalAlignment(TEXT_ALIGN_TOP)
		labelChat:SetWrapMode(TEXT_WRAP_MODE_ELLIPSIS)
		
		table.insert(self.controls.bubbles, {
			control = control,
			bg = bg,
			labelChat = labelChat,
			labelPlayer = labelPlayer
		})
	end
end

EVENT_MANAGER:RegisterForEvent(SCB.name, EVENT_ADD_ON_LOADED, function(_, name)
	if name == SCB.name then
		EVENT_MANAGER:UnregisterForEvent(SCB.name, EVENT_ADD_ON_LOADED)
		SCB:Init()
	end
end)
