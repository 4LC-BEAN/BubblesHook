--//============================================================
--// BUBBLESHOOK V2 - PREMIUM UI
--// Full UI / Key / Loading / Bubble Reveal / Console
--// Appearance / Players / Spectate / Fixed Top Navigation
--// Premium Glow / Shine / Hover / Animated UI Effects
--//============================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
if not player then
return
end

local playerGui = player:WaitForChild("PlayerGui")

--============================================================
-- CLEANUP
--============================================================

local oldGui = playerGui:FindFirstChild("BubblesHook")
if oldGui then
oldGui:Destroy()
end

local oldSFX = SoundService:FindFirstChild("BubblesHookSFX")
if oldSFX then
oldSFX:Destroy()
end

--============================================================
-- COLORS
--============================================================

local BLACK = Color3.fromRGB(4, 5, 7)
local DARKER = Color3.fromRGB(7, 8, 11)
local DARK = Color3.fromRGB(10, 11, 14)

local PANEL = Color3.fromRGB(15, 16, 20)
local PANEL2 = Color3.fromRGB(18, 19, 24)
local PANEL3 = Color3.fromRGB(22, 23, 29)

local HOVER = Color3.fromRGB(29, 31, 38)

local BORDER = Color3.fromRGB(52, 55, 64)
local BORDER_SOFT = Color3.fromRGB(37, 39, 47)

local WHITE = Color3.fromRGB(244, 245, 248)
local SILVER = Color3.fromRGB(202, 204, 211)
local LIGHTGREY = Color3.fromRGB(151, 154, 163)
local GREY = Color3.fromRGB(103, 106, 115)

local ACCENT = Color3.fromRGB(225, 229, 238)

local GLOW = Color3.fromRGB(190, 205, 235)
local GLOW_SOFT = Color3.fromRGB(95, 110, 140)

--============================================================
-- STATE
--============================================================

local State = {
Unlocked = false,
Unloaded = false,

BaseColor = PANEL,
AccentColor = ACCENT,

Animations = true,
Bubbles = true,
SFX = true,

CurrentTab = "Hub",
SelectedPlayer = nil,

ConsoleHistory = {},
ConsoleIndex = 0,

Spectating = false,
}

local Connections = {}

local function connect(signal, callback)
local c = signal:Connect(callback)
table.insert(Connections, c)
return c
end

local function disconnectAll()
for _, c in ipairs(Connections) do
if c and c.Connected then
c:Disconnect()
end
end

table.clear(Connections)
end

--============================================================
-- GUI
--============================================================

local gui = Instance.new("ScreenGui")
gui.Name = "BubblesHook"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 100
gui.Parent = playerGui

--============================================================
-- HELPERS
--============================================================

local function corner(object, radius)
local c = Instance.new("UICorner")
c.CornerRadius = UDim.new(0, radius or 5)
c.Parent = object
return c
end

local function stroke(object, color, thickness, transparency)
local s = Instance.new("UIStroke")
s.Color = color or BORDER
s.Thickness = thickness or 1
s.Transparency = transparency or 0
s.Parent = object
return s
end

local function tween(object, info, properties)
if not object or not object.Parent then
return nil
end

local t = TweenService:Create(object, info, properties)
t:Play()
return t
end

local function quickTween(object, duration, properties)
if not object or not object.Parent then
return
end

if not State.Animations then
for property, value in pairs(properties) do
object[property] = value
end
return
end

return tween(
object,
TweenInfo.new(
duration or 0.15,
Enum.EasingStyle.Quad,
Enum.EasingDirection.Out
),
properties
)
end

local function makeLabel(parent, text, size, color, font)
local l = Instance.new("TextLabel")
l.BackgroundTransparency = 1
l.Text = text
l.TextColor3 = color or WHITE
l.TextSize = size or 14
l.Font = font or Enum.Font.Gotham
l.Parent = parent
return l
end

local function gradient(object)
local g = Instance.new("UIGradient")

g.Rotation = 35

g.Color = ColorSequence.new({
ColorSequenceKeypoint.new(0, WHITE),
ColorSequenceKeypoint.new(0.5, Color3.fromRGB(110, 118, 135)),
ColorSequenceKeypoint.new(1, WHITE)
})

g.Parent = object
return g
end

--============================================================
-- PREMIUM EFFECT HELPERS
--============================================================

local function addGlow(object, color, size, transparency)
if not object or not object:IsA("GuiObject") then
return
end

local old = object:FindFirstChild("BubbleGlow")
if old then
old:Destroy()
end

local glow = Instance.new("ImageLabel")
glow.Name = "BubbleGlow"
glow.BackgroundTransparency = 1
glow.AnchorPoint = Vector2.new(0.5, 0.5)
glow.Position = UDim2.fromScale(0.5, 0.5)
glow.Size = UDim2.new(
1,
size or 35,
1,
size or 35
)

glow.Image = "rbxassetid://5028857084"
glow.ImageColor3 = color or GLOW
glow.ImageTransparency = transparency or 0.8
glow.ScaleType = Enum.ScaleType.Slice
glow.SliceCenter = Rect.new(24, 24, 276, 276)
glow.ZIndex = math.max(object.ZIndex - 1, 0)
glow.Parent = object

return glow
end

local function addShine(object)
	if not object or not object:IsA("GuiObject") then
		return
	end

	local old = object:FindFirstChild("BubbleShine")
	if old then
		old:Destroy()
	end

	-- Contained gradient shine: stays inside the GuiObject.
	local shine = Instance.new("UIGradient")
	shine.Name = "BubbleShine"
	shine.Rotation = 0
	shine.Offset = Vector2.new(-0.35, 0)

	shine.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 11, 14)),
		ColorSequenceKeypoint.new(0.38, Color3.fromRGB(10, 11, 14)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(55, 58, 68)),
		ColorSequenceKeypoint.new(0.62, Color3.fromRGB(10, 11, 14)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 11, 14))
	})

	shine.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.18),
		NumberSequenceKeypoint.new(0.38, 0.18),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(0.62, 0.18),
		NumberSequenceKeypoint.new(1, 0.18)
	})

	shine.Parent = object
	return shine
end

local function animateShine(object)
	if not State.Animations or not object then
		return
	end

	local shine = object:FindFirstChild("BubbleShine")
	if not shine or not shine:IsA("UIGradient") then
		return
	end

	shine.Offset = Vector2.new(-0.35, 0)

	tween(
		shine,
		TweenInfo.new(
			0.75,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		),
		{
			Offset = Vector2.new(0.35, 0)
		}
	)
end

local function addButtonEffect(button, normalColor, hoverColor)
if not button then
return
end

addShine(button)

connect(button.MouseEnter, function()
quickTween(button, 0.16, {
BackgroundColor3 = hoverColor or HOVER
})

animateShine(button)
playSound(hoverSound)
end)

connect(button.MouseLeave, function()
quickTween(button, 0.16, {
BackgroundColor3 = normalColor or DARK
})
end)
end

local function pulse(object, amount, duration)
if not State.Animations or not object then
return
end

local original = object.Size
local d = duration or 0.25
local a = amount or 4

tween(
object,
TweenInfo.new(
d,
Enum.EasingStyle.Quad,
Enum.EasingDirection.Out
),
{
Size = UDim2.new(
original.X.Scale,
original.X.Offset + a,
original.Y.Scale,
original.Y.Offset + a
)
}
)

task.delay(d, function()
if object and object.Parent then
tween(
object,
TweenInfo.new(
d,
Enum.EasingStyle.Quad,
Enum.EasingDirection.Out
),
{
Size = original
}
)
end
end)
end

--============================================================
-- GRADIENT EFFECT NOTES
-- The old off-screen Frame shine has been replaced by UIGradient.
-- UIGradient is contained by each GuiObject, so it cannot extend
-- outside the button/card/window while the shine animates.
--============================================================

--============================================================
-- SOUND
--============================================================

local sfxFolder = Instance.new("Folder")
sfxFolder.Name = "BubblesHookSFX"
sfxFolder.Parent = SoundService

local SOUND_IDS = {
Bubble = "rbxassetid://137426393727807",
Hover = "rbxassetid://139719503904449",
Click = "rbxassetid://9083627113"
}

local function makeSound(name, id, volume)
local s = Instance.new("Sound")
s.Name = name
s.SoundId = id
s.Volume = volume
s.Parent = sfxFolder
return s
end

local hoverSound = makeSound("Hover", SOUND_IDS.Hover, 0.08)
local clickSound = makeSound("Click", SOUND_IDS.Click, 0.12)
local bubbleTemplate = makeSound("Bubble", SOUND_IDS.Bubble, 0.05)

function playSound(sound)
if State.SFX and sound then
sound:Stop()
sound:Play()
end
end

local function playBubbleSound()
if not State.SFX then
return
end

local sound = bubbleTemplate:Clone()

sound.Name = "BubblePop"
sound.Volume = math.random(3, 7) / 100
sound.PlaybackSpeed = math.random(88, 115) / 100
sound.Parent = sfxFolder

sound:Play()

task.delay(3, function()
if sound and sound.Parent then
sound:Destroy()
end
end)
end

--============================================================
-- BUBBLES
--============================================================

local function createBubble(parent, x, y, w, h)
local bubble = Instance.new("Frame")

bubble.BackgroundColor3 = WHITE
bubble.Position = UDim2.fromScale(x, y)
bubble.Size = UDim2.fromScale(w, h)
bubble.BorderSizePixel = 0
bubble.Parent = parent

corner(bubble, 999)
stroke(bubble, WHITE, 1, 0.15)
gradient(bubble)

local highlight = Instance.new("Frame")
highlight.BackgroundColor3 = WHITE
highlight.BackgroundTransparency = 0.05
highlight.Position = UDim2.fromScale(0.18, 0.13)
highlight.Size = UDim2.fromScale(0.30, 0.19)
highlight.BorderSizePixel = 0
highlight.Parent = bubble

corner(highlight, 999)

return bubble
end

local function createLogo(parent, position, size)
local logo = Instance.new("Frame")

logo.BackgroundTransparency = 1
logo.Position = position
logo.Size = size
logo.Parent = parent

createBubble(logo, 0.12, 0.18, 0.57, 0.57)
createBubble(logo, 0.53, 0.03, 0.28, 0.28)
createBubble(logo, 0.62, 0.59, 0.22, 0.22)

return logo
end

--============================================================
-- KEY SCREEN
--============================================================

local keyOverlay = Instance.new("Frame")
keyOverlay.Name = "KeyOverlay"
keyOverlay.BackgroundColor3 = BLACK
keyOverlay.Size = UDim2.fromScale(1, 1)
keyOverlay.BorderSizePixel = 0
keyOverlay.ZIndex = 100
keyOverlay.Parent = gui

local keyGradient = Instance.new("UIGradient")
keyGradient.Rotation = 90
keyGradient.Color = ColorSequence.new({
ColorSequenceKeypoint.new(0, Color3.fromRGB(3, 4, 6)),
ColorSequenceKeypoint.new(0.5, Color3.fromRGB(11, 12, 16)),
ColorSequenceKeypoint.new(1, Color3.fromRGB(3, 4, 6))
})
keyGradient.Parent = keyOverlay

-- Background particles
local keyParticles = {}

for i = 1, 70 do
local b = Instance.new("Frame")

b.BackgroundColor3 = WHITE
b.BackgroundTransparency = math.random(95, 99) / 100
b.BorderSizePixel = 0

local s = math.random(4, 17)
b.Size = UDim2.fromOffset(s, s)

b.Position = UDim2.fromScale(
math.random(),
math.random()
)

b.Parent = keyOverlay
corner(b, 999)

table.insert(keyParticles, {
Object = b,
Speed = math.random(5, 16) / 1000,
Phase = math.random() * 6
})
end

local keyCard = Instance.new("Frame")
keyCard.BackgroundColor3 = PANEL
keyCard.Size = UDim2.fromOffset(410, 275)
keyCard.AnchorPoint = Vector2.new(0.5, 0.5)
keyCard.Position = UDim2.fromScale(0.5, 0.5)
keyCard.BorderSizePixel = 0
keyCard.ZIndex = 101
keyCard.Parent = keyOverlay

corner(keyCard, 8)
stroke(keyCard, BORDER, 1, 0)

local keyGlow = addGlow(
keyCard,
Color3.fromRGB(100, 115, 145),
55,
0.88
)

if keyGlow then
keyGlow.ZIndex = 99
end

addShine(keyCard)

local keyLogo = createLogo(
keyCard,
UDim2.new(0.5, -32, 0, 14),
UDim2.fromOffset(64, 64)
)
keyLogo.ZIndex = 102

local keyTitle = makeLabel(
keyCard,
"ACCESS",
22,
WHITE,
Enum.Font.GothamBold
)

keyTitle.Size = UDim2.new(1, 0, 0, 30)
keyTitle.Position = UDim2.fromOffset(0, 76)
keyTitle.ZIndex = 102

local keySub = makeLabel(
keyCard,
"Enter the access key to continue",
11,
LIGHTGREY
)

keySub.Size = UDim2.new(1, 0, 0, 20)
keySub.Position = UDim2.fromOffset(0, 106)
keySub.ZIndex = 102

local keyInput = Instance.new("TextBox")
keyInput.BackgroundColor3 = PANEL2
keyInput.TextColor3 = WHITE
keyInput.PlaceholderColor3 = GREY
keyInput.PlaceholderText = "Enter access key"
keyInput.Text = ""
keyInput.ClearTextOnFocus = false
keyInput.TextSize = 13
keyInput.Font = Enum.Font.Gotham
keyInput.Size = UDim2.new(1, -50, 0, 42)
keyInput.Position = UDim2.fromOffset(25, 138)
keyInput.BorderSizePixel = 0
keyInput.ZIndex = 102
keyInput.Parent = keyCard

corner(keyInput, 5)
stroke(keyInput, BORDER_SOFT, 1, 0)

local unlockButton = Instance.new("TextButton")
unlockButton.BackgroundColor3 = WHITE
unlockButton.TextColor3 = Color3.fromRGB(15, 16, 19)
unlockButton.Text = "UNLOCK"
unlockButton.TextSize = 12
unlockButton.Font = Enum.Font.GothamBold
unlockButton.Size = UDim2.new(1, -50, 0, 40)
unlockButton.Position = UDim2.fromOffset(25, 188)
unlockButton.BorderSizePixel = 0
unlockButton.AutoButtonColor = false
unlockButton.ZIndex = 102
unlockButton.Parent = keyCard

corner(unlockButton, 5)
addShine(unlockButton)

local statusLabel = makeLabel(
keyCard,
"WAITING FOR KEY",
9,
GREY,
Enum.Font.GothamMedium
)

statusLabel.Size = UDim2.new(1, 0, 0, 20)
statusLabel.Position = UDim2.fromOffset(0, 239)
statusLabel.ZIndex = 102

connect(unlockButton.MouseEnter, function()
quickTween(unlockButton, 0.15, {
BackgroundColor3 = SILVER
})

animateShine(unlockButton)
playSound(hoverSound)
end)

connect(unlockButton.MouseLeave, function()
quickTween(unlockButton, 0.15, {
BackgroundColor3 = WHITE
})
end)

--============================================================
-- LOADING SCREEN
--============================================================

local loadingOverlay = Instance.new("Frame")
loadingOverlay.Name = "LoadingOverlay"
loadingOverlay.BackgroundColor3 = BLACK
loadingOverlay.Size = UDim2.fromScale(1, 1)
loadingOverlay.BorderSizePixel = 0
loadingOverlay.ZIndex = 120
loadingOverlay.Visible = false
loadingOverlay.Parent = gui

local loadingGradient = Instance.new("UIGradient")
loadingGradient.Rotation = 90
loadingGradient.Color = ColorSequence.new({
ColorSequenceKeypoint.new(0, Color3.fromRGB(3, 4, 6)),
ColorSequenceKeypoint.new(0.5, Color3.fromRGB(11, 12, 16)),
ColorSequenceKeypoint.new(1, Color3.fromRGB(3, 4, 6))
})
loadingGradient.Parent = loadingOverlay

local loadingContent = Instance.new("Frame")
loadingContent.BackgroundTransparency = 1
loadingContent.Size = UDim2.fromOffset(470, 300)
loadingContent.AnchorPoint = Vector2.new(0.5, 0.5)
loadingContent.Position = UDim2.fromScale(0.5, 0.5)
loadingContent.ZIndex = 121
loadingContent.Parent = loadingOverlay

local gearHolder = Instance.new("Frame")
gearHolder.BackgroundTransparency = 1
gearHolder.Size = UDim2.fromOffset(60, 60)
gearHolder.AnchorPoint = Vector2.new(0.5, 0.5)
gearHolder.Position = UDim2.fromScale(0.5, 0.19)
gearHolder.ZIndex = 122
gearHolder.Parent = loadingContent

local gearOuter = Instance.new("Frame")
gearOuter.BackgroundColor3 = WHITE
gearOuter.Size = UDim2.fromOffset(48, 48)
gearOuter.AnchorPoint = Vector2.new(0.5, 0.5)
gearOuter.Position = UDim2.fromScale(0.5, 0.5)
gearOuter.BorderSizePixel = 0
gearOuter.Parent = gearHolder

corner(gearOuter, 999)

local gearGlow = addGlow(
gearOuter,
GLOW,
30,
0.65
)

if gearGlow then
gearGlow.ZIndex = 120
end

local gearHole = Instance.new("Frame")
gearHole.BackgroundColor3 = DARK
gearHole.Size = UDim2.fromOffset(18, 18)
gearHole.AnchorPoint = Vector2.new(0.5, 0.5)
gearHole.Position = UDim2.fromScale(0.5, 0.5)
gearHole.BorderSizePixel = 0
gearHole.Parent = gearHolder

corner(gearHole, 999)

local loadTitle = makeLabel(
loadingContent,
"INITIALIZING",
21,
WHITE,
Enum.Font.GothamBold
)

loadTitle.Size = UDim2.new(1, 0, 0, 30)
loadTitle.Position = UDim2.fromOffset(0, 88)

local loadSub = makeLabel(
loadingContent,
"Preparing BubblesHook",
11,
LIGHTGREY
)

loadSub.Size = UDim2.new(1, 0, 0, 20)
loadSub.Position = UDim2.fromOffset(0, 119)

local bar = Instance.new("Frame")
bar.BackgroundColor3 = PANEL3
bar.Size = UDim2.fromOffset(380, 7)
bar.AnchorPoint = Vector2.new(0.5, 0)
bar.Position = UDim2.fromScale(0.5, 0.62)
bar.BorderSizePixel = 0
bar.Parent = loadingContent

corner(bar, 4)
stroke(bar, BORDER_SOFT)

local barGlow = addGlow(
bar,
GLOW_SOFT,
18,
0.75
)

if barGlow then
barGlow.ZIndex = 120
end

local barFill = Instance.new("Frame")
barFill.BackgroundColor3 = WHITE
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BorderSizePixel = 0
barFill.Parent = bar

corner(barFill, 4)
gradient(barFill)

local percent = makeLabel(
loadingContent,
"0%",
10,
GREY,
Enum.Font.GothamMedium
)

percent.Size = UDim2.new(1, 0, 0, 20)
percent.Position = UDim2.fromOffset(0, 177)

--============================================================
-- REVEAL
--============================================================

local revealOverlay = Instance.new("Frame")
revealOverlay.Name = "RevealOverlay"
revealOverlay.BackgroundColor3 = BLACK
revealOverlay.Size = UDim2.fromScale(1, 1)
revealOverlay.BorderSizePixel = 0
revealOverlay.ZIndex = 140
revealOverlay.Visible = false
revealOverlay.Parent = gui

local revealBubbles = {}

for i = 1, 180 do
local bubble = Instance.new("Frame")

bubble.BackgroundColor3 = WHITE
bubble.BackgroundTransparency = 1
bubble.BorderSizePixel = 0

local size = math.random(6, 48)

bubble.Size = UDim2.fromOffset(size, size)

bubble.Position = UDim2.fromScale(
math.random(-10, 110) / 100,
1.02 + math.random(-10, 120) / 100
)

bubble.ZIndex = 141
bubble.Parent = revealOverlay

corner(bubble, 999)

stroke(
bubble,
WHITE,
math.random(1, 2),
math.random(35, 75) / 100
)

addGlow(
bubble,
GLOW,
math.clamp(size, 10, 30),
0.93
)

table.insert(revealBubbles, bubble)
end

local revealLogo = createLogo(
revealOverlay,
UDim2.new(0.5, -110, 1.3, 0),
UDim2.fromOffset(220, 220)
)

revealLogo.ZIndex = 145

local revealGlow = addGlow(
revealLogo,
GLOW,
70,
0.75
)

if revealGlow then
revealGlow.ZIndex = 143
end

--============================================================
-- MAIN HUB
--============================================================

local hubShadow = Instance.new("Frame")
hubShadow.BackgroundColor3 = Color3.new(0, 0, 0)
hubShadow.BackgroundTransparency = 0.5
hubShadow.Size = UDim2.fromOffset(775, 485)
hubShadow.AnchorPoint = Vector2.new(0.5, 0.5)
hubShadow.Position = UDim2.fromScale(0.5, 0.5)
hubShadow.BorderSizePixel = 0
hubShadow.Visible = false
hubShadow.ZIndex = 1
hubShadow.Parent = gui

corner(hubShadow, 9)

local hub = Instance.new("Frame")
hub.Name = "Hub"
hub.BackgroundColor3 = PANEL
hub.Size = UDim2.fromOffset(760, 470)
hub.AnchorPoint = Vector2.new(0.5, 0.5)
hub.Position = UDim2.fromScale(0.5, 0.5)
hub.BorderSizePixel = 0
hub.Visible = false
hub.ClipsDescendants = true
hub.ZIndex = 5
hub.Parent = gui

corner(hub, 8)
stroke(hub, BORDER)

local hubGlow = addGlow(
hub,
Color3.fromRGB(100, 115, 145),
50,
0.87
)

if hubGlow then
hubGlow.ZIndex = 1
end

--============================================================
-- TOP BAR
--============================================================

local topBar = Instance.new("Frame")
topBar.BackgroundColor3 = DARK
topBar.Size = UDim2.new(1, 0, 0, 68)
topBar.BorderSizePixel = 0
topBar.Parent = hub

local topGradient = Instance.new("UIGradient")
topGradient.Rotation = 0
topGradient.Color = ColorSequence.new({
ColorSequenceKeypoint.new(0, Color3.fromRGB(7, 8, 11)),
ColorSequenceKeypoint.new(0.5, Color3.fromRGB(20, 22, 28)),
ColorSequenceKeypoint.new(1, Color3.fromRGB(7, 8, 11))
})
topGradient.Parent = topBar

local logo = createLogo(
topBar,
UDim2.fromOffset(20, 14),
UDim2.fromOffset(40, 40)
)

local title = makeLabel(
topBar,
"BUBBLESHOOK",
15,
WHITE,
Enum.Font.GothamBold
)

title.Position = UDim2.fromOffset(72, 17)
title.Size = UDim2.fromOffset(180, 20)
title.TextXAlignment = Enum.TextXAlignment.Left

local subtitle = makeLabel(
topBar,
"INTERFACE",
9,
GREY,
Enum.Font.GothamMedium
)

subtitle.Position = UDim2.fromOffset(72, 38)
subtitle.Size = UDim2.fromOffset(100, 15)
subtitle.TextXAlignment = Enum.TextXAlignment.Left

--============================================================
-- WINDOW BUTTONS
--============================================================

local function windowButton(text, x)
local button = Instance.new("TextButton")

button.BackgroundColor3 = DARK
button.Text = text
button.TextColor3 = LIGHTGREY
button.TextSize = 18
button.Font = Enum.Font.Gotham
button.Size = UDim2.fromOffset(42, 42)
button.Position = UDim2.new(1, x, 0, 13)
button.BorderSizePixel = 0
button.AutoButtonColor = false
button.Parent = topBar

corner(button, 5)
addShine(button)

connect(button.MouseEnter, function()
quickTween(button, 0.12, {
BackgroundColor3 = HOVER,
TextColor3 = WHITE
})

animateShine(button)
playSound(hoverSound)
end)

connect(button.MouseLeave, function()
quickTween(button, 0.12, {
BackgroundColor3 = DARK,
TextColor3 = LIGHTGREY
})
end)

return button
end

local closeButton = windowButton("×", -52)
local minButton = windowButton("−", -100)
local maxButton = windowButton("□", -148)

--============================================================
-- SIDEBAR
--============================================================

local sidebar = Instance.new("Frame")
sidebar.BackgroundColor3 = DARK
sidebar.Size = UDim2.new(0, 176, 1, -68)
sidebar.Position = UDim2.fromOffset(0, 68)
sidebar.BorderSizePixel = 0
sidebar.Parent = hub

local sidebarLine = Instance.new("Frame")
sidebarLine.BackgroundColor3 = BORDER_SOFT
sidebarLine.Size = UDim2.new(0, 1, 1, 0)
sidebarLine.Position = UDim2.new(1, -1, 0, 0)
sidebarLine.BorderSizePixel = 0
sidebarLine.Parent = sidebar

local tabsHolder = Instance.new("Frame")
tabsHolder.BackgroundTransparency = 1
tabsHolder.Size = UDim2.new(1, -20, 0, 180)
tabsHolder.Position = UDim2.fromOffset(10, 18)
tabsHolder.Parent = sidebar

local tabLayout = Instance.new("UIListLayout")
tabLayout.Padding = UDim.new(0, 5)
tabLayout.Parent = tabsHolder

local tabs = {}

-- Forward declaration fixes page closure.
local pages = {}

local function createTab(name, icon)
local button = Instance.new("TextButton")

button.BackgroundColor3 = DARK
button.Text = ""
button.Size = UDim2.new(1, 0, 0, 40)
button.BorderSizePixel = 0
button.AutoButtonColor = false
button.Parent = tabsHolder

corner(button, 4)
addShine(button)

local iconLabel = makeLabel(
button,
icon,
14,
LIGHTGREY,
Enum.Font.GothamBold
)

iconLabel.Position = UDim2.fromOffset(12, 0)
iconLabel.Size = UDim2.fromOffset(22, 40)

local textLabel = makeLabel(
button,
name,
11,
LIGHTGREY,
Enum.Font.GothamMedium
)

textLabel.Position = UDim2.fromOffset(39, 0)
textLabel.Size = UDim2.new(1, -45, 1, 0)
textLabel.TextXAlignment = Enum.TextXAlignment.Left

local indicator = Instance.new("Frame")
indicator.BackgroundColor3 = ACCENT
indicator.Size = UDim2.fromOffset(2, 18)
indicator.Position = UDim2.fromOffset(0, 11)
indicator.BorderSizePixel = 0
indicator.Visible = false
indicator.Parent = button

corner(indicator, 2)

tabs[name] = {
Button = button,
Icon = iconLabel,
Text = textLabel,
Indicator = indicator
}

connect(button.MouseEnter, function()
if not button:GetAttribute("Selected") then
quickTween(button, 0.12, {
BackgroundColor3 = HOVER
})
end

animateShine(button)
playSound(hoverSound)
end)

connect(button.MouseLeave, function()
if not button:GetAttribute("Selected") then
quickTween(button, 0.12, {
BackgroundColor3 = DARK
})
end
end)

connect(button.MouseButton1Click, function()
for tabName, data in pairs(tabs) do
local selected = tabName == name

data.Button:SetAttribute("Selected", selected)
data.Indicator.Visible = selected

quickTween(data.Button, 0.15, {
BackgroundColor3 = selected
and Color3.fromRGB(27, 29, 36)
or DARK
})

data.Icon.TextColor3 =
selected and State.AccentColor or LIGHTGREY

data.Text.TextColor3 =
selected and WHITE or LIGHTGREY
end

for pageName, page in pairs(pages) do
page.Visible = pageName == name
end

playSound(clickSound)
end)

return button
end

createTab("Home", "●")
createTab("Visuals", "◈")
createTab("Settings", "⚙")
createTab("Misc", "◆")

--============================================================
-- PROFILE
--============================================================

local profile = Instance.new("Frame")
profile.BackgroundColor3 = PANEL
profile.Size = UDim2.new(1, -20, 0, 55)
profile.Position = UDim2.new(0, 10, 1, -68)
profile.BorderSizePixel = 0
profile.Parent = sidebar

corner(profile, 5)
stroke(profile, BORDER_SOFT)

local avatar = Instance.new("Frame")
avatar.BackgroundColor3 = PANEL3
avatar.Size = UDim2.fromOffset(34, 34)
avatar.Position = UDim2.fromOffset(10, 10)
avatar.BorderSizePixel = 0
avatar.Parent = profile

corner(avatar, 999)

local avatarLetter = makeLabel(
avatar,
string.sub(player.DisplayName, 1, 1):upper(),
14,
WHITE,
Enum.Font.GothamBold
)

avatarLetter.Size = UDim2.fromScale(1, 1)

local profileName = makeLabel(
profile,
player.DisplayName,
11,
WHITE,
Enum.Font.GothamMedium
)

profileName.Position = UDim2.fromOffset(53, 9)
profileName.Size = UDim2.new(1, -60, 0, 18)
profileName.TextXAlignment = Enum.TextXAlignment.Left

local profileStatus = makeLabel(
profile,
"CONNECTED",
8,
GREY,
Enum.Font.GothamMedium
)

profileStatus.Position = UDim2.fromOffset(53, 27)
profileStatus.Size = UDim2.new(1, -60, 0, 15)
profileStatus.TextXAlignment = Enum.TextXAlignment.Left

--============================================================
-- CONTENT
--============================================================

local content = Instance.new("Frame")
content.BackgroundTransparency = 1
content.Size = UDim2.new(1, -176, 1, -68)
content.Position = UDim2.fromOffset(176, 68)
content.Parent = hub

local function createPage(name)
local page = Instance.new("Frame")

page.Name = name
page.BackgroundTransparency = 1
page.Size = UDim2.fromScale(1, 1)
page.Visible = false
page.Parent = content

pages[name] = page

return page
end

local homePage = createPage("Home")
local visualsPage = createPage("Visuals")
local settingsPage = createPage("Settings")
local miscPage = createPage("Misc")

local function pageTitle(parent, titleText, subText)
local t = makeLabel(
parent,
titleText,
20,
WHITE,
Enum.Font.GothamBold
)

t.Position = UDim2.fromOffset(24, 20)
t.Size = UDim2.new(1, -48, 0, 28)
t.TextXAlignment = Enum.TextXAlignment.Left

local s = makeLabel(
parent,
subText,
10,
GREY
)

s.Position = UDim2.fromOffset(25, 49)
s.Size = UDim2.new(1, -50, 0, 20)
s.TextXAlignment = Enum.TextXAlignment.Left
end

local function createCard(parent, position, size, titleText)
local card = Instance.new("Frame")

card.BackgroundColor3 = PANEL2
card.Position = position
card.Size = size
card.BorderSizePixel = 0
card.Parent = parent

corner(card, 5)
stroke(card, BORDER_SOFT)

addShine(card)

local highlight = Instance.new("Frame")
highlight.BackgroundColor3 = WHITE
highlight.BackgroundTransparency = 0.965
highlight.Size = UDim2.new(1, -2, 0, 1)
highlight.Position = UDim2.fromOffset(1, 1)
highlight.BorderSizePixel = 0
highlight.Parent = card

corner(highlight, 5)

connect(card.MouseEnter, function()
quickTween(card, 0.18, {
BackgroundColor3 = Color3.fromRGB(20, 21, 27)
})

animateShine(card)
end)

connect(card.MouseLeave, function()
quickTween(card, 0.18, {
BackgroundColor3 = PANEL2
})
end)

local t = makeLabel(
card,
titleText,
10,
SILVER,
Enum.Font.GothamBold
)

t.Position = UDim2.fromOffset(15, 13)
t.Size = UDim2.new(1, -30, 0, 18)
t.TextXAlignment = Enum.TextXAlignment.Left

return card
end

--============================================================
-- CONTROLS
--============================================================

local function createToggle(parent, y, textValue, default)
local row = Instance.new("Frame")

row.BackgroundTransparency = 1
row.Size = UDim2.new(1, -30, 0, 34)
row.Position = UDim2.fromOffset(15, y)
row.Parent = parent

local textLabel = makeLabel(
row,
textValue,
11,
SILVER
)

textLabel.Size = UDim2.new(1, -60, 1, 0)
textLabel.TextXAlignment = Enum.TextXAlignment.Left

local toggle = Instance.new("TextButton")

toggle.BackgroundColor3 = default and State.AccentColor or PANEL3
toggle.Size = UDim2.fromOffset(38, 20)
toggle.Position = UDim2.new(1, -38, 0.5, -10)
toggle.Text = ""
toggle.BorderSizePixel = 0
toggle.AutoButtonColor = false
toggle.Parent = row

corner(toggle, 10)

local knob = Instance.new("Frame")

knob.BackgroundColor3 = default and DARK or GREY
knob.Size = UDim2.fromOffset(14, 14)
knob.Position =
default
and UDim2.new(1, -17, 0.5, -7)
or UDim2.fromOffset(3, 3)

knob.BorderSizePixel = 0
knob.Parent = toggle

corner(knob, 999)

local state = default

connect(toggle.MouseEnter, function()
quickTween(toggle, 0.12, {
BackgroundColor3 = state
and State.AccentColor:Lerp(WHITE, 0.12)
or HOVER
})

playSound(hoverSound)
end)

connect(toggle.MouseLeave, function()
quickTween(toggle, 0.12, {
BackgroundColor3 =
state and State.AccentColor or PANEL3
})
end)

connect(toggle.MouseButton1Click, function()
state = not state

playSound(clickSound)
pulse(toggle, 2, 0.12)

quickTween(toggle, 0.16, {
BackgroundColor3 =
state and State.AccentColor or PANEL3
})

quickTween(knob, 0.16, {
Position =
state
and UDim2.new(1, -17, 0.5, -7)
or UDim2.fromOffset(3, 3),

BackgroundColor3 =
state and DARK or GREY
})
end)

return toggle
end

local function createDropdown(parent, y, textValue, options, default)
local row = Instance.new("Frame")

row.BackgroundTransparency = 1
row.Size = UDim2.new(1, -30, 0, 36)
row.Position = UDim2.fromOffset(15, y)
row.Parent = parent

local textLabel = makeLabel(
row,
textValue,
11,
SILVER
)

textLabel.Size = UDim2.new(0.45, 0, 1, 0)
textLabel.TextXAlignment = Enum.TextXAlignment.Left

local dropdown = Instance.new("TextButton")

dropdown.BackgroundColor3 = PANEL3
dropdown.Text = default or options[1]
dropdown.TextColor3 = LIGHTGREY
dropdown.TextSize = 10
dropdown.Font = Enum.Font.GothamMedium
dropdown.Size = UDim2.fromOffset(125, 28)
dropdown.Position = UDim2.new(1, -125, 0.5, -14)
dropdown.BorderSizePixel = 0
dropdown.AutoButtonColor = false
dropdown.Parent = row

corner(dropdown, 4)
addShine(dropdown)

local index = 1

for i, option in ipairs(options) do
if option == default then
index = i
break
end
end

connect(dropdown.MouseEnter, function()
quickTween(dropdown, 0.12, {
BackgroundColor3 = HOVER,
TextColor3 = WHITE
})

animateShine(dropdown)
playSound(hoverSound)
end)

connect(dropdown.MouseLeave, function()
quickTween(dropdown, 0.12, {
BackgroundColor3 = PANEL3,
TextColor3 = LIGHTGREY
})
end)

connect(dropdown.MouseButton1Click, function()
index += 1

if index > #options then
index = 1
end

dropdown.Text = options[index]

pulse(dropdown, 2, 0.1)
playSound(clickSound)
end)

return dropdown
end

local function createSlider(parent, y, textValue, default)
local row = Instance.new("Frame")

row.BackgroundTransparency = 1
row.Size = UDim2.new(1, -30, 0, 48)
row.Position = UDim2.fromOffset(15, y)
row.Parent = parent

local textLabel = makeLabel(
row,
textValue,
11,
SILVER
)

textLabel.Size = UDim2.new(1, 0, 0, 20)
textLabel.TextXAlignment = Enum.TextXAlignment.Left

local valueLabel = makeLabel(
row,
tostring(default) .. "%",
9,
GREY,
Enum.Font.GothamMedium
)

valueLabel.Position = UDim2.new(1, -40, 0, 0)
valueLabel.Size = UDim2.fromOffset(40, 20)
valueLabel.TextXAlignment = Enum.TextXAlignment.Right

local slider = Instance.new("Frame")

slider.BackgroundColor3 = PANEL3
slider.Size = UDim2.new(1, 0, 0, 5)
slider.Position = UDim2.fromOffset(0, 29)
slider.BorderSizePixel = 0
slider.Parent = row

corner(slider, 3)

local fill = Instance.new("Frame")

fill.BackgroundColor3 = State.AccentColor
fill.Size = UDim2.new(default / 100, 0, 1, 0)
fill.BorderSizePixel = 0
fill.Parent = slider

corner(fill, 3)

addGlow(fill, State.AccentColor, 10, 0.7)

connect(slider.InputBegan, function(input)
if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
return
end

local mouse = player:GetMouse()

local relative = math.clamp(
(mouse.X - slider.AbsolutePosition.X)
/ math.max(slider.AbsoluteSize.X, 1),
0,
1
)

local value = math.floor(relative * 100)

valueLabel.Text = tostring(value) .. "%"

quickTween(fill, 0.12, {
Size = UDim2.new(relative, 0, 1, 0)
})

playSound(clickSound)
end)
end

--============================================================
-- HOME
--============================================================

pageTitle(
homePage,
"Home",
"Main controls and quick actions"
)

local homeMain = createCard(
homePage,
UDim2.fromOffset(24, 82),
UDim2.new(0.47, -28, 0, 280),
"MAIN"
)

createToggle(homeMain, 48, "Enabled", true)
createToggle(homeMain, 84, "Movement", false)
createToggle(homeMain, 120, "Auto Jump", false)
createToggle(homeMain, 156, "Sprint", true)
createToggle(homeMain, 192, "Fast Actions", false)

local homeOther = createCard(
homePage,
UDim2.new(0.47, 4, 0, 82),
UDim2.new(0.53, -28, 0, 280),
"OTHER"
)

createToggle(homeOther, 48, "Option One", true)
createToggle(homeOther, 84, "Option Two", false)
createToggle(homeOther, 120, "Option Three", true)
createToggle(homeOther, 156, "Option Four", false)
createToggle(homeOther, 192, "Notifications", true)

--============================================================
-- VISUALS
--============================================================

pageTitle(
visualsPage,
"Visuals",
"Interface appearance and display settings"
)

local visualsDisplay = createCard(
visualsPage,
UDim2.fromOffset(24, 82),
UDim2.new(0.47, -28, 0, 300),
"DISPLAY"
)

createToggle(visualsDisplay, 48, "Interface Effects", true)
createToggle(visualsDisplay, 84, "Animated Gradient", true)
createToggle(visualsDisplay, 120, "Extra Details", false)
createToggle(visualsDisplay, 156, "Compact Mode", false)
createSlider(visualsDisplay, 198, "Interface Opacity", 90)

local visualsAppearance = createCard(
visualsPage,
UDim2.new(0.47, 4, 0, 82),
UDim2.new(0.53, -28, 0, 300),
"APPEARANCE"
)

createDropdown(
visualsAppearance,
48,
"Theme",
{"Dark", "Light", "Steel"},
"Dark"
)

createDropdown(
visualsAppearance,
84,
"Accent",
{"Silver", "White", "Blue"},
"Silver"
)

createDropdown(
visualsAppearance,
120,
"Scale",
{"80%", "90%", "100%", "110%", "120%"},
"100%"
)

createToggle(visualsAppearance, 162, "Blur", false)
createToggle(visualsAppearance, 198, "Shadows", true)

--============================================================
-- SETTINGS
--============================================================

pageTitle(
settingsPage,
"Settings",
"General interface preferences"
)

local settingsGeneral = createCard(
settingsPage,
UDim2.fromOffset(24, 82),
UDim2.new(0.47, -28, 0, 300),
"GENERAL"
)

createToggle(settingsGeneral, 48, "Enabled", true)
createToggle(settingsGeneral, 84, "Animations", true)
createToggle(settingsGeneral, 120, "Sounds", true)
createToggle(settingsGeneral, 156, "Auto Save", true)

createDropdown(
settingsGeneral,
198,
"Language",
{"English", "Spanish", "French"},
"English"
)

local settingsInterface = createCard(
settingsPage,
UDim2.new(0.47, 4, 0, 82),
UDim2.new(0.53, -28, 0, 300),
"INTERFACE"
)

createDropdown(
settingsInterface,
48,
"Font",
{"Gotham", "SourceSans", "Arial"},
"Gotham"
)

createDropdown(
settingsInterface,
84,
"Layout",
{"Compact", "Standard", "Wide"},
"Compact"
)

createToggle(settingsInterface, 126, "Show Profile", true)
createToggle(settingsInterface, 162, "Show Top Bar", true)
createToggle(settingsInterface, 198, "Remember Tab", true)

--============================================================
-- MISC
--============================================================

pageTitle(
miscPage,
"Misc",
"Utility and interface options"
)

local miscUtility = createCard(
miscPage,
UDim2.fromOffset(24, 82),
UDim2.new(0.47, -28, 0, 300),
"UTILITY"
)

createToggle(miscUtility, 48, "Notifications", true)
createToggle(miscUtility, 84, "Debug Mode", false)
createToggle(miscUtility, 120, "Performance Mode", false)
createToggle(miscUtility, 156, "Developer Options", false)

createDropdown(
miscUtility,
198,
"Priority",
{"Normal", "High", "Low"},
"Normal"
)

local miscOther = createCard(
miscPage,
UDim2.new(0.47, 4, 0, 82),
UDim2.new(0.53, -28, 0, 300),
"OTHER"
)

createToggle(miscOther, 48, "Extra Information", false)
createToggle(miscOther, 84, "Compact Labels", true)
createToggle(miscOther, 120, "Experimental", false)

createDropdown(
miscOther,
162,
"UI Scale",
{"80%", "90%", "100%", "110%", "120%"},
"100%"
)

--============================================================
-- FIXED TOP NAVIGATION
--============================================================

local navigation = Instance.new("Frame")

navigation.Name = "BubbleNavigation"
navigation.AnchorPoint = Vector2.new(0.5, 0)
navigation.Position = UDim2.fromScale(0.5, 0.015)
navigation.Size = UDim2.fromOffset(500, 56)
navigation.BackgroundColor3 = DARKER
navigation.BorderSizePixel = 0
navigation.ZIndex = 500
navigation.Parent = gui

corner(navigation, 9)
stroke(navigation, BORDER)

local navGlow = addGlow(
navigation,
Color3.fromRGB(100, 115, 145),
30,
0.9
)

if navGlow then
navGlow.ZIndex = 499
end

local navLayout = Instance.new("UIListLayout")

navLayout.FillDirection = Enum.FillDirection.Horizontal
navLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
navLayout.VerticalAlignment = Enum.VerticalAlignment.Center
navLayout.Padding = UDim.new(0, 5)
navLayout.Parent = navigation

local navPadding = Instance.new("UIPadding")
navPadding.PaddingLeft = UDim.new(0, 7)
navPadding.PaddingRight = UDim.new(0, 7)
navPadding.Parent = navigation

local navButtons = {}

local function createNavButton(name, icon)
local button = Instance.new("TextButton")

button.Name = name
button.Size = UDim2.fromOffset(91, 42)
button.BackgroundColor3 = DARK
button.Text = ""
button.AutoButtonColor = false
button.BorderSizePixel = 0
button.ZIndex = 501
button.Parent = navigation

corner(button, 6)
addShine(button)

local iconLabel = makeLabel(
button,
icon,
16,
LIGHTGREY,
Enum.Font.GothamBold
)

iconLabel.Position = UDim2.fromOffset(7, 0)
iconLabel.Size = UDim2.fromOffset(26, 42)

local textLabel = makeLabel(
button,
name,
9,
LIGHTGREY,
Enum.Font.GothamBold
)

textLabel.Position = UDim2.fromOffset(32, 0)
textLabel.Size = UDim2.new(1, -36, 1, 0)
textLabel.TextXAlignment = Enum.TextXAlignment.Left

navButtons[name] = {
Button = button,
Icon = iconLabel,
Text = textLabel
}

connect(button.MouseEnter, function()
if State.CurrentTab ~= name then
quickTween(button, 0.12, {
BackgroundColor3 = HOVER
})
end

animateShine(button)
playSound(hoverSound)
end)

connect(button.MouseLeave, function()
if State.CurrentTab ~= name then
quickTween(button, 0.12, {
BackgroundColor3 = DARK
})
end
end)

return button
end

local navHub = createNavButton("Hub", "●")
local navConsole = createNavButton("Console", "▣")
local navSettings = createNavButton("Settings", "⚙")
local navPlayers = createNavButton("Players", "♟")
local navUnload = createNavButton("Unload", "×")

--============================================================
-- NAV PAGES
--============================================================

local navPages = Instance.new("Frame")

navPages.Name = "NavigationPages"
navPages.BackgroundTransparency = 1
navPages.Size = UDim2.fromOffset(700, 500)
navPages.AnchorPoint = Vector2.new(0.5, 0)
navPages.Position = UDim2.new(0.5, 0, 0, 82)
navPages.ZIndex = 300
navPages.Visible = false
navPages.Parent = gui

local function createNavPage(name)
local page = Instance.new("Frame")

page.Name = name
page.BackgroundColor3 = DARKER
page.Size = UDim2.fromScale(1, 1)
page.BorderSizePixel = 0
page.Visible = false
page.ZIndex = 301
page.Parent = navPages

corner(page, 9)
stroke(page, BORDER)

addGlow(
page,
Color3.fromRGB(80, 90, 115),
25,
0.94
)

return page
end

local consolePage = createNavPage("Console")
local appearancePage = createNavPage("Appearance")
local playersPage = createNavPage("Players")

local function createNavTitle(parent, titleText, subtitleText)
local t = makeLabel(
parent,
titleText,
20,
WHITE,
Enum.Font.GothamBold
)

t.Position = UDim2.fromOffset(22, 18)
t.Size = UDim2.new(1, -44, 0, 28)
t.TextXAlignment = Enum.TextXAlignment.Left

local s = makeLabel(
parent,
subtitleText,
10,
GREY
)

s.Position = UDim2.fromOffset(23, 47)
s.Size = UDim2.new(1, -46, 0, 18)
s.TextXAlignment = Enum.TextXAlignment.Left
end

--============================================================
-- CONSOLE
--============================================================

createNavTitle(
consolePage,
"Bubbles Console",
"Local interface command console"
)

local consoleOutput = Instance.new("ScrollingFrame")

consoleOutput.BackgroundColor3 = Color3.fromRGB(6, 7, 9)
consoleOutput.Position = UDim2.fromOffset(20, 76)
consoleOutput.Size = UDim2.new(1, -40, 1, -140)
consoleOutput.BorderSizePixel = 0
consoleOutput.ScrollBarThickness = 3
consoleOutput.ZIndex = 302
consoleOutput.Parent = consolePage

corner(consoleOutput, 6)

local consoleLayout = Instance.new("UIListLayout")
consoleLayout.Padding = UDim.new(0, 3)
consoleLayout.Parent = consoleOutput

local consolePadding = Instance.new("UIPadding")
consolePadding.PaddingTop = UDim.new(0, 10)
consolePadding.PaddingBottom = UDim.new(0, 10)
consolePadding.PaddingLeft = UDim.new(0, 10)
consolePadding.PaddingRight = UDim.new(0, 10)
consolePadding.Parent = consoleOutput

connect(
consoleLayout:GetPropertyChangedSignal("AbsoluteContentSize"),
function()
consoleOutput.CanvasSize = UDim2.new(
0,
0,
0,
consoleLayout.AbsoluteContentSize.Y + 20
)
end
)

local function consolePrint(text, level)
local line = Instance.new("TextLabel")

line.BackgroundTransparency = 1
line.TextXAlignment = Enum.TextXAlignment.Left
line.TextYAlignment = Enum.TextYAlignment.Center
line.Size = UDim2.new(1, 0, 0, 20)
line.TextSize = 10
line.Font = Enum.Font.Code
line.ZIndex = 303
line.Text = os.date("%H:%M:%S")
.. " "
.. tostring(text)

if level == "error" then
line.TextColor3 = Color3.fromRGB(220, 150, 150)
elseif level == "warn" then
line.TextColor3 = Color3.fromRGB(220, 200, 140)
else
line.TextColor3 = LIGHTGREY
end

line.Parent = consoleOutput
end

consolePrint("Bubbles Console initialized.", "system")
consolePrint("Type 'help' for commands.", "system")

local consoleInput = Instance.new("TextBox")

consoleInput.BackgroundColor3 = PANEL2
consoleInput.TextColor3 = WHITE
consoleInput.PlaceholderColor3 = GREY
consoleInput.PlaceholderText = "Enter command..."
consoleInput.Text = ""
consoleInput.TextSize = 11
consoleInput.Font = Enum.Font.Code
consoleInput.ClearTextOnFocus = false
consoleInput.Position = UDim2.fromOffset(20, 445)
consoleInput.Size = UDim2.new(1, -40, 0, 40)
consoleInput.BorderSizePixel = 0
consoleInput.ZIndex = 303
consoleInput.Parent = consolePage

corner(consoleInput, 5)
stroke(consoleInput, BORDER_SOFT)

connect(consoleInput.MouseEnter, function()
quickTween(consoleInput, 0.12, {
BackgroundColor3 = Color3.fromRGB(21, 22, 27)
})
end)

connect(consoleInput.MouseLeave, function()
quickTween(consoleInput, 0.12, {
BackgroundColor3 = PANEL2
})
end)

local function runConsoleCommand(command)
command = tostring(command or "")
command = command:gsub("^%s+", "")
command = command:gsub("%s+$`", "")
command = string.lower(command)

if command == "" then
return
end

consolePrint("> " .. command)

table.insert(State.ConsoleHistory, command)
State.ConsoleIndex = #State.ConsoleHistory + 1

if command == "help" then
consolePrint("Available commands:")
consolePrint("help")
consolePrint("clear")
consolePrint("hub")
consolePrint("hide")
consolePrint("players")
consolePrint("settings")
consolePrint("version")

elseif command == "clear" then
for _, child in ipairs(consoleOutput:GetChildren()) do
if child:IsA("TextLabel") then
child:Destroy()
end
end

elseif command == "hub" then
State.CurrentTab = "Hub"
navPages.Visible = false
hub.Visible = true
hubShadow.Visible = true

elseif command == "hide" then
hub.Visible = false
hubShadow.Visible = false

elseif command == "players" then
State.CurrentTab = "Players"
navPages.Visible = true
consolePage.Visible = false
appearancePage.Visible = false
playersPage.Visible = true

elseif command == "settings" then
State.CurrentTab = "Settings"
navPages.Visible = true
consolePage.Visible = false
playersPage.Visible = false
appearancePage.Visible = true

elseif command == "version" then
consolePrint("BubblesHook V2 - premium UI build.", "system")

else
consolePrint(
"Unknown command. Type 'help'.",
"warn"
)
end
end

connect(
consoleInput.FocusLost,
function(enterPressed)
if enterPressed then
local command = consoleInput.Text
consoleInput.Text = ""
runConsoleCommand(command)
end
end
)

--============================================================
-- APPEARANCE
--============================================================

createNavTitle(
appearancePage,
"Appearance",
"Customize the Bubbles interface"
)

local appearanceLeft = Instance.new("Frame")

appearanceLeft.BackgroundColor3 = PANEL
appearanceLeft.Position = UDim2.fromOffset(20, 78)
appearanceLeft.Size = UDim2.fromOffset(300, 350)
appearanceLeft.BorderSizePixel = 0
appearanceLeft.Parent = appearancePage

corner(appearanceLeft, 7)
stroke(appearanceLeft, BORDER_SOFT)

local appearanceTitle = makeLabel(
appearanceLeft,
"COLOR SETTINGS",
10,
SILVER,
Enum.Font.GothamBold
)

appearanceTitle.Position = UDim2.fromOffset(15, 13)
appearanceTitle.Size = UDim2.new(1, -30, 0, 20)
appearanceTitle.TextXAlignment = Enum.TextXAlignment.Left

local colorWheel = Instance.new("Frame")

colorWheel.BackgroundColor3 = PANEL3
colorWheel.Position = UDim2.fromOffset(55, 48)
colorWheel.Size = UDim2.fromOffset(190, 190)
colorWheel.BorderSizePixel = 0
colorWheel.Parent = appearanceLeft

corner(colorWheel, 999)
stroke(colorWheel, BORDER)

local wheelDots = {}

for i = 0, 71 do
local angle = (i / 72) * math.pi * 2
local radius = 82

local dot = Instance.new("TextButton")

dot.Text = ""
dot.AutoButtonColor = false
dot.BackgroundColor3 = Color3.fromHSV(i / 72, 1, 1)
dot.Size = UDim2.fromOffset(12, 12)
dot.AnchorPoint = Vector2.new(0.5, 0.5)

dot.Position = UDim2.new(
0.5,
math.cos(angle) * radius,
0.5,
math.sin(angle) * radius
)

dot.BorderSizePixel = 0
dot.Parent = colorWheel

corner(dot, 999)

connect(dot.MouseEnter, function()
quickTween(dot, 0.1, {
Size = UDim2.fromOffset(16, 16)
})
end)

connect(dot.MouseLeave, function()
quickTween(dot, 0.1, {
Size = UDim2.fromOffset(12, 12)
})
end)

table.insert(wheelDots, dot)
end

local colorPreview = Instance.new("Frame")

colorPreview.BackgroundColor3 = State.AccentColor
colorPreview.Size = UDim2.fromOffset(64, 64)
colorPreview.AnchorPoint = Vector2.new(0.5, 0.5)
colorPreview.Position = UDim2.fromScale(0.5, 0.5)
colorPreview.BorderSizePixel = 0
colorPreview.Parent = colorWheel

corner(colorPreview, 999)
stroke(colorPreview, WHITE, 2, 0.25)

local previewGlow = addGlow(
colorPreview,
State.AccentColor,
25,
0.55
)

if previewGlow then
previewGlow.ZIndex = 0
end

local function setAccentColor(color)
State.AccentColor = color

colorPreview.BackgroundColor3 = color

if previewGlow then
previewGlow.ImageColor3 = color
end

for name, data in pairs(navButtons) do
data.Icon.TextColor3 =
State.CurrentTab == name
and color
or LIGHTGREY
end

for _, data in pairs(tabs) do
data.Indicator.BackgroundColor3 = color

if data.Button:GetAttribute("Selected") then
data.Icon.TextColor3 = color
end
end
end

for i, dot in ipairs(wheelDots) do
connect(dot.MouseButton1Click, function()
setAccentColor(
Color3.fromHSV(
(i - 1) / 72,
1,
1
)
)

playSound(clickSound)
pulse(colorPreview, 4, 0.12)
end)
end

local accentColorButton = Instance.new("TextButton")

accentColorButton.BackgroundColor3 = State.AccentColor
accentColorButton.Text = "ACCENT COLOR"
accentColorButton.TextColor3 = DARK
accentColorButton.TextSize = 9
accentColorButton.Font = Enum.Font.GothamBold
accentColorButton.Position = UDim2.fromOffset(20, 255)
accentColorButton.Size = UDim2.fromOffset(260, 36)
accentColorButton.BorderSizePixel = 0
accentColorButton.AutoButtonColor = false
accentColorButton.Parent = appearanceLeft

corner(accentColorButton, 5)
addShine(accentColorButton)

connect(accentColorButton.MouseEnter, function()
quickTween(accentColorButton, 0.12, {
BackgroundColor3 = WHITE
})

animateShine(accentColorButton)
playSound(hoverSound)
end)

connect(accentColorButton.MouseLeave, function()
quickTween(accentColorButton, 0.12, {
BackgroundColor3 = State.AccentColor
})
end)

connect(accentColorButton.MouseButton1Click, function()
setAccentColor(Color3.fromRGB(235, 238, 245))
playSound(clickSound)
end)

--============================================================
-- PLAYERS
--============================================================

createNavTitle(
playersPage,
"Players",
"Select a player to spectate"
)

local playerList = Instance.new("ScrollingFrame")

playerList.BackgroundColor3 = PANEL
playerList.Position = UDim2.fromOffset(20, 78)
playerList.Size = UDim2.fromOffset(300, 350)
playerList.BorderSizePixel = 0
playerList.ScrollBarThickness = 3
playerList.Parent = playersPage

corner(playerList, 7)
stroke(playerList, BORDER_SOFT)

local playerLayout = Instance.new("UIListLayout")
playerLayout.Padding = UDim.new(0, 5)
playerLayout.SortOrder = Enum.SortOrder.Name
playerLayout.Parent = playerList

local playerPadding = Instance.new("UIPadding")
playerPadding.PaddingTop = UDim.new(0, 8)
playerPadding.PaddingLeft = UDim.new(0, 8)
playerPadding.PaddingRight = UDim.new(0, 8)
playerPadding.Parent = playerList

local selectedPanel = Instance.new("Frame")

selectedPanel.BackgroundColor3 = PANEL
selectedPanel.Position = UDim2.fromOffset(340, 78)
selectedPanel.Size = UDim2.new(1, -360, 0, 350)
selectedPanel.BorderSizePixel = 0
selectedPanel.Parent = playersPage

corner(selectedPanel, 7)
stroke(selectedPanel, BORDER_SOFT)

local selectedGlow = addGlow(
selectedPanel,
State.AccentColor,
25,
0.94
)

if selectedGlow then
selectedGlow.ZIndex = 0
end

local selectedTitle = makeLabel(
selectedPanel,
"NO PLAYER SELECTED",
15,
WHITE,
Enum.Font.GothamBold
)

selectedTitle.Position = UDim2.fromOffset(18, 18)
selectedTitle.Size = UDim2.new(1, -36, 0, 24)
selectedTitle.TextXAlignment = Enum.TextXAlignment.Left

local selectedStatus = makeLabel(
selectedPanel,
"Select a player from the list.",
10,
GREY
)

selectedStatus.Position = UDim2.fromOffset(18, 47)
selectedStatus.Size = UDim2.new(1, -36, 0, 35)
selectedStatus.TextXAlignment = Enum.TextXAlignment.Left

local spectateButton = Instance.new("TextButton")

spectateButton.BackgroundColor3 = State.AccentColor
spectateButton.Text = "SPECTATE"
spectateButton.TextColor3 = DARK
spectateButton.TextSize = 10
spectateButton.Font = Enum.Font.GothamBold
spectateButton.Position = UDim2.fromOffset(18, 105)
spectateButton.Size = UDim2.new(1, -36, 0, 38)
spectateButton.BorderSizePixel = 0
spectateButton.AutoButtonColor = false
spectateButton.Parent = selectedPanel

corner(spectateButton, 5)
addShine(spectateButton)

local stopSpectateButton = Instance.new("TextButton")

stopSpectateButton.BackgroundColor3 = PANEL3
stopSpectateButton.Text = "STOP SPECTATING"
stopSpectateButton.TextColor3 = LIGHTGREY
stopSpectateButton.TextSize = 10
stopSpectateButton.Font = Enum.Font.GothamBold
stopSpectateButton.Position = UDim2.fromOffset(18, 150)
stopSpectateButton.Size = UDim2.new(1, -36, 0, 38)
stopSpectateButton.BorderSizePixel = 0
stopSpectateButton.AutoButtonColor = false
stopSpectateButton.Parent = selectedPanel

corner(stopSpectateButton, 5)
addShine(stopSpectateButton)

local safeInfo = makeLabel(
selectedPanel,
"Local/client-side player controls.",
9,
GREY
)

safeInfo.Position = UDim2.fromOffset(18, 210)
safeInfo.Size = UDim2.new(1, -36, 0, 40)
safeInfo.TextWrapped = true
safeInfo.TextXAlignment = Enum.TextXAlignment.Left

local function setupActionButton(button, normal, hover)
connect(button.MouseEnter, function()
quickTween(button, 0.12, {
BackgroundColor3 = hover
})

animateShine(button)
playSound(hoverSound)
end)

connect(button.MouseLeave, function()
quickTween(button, 0.12, {
BackgroundColor3 = normal
})
end)
end

setupActionButton(
spectateButton,
State.AccentColor,
WHITE
)

setupActionButton(
stopSpectateButton,
PANEL3,
HOVER
)

--============================================================
-- PLAYER LIST
--============================================================

local function clearPlayerList()
for _, child in ipairs(playerList:GetChildren()) do
if child:IsA("TextButton") then
child:Destroy()
end
end
end

local function selectPlayer(target)
State.SelectedPlayer = target

if target then
selectedTitle.Text = target.DisplayName

selectedStatus.Text =
"@" .. target.Name
.. "\nUserId: "
.. tostring(target.UserId)
else
selectedTitle.Text = "NO PLAYER SELECTED"
selectedStatus.Text = "Select a player from the list."
end
end

local function refreshPlayerList()
clearPlayerList()

for _, target in ipairs(Players:GetPlayers()) do
local button = Instance.new("TextButton")

button.Name = target.Name
button.BackgroundColor3 = PANEL2
button.Text = ""
button.Size = UDim2.new(1, 0, 0, 48)
button.BorderSizePixel = 0
button.AutoButtonColor = false
button.Parent = playerList

corner(button, 5)
addShine(button)

local avatarCircle = Instance.new("Frame")

avatarCircle.BackgroundColor3 = PANEL3
avatarCircle.Size = UDim2.fromOffset(32, 32)
avatarCircle.Position = UDim2.fromOffset(8, 8)
avatarCircle.BorderSizePixel = 0
avatarCircle.Parent = button

corner(avatarCircle, 999)

local avatarText = makeLabel(
avatarCircle,
string.sub(target.DisplayName, 1, 1):upper(),
12,
WHITE,
Enum.Font.GothamBold
)

avatarText.Size = UDim2.fromScale(1, 1)

local nameLabel = makeLabel(
button,
target.DisplayName,
10,
WHITE,
Enum.Font.GothamMedium
)

nameLabel.Position = UDim2.fromOffset(50, 6)
nameLabel.Size = UDim2.new(1, -58, 0, 18)
nameLabel.TextXAlignment = Enum.TextXAlignment.Left
nameLabel.TextTruncate = Enum.TextTruncate.AtEnd

local username = makeLabel(
button,
"@" .. target.Name,
8,
GREY
)

username.Position = UDim2.fromOffset(50, 25)
username.Size = UDim2.new(1, -58, 0, 15)
username.TextXAlignment = Enum.TextXAlignment.Left

connect(button.MouseEnter, function()
quickTween(button, 0.1, {
BackgroundColor3 = HOVER
})

animateShine(button)
playSound(hoverSound)
end)

connect(button.MouseLeave, function()
quickTween(button, 0.1, {
BackgroundColor3 = PANEL2
})
end)

connect(button.MouseButton1Click, function()
selectPlayer(target)
playSound(clickSound)
pulse(button, 2, 0.1)
end)
end

playerList.CanvasSize = UDim2.new(
0,
0,
0,
playerLayout.AbsoluteContentSize.Y + 20
)
end

connect(Players.PlayerAdded, function()
task.wait()
refreshPlayerList()
end)

connect(Players.PlayerRemoving, function(target)
if State.SelectedPlayer == target then
selectPlayer(nil)
end

task.wait()
refreshPlayerList()
end)

refreshPlayerList()

--============================================================
-- SPECTATE
--============================================================

local function stopSpectating()
State.Spectating = false

local camera = workspace.CurrentCamera

if camera then
camera.CameraType = Enum.CameraType.Custom

local character = player.Character

if character then
local humanoid =
character:FindFirstChildOfClass("Humanoid")

if humanoid then
camera.CameraSubject = humanoid
end
end
end

spectateButton.Text = "SPECTATE"
end

connect(spectateButton.MouseButton1Click, function()
local target = State.SelectedPlayer

if not target then
selectedStatus.Text = "No player selected."
return
end

if target == player then
selectedStatus.Text = "You are already viewing yourself."
return
end

local character = target.Character

if not character then
selectedStatus.Text = "Character unavailable."
return
end

local humanoid =
character:FindFirstChildOfClass("Humanoid")

if not humanoid then
selectedStatus.Text = "Humanoid unavailable."
return
end

local camera = workspace.CurrentCamera

State.Spectating = true

camera.CameraType = Enum.CameraType.Custom
camera.CameraSubject = humanoid

spectateButton.Text = "SPECTATING"

playSound(clickSound)
pulse(spectateButton, 3, 0.12)
end)

connect(stopSpectateButton.MouseButton1Click, function()
stopSpectating()
playSound(clickSound)
end)

--============================================================
-- NAVIGATION
--============================================================

local function updateNavButtons()
for name, data in pairs(navButtons) do
local selected = State.CurrentTab == name

quickTween(data.Button, 0.18, {
BackgroundColor3 = selected
and Color3.fromRGB(27, 29, 36)
or DARK
})

data.Icon.TextColor3 =
selected and State.AccentColor or LIGHTGREY

data.Text.TextColor3 =
selected and WHITE or LIGHTGREY
end
end

local function hideNavPages()
consolePage.Visible = false
appearancePage.Visible = false
playersPage.Visible = false
end

local function openNavPage(name)
if State.Unloaded then
return
end

State.CurrentTab = name
updateNavButtons()

if name == "Hub" then
hideNavPages()

navPages.Visible = false

hub.Visible = true
hubShadow.Visible = true

elseif name == "Console" then
hideNavPages()

consolePage.Visible = true
navPages.Visible = true

hub.Visible = false
hubShadow.Visible = false

elseif name == "Settings" then
hideNavPages()

appearancePage.Visible = true
navPages.Visible = true

hub.Visible = false
hubShadow.Visible = false

elseif name == "Players" then
hideNavPages()

playersPage.Visible = true
navPages.Visible = true

refreshPlayerList()

hub.Visible = false
hubShadow.Visible = false
end
end

connect(navHub.MouseButton1Click, function()
playSound(clickSound)
openNavPage("Hub")
end)

connect(navConsole.MouseButton1Click, function()
playSound(clickSound)
openNavPage("Console")
end)

connect(navSettings.MouseButton1Click, function()
playSound(clickSound)
openNavPage("Settings")
end)

connect(navPlayers.MouseButton1Click, function()
playSound(clickSound)
openNavPage("Players")
end)

--============================================================
-- OPEN BUTTON
--============================================================

local openButton = Instance.new("TextButton")

openButton.Name = "OpenButton"
openButton.AnchorPoint = Vector2.new(1, 1)
openButton.BackgroundColor3 = PANEL
openButton.Text = ""
openButton.Size = UDim2.fromOffset(52, 52)
openButton.Position = UDim2.new(1, -22, 1, -22)
openButton.BorderSizePixel = 0
openButton.AutoButtonColor = false
openButton.Visible = false
openButton.ZIndex = 450
openButton.Parent = gui

corner(openButton, 999)
stroke(openButton, BORDER)

local openGlow = addGlow(
openButton,
GLOW,
30,
0.62
)

if openGlow then
openGlow.ZIndex = 449
end

gradient(openButton)

local openLogo = createLogo(
openButton,
UDim2.fromOffset(9, 9),
UDim2.fromOffset(34, 34)
)

openLogo.ZIndex = 451

for _, child in ipairs(openLogo:GetDescendants()) do
if child:IsA("GuiObject") then
child.ZIndex = 451
end
end

connect(openButton.MouseEnter, function()
quickTween(openButton, 0.15, {
Size = UDim2.fromOffset(58, 58)
})

quickTween(openLogo, 0.15, {
Position = UDim2.fromOffset(12, 12)
})

playSound(hoverSound)
end)

connect(openButton.MouseLeave, function()
quickTween(openButton, 0.15, {
Size = UDim2.fromOffset(52, 52)
})

quickTween(openLogo, 0.15, {
Position = UDim2.fromOffset(9, 9)
})
end)

connect(openButton.MouseButton1Click, function()
playSound(clickSound)

openButton.Visible = false
openNavPage("Hub")
end)

--============================================================
-- WINDOW CONTROLS
--============================================================

local minimized = false
local maximized = false

local normalSize = UDim2.fromOffset(760, 470)
local normalPosition = UDim2.fromScale(0.5, 0.5)

connect(minButton.MouseButton1Click, function()
playSound(clickSound)

if minimized then
minimized = false

quickTween(hub, 0.25, {
Size = normalSize
})

else
minimized = true

quickTween(hub, 0.25, {
Size = UDim2.fromOffset(760, 68)
})
end
end)

connect(maxButton.MouseButton1Click, function()
playSound(clickSound)

if maximized then
maximized = false

quickTween(hub, 0.25, {
Size = normalSize,
Position = normalPosition
})

quickTween(hubShadow, 0.25, {
Size = UDim2.fromOffset(775, 485),
Position = normalPosition
})

else
maximized = true

quickTween(hub, 0.25, {
Size = UDim2.fromScale(0.88, 0.82),
Position = UDim2.fromScale(0.5, 0.5)
})

quickTween(hubShadow, 0.25, {
Size = UDim2.fromScale(0.89, 0.83),
Position = UDim2.fromScale(0.5, 0.5)
})
end
end)

connect(closeButton.MouseButton1Click, function()
playSound(clickSound)

hub.Visible = false
hubShadow.Visible = false

openButton.Visible = true

pulse(openButton, 3, 0.15)
end)

--============================================================
-- DRAGGING
--============================================================

local dragging = false
local dragStart
local startPos

connect(topBar.InputBegan, function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 then
dragging = true
dragStart = input.Position
startPos = hub.Position
end
end)

connect(topBar.InputEnded, function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 then
dragging = false
end
end)

connect(UserInputService.InputChanged, function(input)
if not dragging then
return
end

if input.UserInputType ~= Enum.UserInputType.MouseMovement then
return
end

local delta = input.Position - dragStart

hub.Position = UDim2.new(
startPos.X.Scale,
startPos.X.Offset + delta.X,
startPos.Y.Scale,
startPos.Y.Offset + delta.Y
)

hubShadow.Position = hub.Position
end)

--============================================================
-- PREMIUM IDLE ANIMATIONS
--============================================================

task.spawn(function()
while gui.Parent and not State.Unloaded do
if State.Animations then
topGradient.Offset = Vector2.new(
math.sin(os.clock() * 0.35) * 0.22,
0
)

logo.Rotation =
math.sin(os.clock() * 1.2) * 1.5

keyLogo.Rotation =
math.sin(os.clock() * 1.1) * 1.5

if openButton.Visible then
openLogo.Rotation =
math.sin(os.clock() * 2) * 3
end

for _, info in ipairs(keyParticles) do
local object = info.Object

if object and object.Parent then
local x = object.Position.X.Scale
local y = object.Position.Y.Scale

y -= info.Speed

if y < -0.05 then
y = 1.05
x = math.random()
end

object.Position = UDim2.fromScale(
x + math.sin(os.clock() + info.Phase) * 0.0002,
y
)
end
end
end

RunService.RenderStepped:Wait()
end
end)

--============================================================
-- REVEAL SEQUENCE
--============================================================

local function resetRevealBubbles()
for _, bubble in ipairs(revealBubbles) do
local size = math.random(6, 48)

bubble.Size = UDim2.fromOffset(size, size)

bubble.BackgroundTransparency =
math.random(92, 98) / 100

bubble.Position = UDim2.fromScale(
math.random(-10, 110) / 100,
1.02 + math.random(-10, 120) / 100
)
end
end

local function runRevealSequence()
if State.Unloaded then
return
end

revealOverlay.Visible = true
revealOverlay.BackgroundTransparency = 0

resetRevealBubbles()

revealLogo.Position =
UDim2.new(0.5, -110, 1.3, 0)

revealLogo.Size =
UDim2.fromOffset(220, 220)

playBubbleSound()

for i, bubble in ipairs(revealBubbles) do
local delayTime =
math.random(0, 140) / 100

local riseTime =
math.random(100, 240) / 100

task.delay(delayTime, function()
if State.Unloaded or not bubble.Parent then
return
end

if i % 3 == 0 then
playBubbleSound()
end

local targetX =
bubble.Position.X.Scale
+ math.random(-18, 18) / 100

tween(
bubble,
TweenInfo.new(
riseTime,
Enum.EasingStyle.Quad,
Enum.EasingDirection.Out
),
{
Position = UDim2.fromScale(
targetX,
-math.random(5, 35) / 100
),

BackgroundTransparency = 1
}
)
end)
end

task.wait(0.35)

local logoRise = tween(
revealLogo,
TweenInfo.new(
1.5,
Enum.EasingStyle.Quint,
Enum.EasingDirection.Out
),
{
Position = UDim2.new(
0.5,
-110,
0.5,
-110
)
}
)

task.wait(0.2)

playBubbleSound()

if logoRise then
logoRise.Completed:Wait()
end

task.wait(0.15)

playBubbleSound()

local expandTween = tween(
revealLogo,
TweenInfo.new(
1.2,
Enum.EasingStyle.Quint,
Enum.EasingDirection.InOut
),
{
Position = UDim2.new(
0.5,
-500,
0.5,
-500
),

Size = UDim2.fromOffset(
1000,
1000
)
}
)

tween(
revealOverlay,
TweenInfo.new(
1.15,
Enum.EasingStyle.Quad,
Enum.EasingDirection.Out
),
{
BackgroundTransparency = 1
}
)

if expandTween then
expandTween.Completed:Wait()
end

revealOverlay.Visible = false

hubShadow.Visible = true
hub.Visible = true

hub.Size = UDim2.fromOffset(680, 420)

tween(
hub,
TweenInfo.new(
0.4,
Enum.EasingStyle.Back,
Enum.EasingDirection.Out
),
{
Size = normalSize
}
)

tween(
hubShadow,
TweenInfo.new(
0.4,
Enum.EasingStyle.Quad,
Enum.EasingDirection.Out
),
{
Size = UDim2.fromOffset(775, 485)
}
)

playSound(clickSound)
end

--============================================================
-- LOADING
--============================================================

local function runLoadingSequence()
if State.Unloaded then
return
end

loadingOverlay.Visible = true
loadingOverlay.BackgroundTransparency = 0

barFill.Size = UDim2.new(0, 0, 1, 0)
percent.Text = "0%"

gearHolder.Rotation = 0

local loadingTime = 5.5
local startTime = os.clock()
local lastStep = -1

local progressConnection

progressConnection = RunService.RenderStepped:Connect(function()
if State.Unloaded or not loadingOverlay.Visible then
if progressConnection then
progressConnection:Disconnect()
end

return
end

local elapsed = os.clock() - startTime

local alpha = math.clamp(
elapsed / loadingTime,
0,
1
)

local currentPercent =
math.floor(alpha * 100)

barFill.Size =
UDim2.new(alpha, 0, 1, 0)

percent.Text =
tostring(currentPercent) .. "%"

local step =
math.floor(currentPercent / 4)

if step > lastStep then
lastStep = step

if currentPercent > 0
and currentPercent < 100 then

playBubbleSound()

if step % 5 == 0 then
task.delay(0.07, playBubbleSound)
end
end
end

if alpha >= 1 then
progressConnection:Disconnect()
end
end)

task.spawn(function()
while loadingOverlay.Visible
and not State.Unloaded do

local rotationTween = tween(
gearHolder,
TweenInfo.new(
1.25,
Enum.EasingStyle.Linear
),
{
Rotation =
gearHolder.Rotation + 360
}
)

if rotationTween then
rotationTween.Completed:Wait()
else
break
end
end
end)

task.wait(loadingTime + 0.2)

if State.Unloaded then
return
end

percent.Text = "100%"

playBubbleSound()
playBubbleSound()

task.wait(0.35)

loadingOverlay.Visible = false

runRevealSequence()
end

--============================================================
-- KEY SYSTEM
--============================================================

local unlocked = false

local function shakeKeyCard()
local original = keyCard.Position

for i = 1, 6 do
local direction =
i % 2 == 0 and 8 or -8

local t = tween(
keyCard,
TweenInfo.new(0.035),
{
Position =
original
+ UDim2.fromOffset(
direction,
0
)
}
)

if t then
t.Completed:Wait()
end
end

tween(
keyCard,
TweenInfo.new(0.08),
{
Position = original
}
)
end

local function attemptUnlock()
if unlocked or State.Unloaded then
return
end

playSound(clickSound)

local enteredKey = tostring(keyInput.Text or "")

enteredKey = enteredKey:gsub("^%s+", "")
enteredKey = enteredKey:gsub("%s+`$", "")
enteredKey = string.lower(enteredKey)

print("[BubblesHook] Key entered:", enteredKey)

if enteredKey == "bubbles" then
unlocked = true
State.Unlocked = true

statusLabel.Text = "ACCESS GRANTED"
statusLabel.TextColor3 = State.AccentColor

keyInput.TextEditable = false
unlockButton.Active = false

pulse(keyCard, 5, 0.15)

task.wait(0.25)

tween(
keyOverlay,
TweenInfo.new(
0.5,
Enum.EasingStyle.Quad,
Enum.EasingDirection.Out
),
{
BackgroundTransparency = 1
}
)

tween(
keyCard,
TweenInfo.new(
0.45,
Enum.EasingStyle.Quad,
Enum.EasingDirection.In
),
{
Position = UDim2.fromScale(
0.5,
0.54
)
}
)

task.wait(0.5)

if State.Unloaded then
return
end

keyOverlay.Visible = false

runLoadingSequence()

else
statusLabel.Text = "INVALID KEY"
statusLabel.TextColor3 =
Color3.fromRGB(
210,
150,
150
)

playBubbleSound()
shakeKeyCard()

task.wait(0.4)

if not State.Unloaded and not unlocked then
statusLabel.Text = "WAITING FOR KEY"
statusLabel.TextColor3 = GREY
end
end
end

connect(
unlockButton.Activated,
attemptUnlock
)

connect(
keyInput.FocusLost,
function(enterPressed)
if enterPressed and not unlocked then
attemptUnlock()
end
end
)

--============================================================
-- UNLOAD
--============================================================

local function unload()
if State.Unloaded then
return
end

State.Unloaded = true

stopSpectating()

disconnectAll()

for _, sound in ipairs(sfxFolder:GetChildren()) do
if sound:IsA("Sound") then
sound:Stop()
end
end

local fade = Instance.new("Frame")

fade.BackgroundColor3 = BLACK
fade.BackgroundTransparency = 1
fade.Size = UDim2.fromScale(1, 1)
fade.ZIndex = 9999
fade.Parent = gui

tween(
fade,
TweenInfo.new(
0.3,
Enum.EasingStyle.Quad
),
{
BackgroundTransparency = 0
}
)

task.delay(0.32, function()
if gui and gui.Parent then
gui:Destroy()
end

if sfxFolder and sfxFolder.Parent then
sfxFolder:Destroy()
end
end)
end

connect(
navUnload.Activated,
function()
playSound(clickSound)
unload()
end
)

--============================================================
-- STARTUP
--============================================================

for name, page in pairs(pages) do
page.Visible = name == "Home"
end

for name, data in pairs(tabs) do
local selected = name == "Home"

data.Button:SetAttribute(
"Selected",
selected
)

data.Indicator.Visible = selected

data.Button.BackgroundColor3 =
selected and PANEL3 or DARK

data.Icon.TextColor3 =
selected and State.AccentColor or LIGHTGREY

data.Text.TextColor3 =
selected and WHITE or LIGHTGREY
end

State.CurrentTab = "Hub"

updateNavButtons()

navigation.Visible = false
hub.Visible = false
hubShadow.Visible = false
openButton.Visible = false

keyOverlay.Visible = true
loadingOverlay.Visible = false
revealOverlay.Visible = false

print("")
print("BubblesHook V2 Premium started")
print("Key system ready")
print("Expected key: bubbles")
print("Premium UI effects enabled")
print("")
