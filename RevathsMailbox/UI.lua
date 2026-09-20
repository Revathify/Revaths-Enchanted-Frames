local _, ns = ...
local C = ns.colors
local MAX_RECEIVE = ATTACHMENTS_MAX_RECEIVE or 16
local MAX_SEND = ATTACHMENTS_MAX_SEND or 12

local THEMES = {
    modern = {
        bg = { 0.035, 0.047, 0.071, 0.98 }, panel = { 0.065, 0.082, 0.115, 0.98 },
        panelAlt = { 0.09, 0.11, 0.15, 1 }, input = { 0.025, 0.034, 0.052, 1 },
        button = { 0.09, 0.11, 0.15, 1 }, parchment = { 0.065, 0.082, 0.115, 0.98 },
        letter = { 0.025, 0.034, 0.052, 1 }, ink = { 0.90, 0.93, 0.96, 1 },
        border = { 0.18, 0.23, 0.31, 1 }, accent = { 0.18, 0.72, 0.78, 1 },
        accent2 = { 0.40, 0.86, 0.69, 1 }, text = { 0.90, 0.93, 0.96, 1 },
        muted = { 0.56, 0.62, 0.70, 1 }, danger = { 0.92, 0.33, 0.38, 1 },
    },
    classic = {
        bg = { 0.030, 0.024, 0.014, 1 }, panel = { 0.040, 0.030, 0.016, 1 },
        panelAlt = { 0.020, 0.016, 0.009, 1 }, input = { 0.025, 0.018, 0.009, 1 },
        button = { 0.36, 0.030, 0.012, 1 }, parchment = { 0.76, 0.48, 0.20, 1 },
        letter = { 0.76, 0.48, 0.20, 1 }, ink = { 0.10, 0.040, 0.012, 1 },
        border = { 0.58, 0.48, 0.30, 1 }, accent = { 0.96, 0.72, 0.20, 1 },
        accent2 = { 0.98, 0.83, 0.43, 1 }, text = { 1.00, 0.92, 0.72, 1 },
        muted = { 0.76, 0.64, 0.43, 1 }, danger = { 0.96, 0.35, 0.24, 1 },
    },
}

local MODERN_PALETTES = {
    midnight = {
        label = "Midnight Cyan", bg = { 0.035, 0.047, 0.071 }, panel = { 0.065, 0.082, 0.115 },
        panelAlt = { 0.09, 0.11, 0.15 }, input = { 0.025, 0.034, 0.052 }, button = { 0.09, 0.11, 0.15 },
        border = { 0.18, 0.23, 0.31 }, accent = { 0.18, 0.72, 0.78 }, accent2 = { 0.40, 0.86, 0.69 },
    },
    arcane = {
        label = "Arcane Violet", bg = { 0.050, 0.035, 0.080 }, panel = { 0.085, 0.060, 0.125 },
        panelAlt = { 0.115, 0.080, 0.165 }, input = { 0.035, 0.025, 0.060 }, button = { 0.105, 0.070, 0.155 },
        border = { 0.30, 0.22, 0.42 }, accent = { 0.66, 0.40, 0.94 }, accent2 = { 0.91, 0.55, 0.96 },
    },
    emerald = {
        label = "Emerald Grove", bg = { 0.025, 0.060, 0.050 }, panel = { 0.045, 0.095, 0.075 },
        panelAlt = { 0.060, 0.125, 0.100 }, input = { 0.018, 0.046, 0.038 }, button = { 0.052, 0.115, 0.090 },
        border = { 0.16, 0.34, 0.27 }, accent = { 0.18, 0.78, 0.53 }, accent2 = { 0.55, 0.91, 0.48 },
    },
    crimson = {
        label = "Crimson Ember", bg = { 0.070, 0.030, 0.035 }, panel = { 0.115, 0.048, 0.055 },
        panelAlt = { 0.150, 0.064, 0.070 }, input = { 0.052, 0.022, 0.026 }, button = { 0.135, 0.052, 0.058 },
        border = { 0.38, 0.18, 0.20 }, accent = { 0.91, 0.28, 0.34 }, accent2 = { 1.00, 0.62, 0.34 },
    },
    royal = {
        label = "Royal Blue", bg = { 0.025, 0.040, 0.080 }, panel = { 0.042, 0.070, 0.125 },
        panelAlt = { 0.060, 0.095, 0.165 }, input = { 0.018, 0.032, 0.062 }, button = { 0.052, 0.082, 0.145 },
        border = { 0.16, 0.28, 0.46 }, accent = { 0.25, 0.57, 0.96 }, accent2 = { 0.55, 0.78, 1.00 },
    },
    graphite = {
        label = "Graphite Gray", bg = { 0.050, 0.052, 0.058 }, panel = { 0.080, 0.083, 0.092 },
        panelAlt = { 0.110, 0.114, 0.125 }, input = { 0.035, 0.037, 0.043 }, button = { 0.105, 0.109, 0.120 },
        border = { 0.28, 0.29, 0.32 }, accent = { 0.62, 0.65, 0.70 }, accent2 = { 0.84, 0.86, 0.89 },
    },
}

local FONT_OPTIONS = {
    friz = { label = "Friz Quadrata", path = STANDARD_TEXT_FONT, flags = "" },
    frizOutline = { label = "Friz Outlined", path = STANDARD_TEXT_FONT, flags = "OUTLINE" },
    arial = { label = "Arial Narrow", path = "Fonts\\ARIALN.TTF", flags = "" },
    arialOutline = { label = "Arial Outlined", path = "Fonts\\ARIALN.TTF", flags = "OUTLINE" },
    morpheus = { label = "Morpheus", path = "Fonts\\MORPHEUS.TTF", flags = "" },
    morpheusOutline = { label = "Morpheus Outlined", path = "Fonts\\MORPHEUS.TTF", flags = "OUTLINE" },
    skurri = { label = "Skurri", path = "Fonts\\SKURRI.TTF", flags = "" },
    skurriOutline = { label = "Skurri Outlined", path = "Fonts\\SKURRI.TTF", flags = "OUTLINE" },
}
local PALETTE_ORDER = { "midnight", "arcane", "emerald", "crimson", "royal", "graphite" }
local FONT_ORDER = { "friz", "frizOutline", "arial", "arialOutline", "morpheus", "morpheusOutline", "skurri", "skurriOutline" }

local function DiscoverSharedMediaFonts()
    if not LibStub then return end
    local media = LibStub("LibSharedMedia-3.0", true)
    if not media or not media.HashTable then return end
    local registered = media:HashTable("font")
    if type(registered) ~= "table" then return end
    local knownPaths = {}
    for _, font in pairs(FONT_OPTIONS) do
        if font.flags == "" and type(font.path) == "string" then knownPaths[string.lower(font.path)] = true end
    end
    local names = {}
    for name, path in pairs(registered) do
        if type(name) == "string" and type(path) == "string" and path ~= "" and not knownPaths[string.lower(path)] then
            names[#names + 1] = name
        end
    end
    table.sort(names, function(a, b) return string.lower(a) < string.lower(b) end)
    for _, name in ipairs(names) do
        local key = "shared:" .. name
        local loweredPath = string.lower(registered[name])
        if not FONT_OPTIONS[key] and not knownPaths[loweredPath] then
            local label = name
            local loweredName = string.lower(name)
            if loweredName == "avant garde" or string.find(loweredPath, "naowh", 1, true) then
                label = "Naowh / " .. name
            end
            FONT_OPTIONS[key] = { label = label, path = registered[name], flags = "", shared = true }
            FONT_ORDER[#FONT_ORDER + 1] = key
            knownPaths[loweredPath] = true
        end
    end
end

local styledFrames, styledText, classicInkText, fontObjects = {}, {}, {}, {}
local savedSkin = type(RevathsMailboxDB) == "table" and type(RevathsMailboxDB.settings) == "table" and RevathsMailboxDB.settings.skin or "modern"
if not THEMES[savedSkin] then savedSkin = "modern" end
local activeSkin = "modern"

local function SavedSetting(key, fallback)
    local settings = ns.db and ns.db.settings
    if not settings and type(RevathsMailboxDB) == "table" then settings = RevathsMailboxDB.settings end
    local value = settings and settings[key]
    return value == nil and fallback or value
end

local function SetColor(target, source)
    for i = 1, 4 do target[i] = source[i] end
end

local function LoadPalette(skin)
    local palette = THEMES[skin] or THEMES.modern
    for role, color in pairs(palette) do
        if C[role] then SetColor(C[role], color) else C[role] = { unpack(color) } end
    end
    if skin == "modern" then
        local paletteKey = SavedSetting("palette", "midnight")
        local selected = MODERN_PALETTES[paletteKey] or MODERN_PALETTES.midnight
        for role, color in pairs(selected) do
            if role ~= "label" and C[role] then
                C[role][1], C[role][2], C[role][3] = color[1], color[2], color[3]
            end
        end
        C.parchment[1], C.parchment[2], C.parchment[3] = C.panel[1], C.panel[2], C.panel[3]
        C.letter[1], C.letter[2], C.letter[3] = C.input[1], C.input[2], C.input[3]
        local opacity = math.max(0.55, math.min(1, tonumber(SavedSetting("modernOpacity", 0.96)) or 0.96))
        C.bg[4] = opacity
        C.panel[4], C.parchment[4] = math.min(1, opacity + 0.02), math.min(1, opacity + 0.02)
        C.panelAlt[4], C.button[4] = math.min(1, opacity + 0.04), math.min(1, opacity + 0.04)
        C.input[4], C.letter[4] = math.min(1, opacity + 0.04), math.min(1, opacity + 0.04)
    end
    activeSkin = skin
end

LoadPalette(activeSkin)

local function ColorRole(color, fallback)
    for _, role in ipairs({ "bg", "panel", "panelAlt", "input", "button", "parchment", "letter", "ink", "border", "accent", "accent2", "text", "muted", "danger" }) do
        if color == C[role] then return role end
    end
    return fallback
end

local function SetFrameBackdrop(frame, role)
    if activeSkin == "classic" and (role == "bg" or role == "panel" or role == "parchment" or role == "letter") then
        local edgeSize = role == "bg" and 32 or role == "panel" and 22 or 18
        local inset = role == "bg" and 11 or role == "panel" and 7 or 6
        frame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = edgeSize,
            insets = { left = inset, right = inset, top = inset, bottom = inset },
        })
        if not frame.revathsClassicTexture then
            frame.revathsClassicTexture = frame:CreateTexture(nil, "BACKGROUND", nil, 1)
            frame.revathsClassicTexture:SetPoint("TOPLEFT", 6, -6)
            frame.revathsClassicTexture:SetPoint("BOTTOMRIGHT", -6, 6)
        end
        if role == "parchment" or role == "letter" then
            frame.revathsClassicTexture:SetTexture("Interface\\QuestFrame\\QuestBG")
            frame.revathsClassicTexture:SetTexCoord(0, 0.5859375, 0, 0.65625)
            frame.revathsClassicTexture:SetVertexColor(1, 0.94, 0.78, 0.88)
        else
            frame.revathsClassicTexture:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Background")
            frame.revathsClassicTexture:SetTexCoord(0, 1, 0, 1)
            frame.revathsClassicTexture:SetVertexColor(0.40, 0.32, 0.20, 0.42)
        end
        frame.revathsClassicTexture:Show()
    elseif activeSkin == "classic" and role == "button" and frame.SetNormalTexture then
        frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        frame:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
        frame:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")
        frame:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight", "ADD")
        if frame:GetNormalTexture() then
            frame:GetNormalTexture():SetTexCoord(0, 0.625, 0, 0.6875)
            frame:GetNormalTexture():SetVertexColor(0.78, 0.20, 0.08, 1)
        end
        if frame:GetPushedTexture() then
            frame:GetPushedTexture():SetTexCoord(0, 0.625, 0, 0.6875)
            frame:GetPushedTexture():SetVertexColor(0.58, 0.09, 0.035, 1)
        end
        if frame:GetHighlightTexture() then
            frame:GetHighlightTexture():SetTexCoord(0, 0.625, 0, 0.6875)
            frame:GetHighlightTexture():SetVertexColor(1, 0.72, 0.18, 0.55)
        end
        frame:SetBackdropColor(0, 0, 0, 0)
        frame:SetBackdropBorderColor(0, 0, 0, 0)
        if frame.revathsClassicTexture then frame.revathsClassicTexture:Hide() end
        return
    else
        local outer = role == "bg"
        frame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = outer and 16 or 12,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        if role == "button" and frame.SetNormalTexture then
            local normal = frame:GetNormalTexture()
            local pushed = frame:GetPushedTexture()
            local highlight = frame:GetHighlightTexture()
            if normal then normal:SetTexture(nil) end
            if pushed then pushed:SetTexture(nil) end
            if highlight then highlight:SetTexture(nil) end
        end
        if frame.revathsClassicTexture then frame.revathsClassicTexture:Hide() end
    end
    frame:SetBackdropColor(unpack(C[role] or C.panel))
    frame:SetBackdropBorderColor(unpack(C.border))
end

local function ApplyBackdrop(frame, color, role)
    role = role or ColorRole(color, "panel")
    styledFrames[frame] = role
    SetFrameBackdrop(frame, role)
end

local function ClassicInk(object, modernRole)
    classicInkText[object] = modernRole or "text"
end

local function Font(parent, size, color, justify)
    local text = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetFont(STANDARD_TEXT_FONT, size or 12, "")
    text:SetTextColor(unpack(color or C.text))
    text:SetJustifyH(justify or "LEFT")
    local role = color and ColorRole(color, nil) or "text"
    if role then styledText[text] = role end
    fontObjects[text] = true
    return text
end

local function Button(parent, label, width, height)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(width or 100, height or 30)
    ApplyBackdrop(b, C.button, "button")
    b.label = Font(b, 12, C.text, "CENTER")
    b.label:SetPoint("CENTER")
    b.label:SetText(label)
    b:SetScript("OnEnter", function(self) if activeSkin ~= "classic" then self:SetBackdropBorderColor(unpack(C.accent)) end end)
    b:SetScript("OnLeave", function(self) if activeSkin ~= "classic" then self:SetBackdropBorderColor(unpack(C.border)) end end)
    b:SetScript("OnMouseDown", function(self) self.label:SetPoint("CENTER", 1, -1) end)
    b:SetScript("OnMouseUp", function(self) self.label:SetPoint("CENTER") end)
    return b
end

local function AddDropdownArrow(button)
    local arrow = button:CreateTexture(nil, "ARTWORK")
    arrow:SetSize(17, 17); arrow:SetPoint("RIGHT", -9, 0)
    local atlasLoaded = arrow.SetAtlas and pcall(arrow.SetAtlas, arrow, "common-dropdown-icon")
    if not atlasLoaded then arrow:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up") end
    button.label:ClearAllPoints(); button.label:SetPoint("LEFT", 10, 0); button.label:SetPoint("RIGHT", -31, 0); button.label:SetJustifyH("CENTER")
    button.dropdownArrow = arrow
end

local function EditBox(parent, multiline)
    local box = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
    ApplyBackdrop(box, C.input, "input")
    box:SetFont(STANDARD_TEXT_FONT, 13, "")
    fontObjects[box] = true
    box:SetTextColor(unpack(C.text))
    box:SetAutoFocus(false)
    box:SetMultiLine(multiline or false)
    box:SetTextInsets(10, 10, 7, 7)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    return box
end

local function ApplySelectedFont()
    local fontKey = SavedSetting("font", "friz")
    local option = FONT_OPTIONS[fontKey] or FONT_OPTIONS.friz
    for object in pairs(fontObjects) do
        if object and object.GetFont and object.SetFont then
            local _, size, flags = object:GetFont()
            local selectedFlags = option.flags
            if selectedFlags == nil then selectedFlags = flags or "" end
            local ok, loaded = pcall(object.SetFont, object, option.path, size or 12, selectedFlags)
            if not ok or loaded == false then object:SetFont(STANDARD_TEXT_FONT, size or 12, flags or "") end
        end
    end
end

local function HexColor(color)
    return string.format("ff%02x%02x%02x", math.floor(color[1] * 255 + 0.5), math.floor(color[2] * 255 + 0.5), math.floor(color[3] * 255 + 0.5))
end

local frame = CreateFrame("Frame", "RevathsMailboxFrame", UIParent, "BackdropTemplate")
ns.frame = frame
frame:SetSize(940, 680)
frame:SetPoint("CENTER")
frame:SetFrameStrata("HIGH")
frame:SetClampedToScreen(true)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
ApplyBackdrop(frame, C.bg)
frame:Hide()

local glow = frame:CreateTexture(nil, "BACKGROUND")
glow:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], 0.12)
glow:SetPoint("TOPLEFT", 4, -4)
glow:SetPoint("TOPRIGHT", -4, -4)
glow:SetHeight(72)

local classicTitlePlate = frame:CreateTexture(nil, "ARTWORK", nil, 1)
classicTitlePlate:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
classicTitlePlate:SetSize(590, 84)
classicTitlePlate:SetPoint("TOP", 0, 14)
classicTitlePlate:Hide()

local headerIcon = frame:CreateTexture(nil, "ARTWORK")
headerIcon:SetSize(46, 46)
headerIcon:SetPoint("TOPLEFT", 20, -13)
headerIcon:SetTexture("Interface\\AddOns\\RevathsMailbox\\Media\\IconSmall")

local title = Font(frame, 23, C.text)
title:SetPoint("TOPLEFT", 76, -18)
title:SetText("REVATH'S |cff2eb8c7ENCHANTED MAILBOX|r")
local subtitle = Font(frame, 11, C.muted)
subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 1, -4)
subtitle:SetText("MAILBOX & CHARACTER COURIER")

local headerLine = frame:CreateTexture(nil, "ARTWORK")
headerLine:SetHeight(2)
headerLine:SetPoint("TOPLEFT", 22, -69)
headerLine:SetPoint("RIGHT", -22, 0)
headerLine:SetColorTexture(unpack(C.accent))
headerLine:SetAlpha(0.45)

local status = Font(frame, 11, C.muted, "RIGHT")
status:SetPoint("TOPRIGHT", -54, -28)
status:SetWidth(260)
status:SetText("")

local close = Button(frame, "×", 30, 30)
close:SetPoint("TOPRIGHT", -14, -14)
close.label:SetFont(STANDARD_TEXT_FONT, 20, "")
close:SetScript("OnClick", function() ns:Hide(false) end)

local headerSettings = Button(frame, "Settings", 76, 30)
headerSettings:SetPoint("RIGHT", close, "LEFT", -7, 0)
headerSettings:SetScript("OnClick", function()
    ns:SelectTab(frame.currentTab == "Settings" and "Inbox" or "Settings")
end)
status:ClearAllPoints()
status:SetPoint("RIGHT", headerSettings, "LEFT", -10, 0)

frame.tabs = {}
frame.pages = {}
local tabDefinitions = {
    { label = "Inbox", page = "Inbox" },
    { label = "New Mail", page = "Compose" },
    { label = "Contacts", page = "Contacts" },
    { label = "Alts", page = "Alts" },
}
for i, definition in ipairs(tabDefinitions) do
    local tab = Button(frame, definition.label, 112, 32)
    tab:SetPoint("TOPLEFT", 24 + ((i - 1) * 120), -83)
    tab.pageName = definition.page
    frame.tabs[definition.page] = tab
end

local content = CreateFrame("Frame", nil, frame)
content:SetPoint("TOPLEFT", 24, -126)
content:SetPoint("BOTTOMRIGHT", -24, 46)

local footer = Font(frame, 11, C.muted)
footer:SetPoint("BOTTOMLEFT", 24, 17)
footer:SetText("Inbox data is saved when each character visits a mailbox.")

local function ApplyGeometry(skin)
    local isClassic = skin == "classic"
    frame:SetSize(isClassic and 930 or 940, isClassic and 670 or 680)

    glow:SetHeight(isClassic and 94 or 72)
    classicTitlePlate:SetShown(isClassic)
    headerLine:SetShown(not isClassic)

    headerIcon:ClearAllPoints()
    headerIcon:SetSize(isClassic and 48 or 46, isClassic and 48 or 46)
    headerIcon:SetPoint("TOPLEFT", isClassic and 24 or 20, isClassic and -24 or -13)

    title:ClearAllPoints()
    title:SetWidth(isClassic and 360 or 420)
    title:SetJustifyH(isClassic and "CENTER" or "LEFT")
    if isClassic then title:SetPoint("TOP", frame, "TOP", 0, -2)
    else title:SetPoint("TOPLEFT", 76, -18) end

    subtitle:ClearAllPoints()
    subtitle:SetWidth(isClassic and 420 or 360)
    subtitle:SetJustifyH(isClassic and "CENTER" or "LEFT")
    if isClassic then subtitle:SetPoint("TOP", frame, "TOP", 0, -40)
    else subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 1, -4) end

    status:ClearAllPoints()
    status:SetWidth(isClassic and 180 or 260)
    close:ClearAllPoints()
    close:SetSize(isClassic and 34 or 30, isClassic and 34 or 30)
    close:SetPoint("TOPRIGHT", isClassic and -24 or -14, isClassic and -23 or -14)
    headerSettings:ClearAllPoints()
    headerSettings:SetSize(isClassic and 82 or 76, isClassic and 34 or 30)
    headerSettings:SetPoint("RIGHT", close, "LEFT", -7, 0)
    status:SetPoint("RIGHT", headerSettings, "LEFT", -10, 0)

    for i, definition in ipairs(tabDefinitions) do
        local tab = frame.tabs[definition.page]
        tab:ClearAllPoints()
        tab:SetSize(isClassic and 124 or 112, isClassic and 34 or 32)
        local x = isClassic and (205 + ((i - 1) * 132)) or (24 + ((i - 1) * 120))
        tab:SetPoint("TOPLEFT", x, isClassic and -99 or -83)
    end

    content:ClearAllPoints()
    content:SetPoint("TOPLEFT", isClassic and 36 or 24, isClassic and -148 or -126)
    content:SetPoint("BOTTOMRIGHT", isClassic and -36 or -24, isClassic and 58 or 46)
    footer:ClearAllPoints()
    footer:SetPoint("BOTTOMLEFT", isClassic and 38 or 24, isClassic and 23 or 17)

    if frame.composeSidebarButtons then
        for _, button in ipairs(frame.composeSidebarButtons) do button:SetWidth(isClassic and 206 or 238) end
    end
    if frame.materialMenu then
        frame.materialMenu:SetWidth(isClassic and 226 or 258)
        for _, button in ipairs(frame.materialMenu.buttons or {}) do button:SetWidth(isClassic and 206 or 238) end
    end
end

local compose

function ns:SetStatus(message, isError)
    status:SetText(message or "")
    status:SetTextColor(unpack(isError and C.danger or C.accent2))
end

function ns:ApplySkin(skin)
    skin = THEMES[skin] and skin or "modern"
    LoadPalette(skin)
    if self.db then self.db.settings.skin = skin end
    ApplyGeometry(skin)
    for object, role in pairs(styledFrames) do
        if object and object.SetBackdropColor then
            SetFrameBackdrop(object, role)
        end
    end
    for object, role in pairs(styledText) do
        if object and role and C[role] then object:SetTextColor(unpack(C[role])) end
    end
    for object, modernRole in pairs(classicInkText) do
        if object and object.SetTextColor then object:SetTextColor(unpack(skin == "classic" and C.ink or C[modernRole])) end
    end
    ApplySelectedFont()
    glow:SetColorTexture(C.accent[1], C.accent[2], C.accent[3], skin == "classic" and 0.20 or 0.12)
    headerLine:SetColorTexture(unpack(C.accent))
    if skin == "classic" then
        title:SetText("REVATH'S |cfff5b833ENCHANTED MAILBOX|r")
        subtitle:SetText("MAILBOX & CHARACTER COURIER  ·  CLASSIC")
    else
        title:SetText("REVATH'S |c" .. HexColor(C.accent) .. "ENCHANTED MAILBOX|r")
        subtitle:SetText("MAILBOX & CHARACTER COURIER")
    end
    if compose and compose.body then compose.body:SetTextColor(unpack(skin == "classic" and C.ink or C.text)) end
    if frame.currentTab then self:SelectTab(frame.currentTab) end
end

function ns:ApplySkinSafe(skin)
    local ok, message = pcall(self.ApplySkin, self, skin)
    if ok then return true end
    if self.db then self.db.settings.skin = "modern" end
    activeSkin = "modern"
    pcall(self.ApplySkin, self, "modern")
    self.lastSkinError = tostring(message)
    return false
end

function ns:SelectTab(name)
    frame.currentTab = name
    for tabName, page in pairs(frame.pages) do page:SetShown(tabName == name) end
    for tabName, tab in pairs(frame.tabs) do
        if tabName == name then
            tab:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.22)
            tab:SetBackdropBorderColor(unpack(C.accent))
            if activeSkin == "classic" and tab:GetNormalTexture() then
                tab:GetNormalTexture():SetVertexColor(0.76, 0.53, 0.10, 1)
                tab.label:SetTextColor(unpack(C.accent2))
            end
        else
            tab:SetBackdropColor(unpack(C.panelAlt))
            tab:SetBackdropBorderColor(unpack(C.border))
            if activeSkin == "classic" and tab:GetNormalTexture() then
                tab:GetNormalTexture():SetVertexColor(0.78, 0.20, 0.08, 1)
                tab.label:SetTextColor(unpack(C.text))
            end
        end
    end
    local settingsSelected = name == "Settings"
    headerSettings:SetBackdropColor(unpack(settingsSelected and C.buttonHover or C.button))
    headerSettings:SetBackdropBorderColor(unpack(settingsSelected and C.accent or C.border))
    headerSettings.label:SetText("Settings")
    if self.mailOpen then SetSendMailShowing(name == "Compose") end
    if name == "Inbox" then self:RefreshInbox()
    elseif name == "Compose" then self:RefreshCompose()
    elseif name == "Contacts" then self:RefreshContacts()
    elseif name == "Alts" then self:RefreshAlts()
    elseif name == "Settings" then self:RefreshSettings() end
end

for name, tab in pairs(frame.tabs) do
    tab:SetScript("OnClick", function() ns:SelectTab(name) end)
end

-- Inbox
local inbox = CreateFrame("Frame", nil, content)
inbox:SetAllPoints()
frame.pages.Inbox = inbox

local inboxList = CreateFrame("Frame", nil, inbox, "BackdropTemplate")
inboxList:SetPoint("TOPLEFT")
inboxList:SetPoint("BOTTOMLEFT")
inboxList:SetWidth(490)
ApplyBackdrop(inboxList)

local inboxHeader = Font(inboxList, 13, C.muted)
inboxHeader:SetPoint("TOPLEFT", 16, -14)
inboxHeader:SetText("LOADED MAIL")

local refresh = Button(inboxList, "Refresh", 78, 26)
refresh:SetPoint("TOPRIGHT", -12, -9)
refresh:SetScript("OnClick", function() CheckInbox(); ns:SetStatus("Checking for mail...") end)

local openAll = Button(inboxList, "Open all", 90, 26)
openAll:SetPoint("RIGHT", refresh, "LEFT", -6, 0)

local scroll = CreateFrame("ScrollFrame", nil, inboxList, "UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", 10, -45)
scroll:SetPoint("BOTTOMRIGHT", -30, 10)
local scrollChild = CreateFrame("Frame", nil, scroll)
scrollChild:SetSize(440, 1)
scroll:SetScrollChild(scrollChild)
inbox.scrollChild = scrollChild
inbox.rows = {}

local detail = CreateFrame("Frame", nil, inbox, "BackdropTemplate")
detail:SetPoint("TOPLEFT", inboxList, "TOPRIGHT", 12, 0)
detail:SetPoint("BOTTOMRIGHT")
ApplyBackdrop(detail, C.parchment, "parchment")
inbox.detail = detail

local detailFrom = Font(detail, 12, C.accent)
detailFrom:SetPoint("TOPLEFT", 16, -16)
detailFrom:SetPoint("TOPRIGHT", -16, -16)
local detailSubject = Font(detail, 17, C.text)
detailSubject:SetPoint("TOPLEFT", detailFrom, "BOTTOMLEFT", 0, -8)
detailSubject:SetPoint("TOPRIGHT", -16, -40)
detailSubject:SetWordWrap(true)
local detailMeta = Font(detail, 11, C.muted)
detailMeta:SetPoint("TOPLEFT", detailSubject, "BOTTOMLEFT", 0, -7)
local body = Font(detail, 12, C.text)
body:SetPoint("TOPLEFT", detailMeta, "BOTTOMLEFT", 0, -14)
body:SetPoint("TOPRIGHT", -16, -100)
body:SetHeight(190)
body:SetWordWrap(true)
body:SetJustifyV("TOP")
inbox.detailFrom, inbox.detailSubject, inbox.detailMeta, inbox.body = detailFrom, detailSubject, detailMeta, body
ClassicInk(detailFrom, "accent")
ClassicInk(detailSubject, "text")
ClassicInk(detailMeta, "muted")
ClassicInk(body, "text")

local copyPanel = CreateFrame("Frame", nil, detail, "BackdropTemplate")
copyPanel:SetPoint("TOPLEFT", 8, -8)
copyPanel:SetPoint("BOTTOMRIGHT", -8, 52)
copyPanel:SetFrameLevel(detail:GetFrameLevel() + 20)
ApplyBackdrop(copyPanel, C.panel, "panel")
copyPanel:Hide()
local copyTitle = Font(copyPanel, 15, C.text)
copyTitle:SetPoint("TOPLEFT", 14, -14)
copyTitle:SetText("COPY MESSAGE TEXT")
local copyHelp = Font(copyPanel, 11, C.muted)
copyHelp:SetPoint("TOPLEFT", copyTitle, "BOTTOMLEFT", 0, -6)
copyHelp:SetText("Select any part, or press Ctrl+A then Ctrl+C to copy the full message.")
local copyBox = EditBox(copyPanel, true)
copyBox:SetPoint("TOPLEFT", 12, -62)
copyBox:SetPoint("BOTTOMRIGHT", -12, 48)
copyBox:SetJustifyV("TOP")
copyBox:SetScript("OnEscapePressed", function(self) self:ClearFocus(); copyPanel:Hide() end)
ClassicInk(copyBox, "text")
local closeCopy = Button(copyPanel, "Close", 72, 28)
closeCopy:SetPoint("BOTTOMRIGHT", -12, 10)
closeCopy:SetScript("OnClick", function() copyBox:ClearFocus(); copyPanel:Hide() end)

local detailMoneyIcon = detail:CreateTexture(nil, "ARTWORK")
detailMoneyIcon:SetSize(30, 30)
detailMoneyIcon:SetPoint("BOTTOMLEFT", 16, 108)
detailMoneyIcon:SetTexture("Interface\\MoneyFrame\\UI-GoldIcon")
local detailMoneyLabel = Font(detail, 10, C.muted)
detailMoneyLabel:SetPoint("BOTTOMLEFT", 52, 132)
detailMoneyLabel:SetText("GOLD ATTACHED")
local detailMoneyValue = Font(detail, 18, { 1, 0.82, 0.18, 1 })
detailMoneyValue:SetPoint("BOTTOMLEFT", 52, 108)
detailMoneyIcon:Hide()
detailMoneyLabel:Hide()
detailMoneyValue:Hide()

inbox.attachments = {}
for i = 1, MAX_RECEIVE do
    local item = CreateFrame("Button", nil, detail, "BackdropTemplate")
    item:SetSize(38, 38)
    item:SetPoint("BOTTOMLEFT", 16 + ((i - 1) * 43), 58)
    ApplyBackdrop(item, C.panelAlt)
    item.icon = item:CreateTexture(nil, "ARTWORK")
    item.icon:SetPoint("TOPLEFT", 3, -3)
    item.icon:SetPoint("BOTTOMRIGHT", -3, 3)
    item.count = Font(item, 10, C.text, "RIGHT")
    item.count:SetPoint("BOTTOMRIGHT", -4, 3)
    item:Hide()
    inbox.attachments[i] = item
end

local function ClearInboxAttachments()
    for _, item in ipairs(inbox.attachments) do
        item:Hide()
        item.icon:SetTexture(nil)
        item.count:SetText("")
        item:SetScript("OnEnter", nil)
        item:SetScript("OnLeave", nil)
        item:SetScript("OnClick", nil)
    end
end

local takeAll = Button(detail, "Take contents", 108, 28)
takeAll:SetPoint("BOTTOMLEFT", 16, 15)
local replyMail = Button(detail, "Reply", 60, 28)
replyMail:SetPoint("LEFT", takeAll, "RIGHT", 4, 0)
local returnMail = Button(detail, "Return", 64, 28)
returnMail:SetPoint("LEFT", replyMail, "RIGHT", 4, 0)
local copyMail = Button(detail, "Copy", 56, 28)
copyMail:SetPoint("LEFT", returnMail, "RIGHT", 4, 0)
local deleteMail = Button(detail, "Delete", 64, 28)
deleteMail:SetPoint("LEFT", copyMail, "RIGHT", 4, 0)
deleteMail.label:SetTextColor(unpack(C.danger))
styledText[deleteMail.label] = "danger"
copyMail:SetScript("OnClick", function()
    if not inbox.selected then return end
    copyBox:SetText(body:GetText() or "")
    copyPanel:Show()
    copyBox:SetFocus()
    copyBox:HighlightText()
end)

inbox.openAll = { active = false, waiting = false, queued = false, processed = 0, checkAttempts = 0 }

local function SetOpeningAllState(enabled)
    if C_Mail and C_Mail.SetOpeningAll then C_Mail.SetOpeningAll(enabled) end
end

function ns:StopOpenAll(message, isError)
    local wasActive = inbox.openAll.active
    inbox.openAll.active = false
    inbox.openAll.waiting = false
    inbox.openAll.queued = false
    openAll.label:SetText("Open all")
    SetOpeningAllState(false)
    if message then self:SetStatus(message, isError) end
    return wasActive
end

local function QueueOpenAll(delay)
    if not inbox.openAll.active or inbox.openAll.queued then return end
    inbox.openAll.queued = true
    C_Timer.After(delay or 0.15, function()
        inbox.openAll.queued = false
        if inbox.openAll.active then ns:ContinueOpenAll() end
    end)
end

local function FindOpenableMail()
    local loaded, total = GetInboxNumItems()
    local skippedCOD = 0
    for index = 1, (loaded or 0) do
        local _, _, sender, _, money, cod, _, hasItem = GetInboxHeaderInfo(index)
        if sender and (cod or 0) > 0 then
            skippedCOD = skippedCOD + 1
        elseif sender and ((money or 0) > 0 or hasItem) then
            return index, skippedCOD, loaded or 0, total or loaded or 0
        end
    end
    return nil, skippedCOD, loaded or 0, total or loaded or 0
end

function ns:ContinueOpenAll()
    if not inbox.openAll.active then return end
    if not self.mailOpen then
        self:StopOpenAll("Open all stopped because the mailbox closed.")
        return
    end
    if inbox.openAll.waiting then return end
    if C_Mail and C_Mail.IsCommandPending and C_Mail.IsCommandPending() then
        QueueOpenAll(0.2)
        return
    end

    local index, skippedCOD, loaded, total = FindOpenableMail()
    if index then
        inbox.openAll.checkAttempts = 0
        inbox.openAll.waiting = true
        openAll.label:SetText("Stop")
        self:SetStatus(string.format("Opening mail... %d collected", inbox.openAll.processed))
        AutoLootMailItem(index)
        C_Timer.After(2, function()
            if inbox.openAll.active and inbox.openAll.waiting then
                inbox.openAll.waiting = false
                QueueOpenAll(0)
            end
        end)
        return
    end

    if loaded < total and inbox.openAll.checkAttempts < 3 and C_Mail and C_Mail.CanCheckInbox then
        inbox.openAll.checkAttempts = inbox.openAll.checkAttempts + 1
        local canCheck, seconds = C_Mail.CanCheckInbox()
        if canCheck then CheckInbox() end
        QueueOpenAll(math.max(0.2, tonumber(seconds) or 0.2))
        return
    end

    local processed = inbox.openAll.processed
    local message
    if processed > 0 then
        message = string.format("Collected contents from %d mail%s.", processed, processed == 1 and "" or "s")
    else
        message = "No attachments or money to collect."
    end
    if skippedCOD > 0 then message = message .. string.format(" Skipped %d COD mail%s.", skippedCOD, skippedCOD == 1 and "" or "s") end
    if loaded < total then message = message .. " Some remaining mail is not loaded yet; refresh and run Open all again." end
    self:StopOpenAll(message)
end

function ns:OnOpenAllMailEvent()
    if not inbox.openAll.active then return end
    if inbox.openAll.waiting then
        inbox.openAll.waiting = false
        inbox.openAll.processed = inbox.openAll.processed + 1
    end
    QueueOpenAll(0.2)
end

openAll:SetScript("OnClick", function()
    if inbox.openAll.active then
        ns:StopOpenAll(string.format("Open all stopped after %d mail%s.", inbox.openAll.processed, inbox.openAll.processed == 1 and "" or "s"))
        return
    end
    inbox.openAll.active = true
    inbox.openAll.waiting = false
    inbox.openAll.queued = false
    inbox.openAll.processed = 0
    inbox.openAll.checkAttempts = 0
    openAll.label:SetText("Stop")
    SetOpeningAllState(true)
    ns:SetStatus("Opening all mail...")
    ns:ContinueOpenAll()
end)

StaticPopupDialogs.REVATHSMAILBOX_DELETE = {
    text = "Delete this mail? This cannot be undone.", button1 = DELETE, button2 = CANCEL,
    OnAccept = function(_, data) if data then DeleteInboxItem(data) end end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}
StaticPopupDialogs.REVATHSMAILBOX_RETURN = {
    text = "Return this mail to its sender?", button1 = RETURN, button2 = CANCEL,
    OnAccept = function(_, data) if data then ReturnInboxItem(data) end end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}
StaticPopupDialogs.REVATHSMAILBOX_COD = {
    text = "This is COD mail. Taking its contents will pay the requested amount. Continue?", button1 = ACCEPT, button2 = CANCEL,
    OnAccept = function(_, data) if data then AutoLootMailItem(data) end end,
    timeout = 0, whileDead = true, hideOnEscape = true,
}

takeAll:SetScript("OnClick", function()
    if inbox.selected then
        if (inbox.selectedCOD or 0) > 0 then StaticPopup_Show("REVATHSMAILBOX_COD", nil, nil, inbox.selected)
        else AutoLootMailItem(inbox.selected) end
    end
end)
replyMail:SetScript("OnClick", function()
    if not inbox.selected then return end
    local _, _, sender, subject = GetInboxHeaderInfo(inbox.selected)
    if not sender then return end
    if compose.SetRecipient then compose:SetRecipient(sender) else compose.to:SetText(sender) end
    local prefix = MAIL_REPLY_PREFIX .. " "
    if string.sub(subject or "", 1, string.len(prefix)) ~= prefix then subject = prefix .. (subject or "") end
    compose.subject:SetText(subject)
    ns:SelectTab("Compose")
    compose.body:SetFocus()
end)
returnMail:SetScript("OnClick", function()
    if inbox.selected then StaticPopup_Show("REVATHSMAILBOX_RETURN", nil, nil, inbox.selected) end
end)
deleteMail:SetScript("OnClick", function()
    if inbox.selected then StaticPopup_Show("REVATHSMAILBOX_DELETE", nil, nil, inbox.selected) end
end)

function ns:SelectMessage(index, skipListRefresh)
    inbox.selected = index
    copyBox:ClearFocus()
    copyPanel:Hide()
    local _, _, sender, subject, money, cod, days, hasItem, wasRead, wasReturned, _, canReply = GetInboxHeaderInfo(index)
    if not sender then
        inbox.selected = nil
        inbox.selectedCOD = 0
        ClearInboxAttachments()
        detailMoneyIcon:Hide()
        detailMoneyLabel:Hide()
        detailMoneyValue:Hide()
        return
    end
    inbox.selectedCOD = cod or 0
    detailFrom:SetText("FROM  " .. sender)
    detailSubject:SetText(subject or "(No subject)")
    local pieces = { string.format("%.1f days left", days or 0) }
    if cod and cod > 0 then pieces[#pieces + 1] = "COD " .. ns:FormatMoney(cod) end
    detailMeta:SetText(table.concat(pieces, "  ·  "))
    local hasMoney = (money or 0) > 0
    detailMoneyIcon:SetShown(hasMoney)
    detailMoneyLabel:SetShown(hasMoney)
    detailMoneyValue:SetShown(hasMoney)
    detailMoneyValue:SetText(hasMoney and ns:FormatMoney(money) or "")
    local mailBody = GetInboxText(index)
    body:SetText((mailBody and mailBody ~= "") and mailBody or "No message body.")
    for slot, item in ipairs(inbox.attachments) do
        local mailIndex, attachmentSlot = index, slot
        local itemName, _, texture, count = GetInboxItem(mailIndex, attachmentSlot)
        item:SetShown(itemName ~= nil)
        if itemName then
            item.icon:SetTexture(texture)
            item.count:SetText((count or 1) > 1 and count or "")
            item:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetInboxItem(mailIndex, attachmentSlot)
                GameTooltip:Show()
            end)
            item:SetScript("OnLeave", GameTooltip_Hide)
            item:SetScript("OnClick", function()
                TakeInboxItem(mailIndex, attachmentSlot)
                if C_Timer and C_Timer.After then
                    C_Timer.After(0.15, function()
                        if inbox:IsShown() and inbox.selected then ns:RefreshInbox(inbox.selected) end
                    end)
                end
            end)
        else
            item.icon:SetTexture(nil)
            item.count:SetText("")
            item:SetScript("OnEnter", nil)
            item:SetScript("OnLeave", nil)
            item:SetScript("OnClick", nil)
        end
    end
    takeAll:SetEnabled((money or 0) > 0 or hasItem)
    replyMail:SetEnabled(canReply)
    returnMail:SetEnabled(not wasReturned and canReply)
    deleteMail:SetEnabled(true)
    if not skipListRefresh then self:RefreshInbox(index) end
end

function ns:RefreshInbox(keepSelection)
    if not inbox or not inbox:IsShown() then return end
    local loaded, total = GetInboxNumItems()
    inboxHeader:SetText(string.format("LOADED MAIL  %d / %d", loaded or 0, total or 0))
    for _, row in ipairs(inbox.rows) do row:Hide() end
    for i = 1, (loaded or 0) do
        local row = inbox.rows[i]
        if not row then
            row = CreateFrame("Button", nil, scrollChild, "BackdropTemplate")
            row:SetSize(434, 61)
            row:SetPoint("TOPLEFT", 0, -((i - 1) * 66))
            ApplyBackdrop(row, C.panelAlt)
            row.sender = Font(row, 13, C.text)
            row.sender:SetPoint("TOPLEFT", 12, -10)
            row.sender:SetWidth(245)
            row.subject = Font(row, 11, C.muted)
            row.subject:SetPoint("TOPLEFT", row.sender, "BOTTOMLEFT", 0, -5)
            row.subject:SetWidth(305)
            row.moneyIcon = row:CreateTexture(nil, "ARTWORK")
            row.moneyIcon:SetSize(17, 17)
            row.moneyIcon:SetPoint("TOPRIGHT", -9, -8)
            row.moneyIcon:SetTexture("Interface\\MoneyFrame\\UI-GoldIcon")
            row.money = Font(row, 13, { 1, 0.82, 0.18, 1 }, "RIGHT")
            row.money:SetPoint("RIGHT", row.moneyIcon, "LEFT", -4, 0)
            row.money:SetWidth(145)
            row.meta = Font(row, 10, C.muted, "RIGHT")
            row.meta:SetPoint("BOTTOMRIGHT", -10, 9)
            row.meta:SetWidth(150)
            row.dot = row:CreateTexture(nil, "OVERLAY")
            row.dot:SetSize(6, 41)
            row.dot:SetPoint("LEFT", 0, 0)
            inbox.rows[i] = row
        end
        local _, _, sender, subject, money, cod, days, hasItem, wasRead = GetInboxHeaderInfo(i)
        row.sender:SetText(sender or UNKNOWN)
        row.subject:SetText(subject or "(No subject)")
        local flags = {}
        if cod and cod > 0 then flags[#flags + 1] = "COD" end
        if hasItem then flags[#flags + 1] = "Item" end
        flags[#flags + 1] = string.format("%.0fd", days or 0)
        local hasMoney = (money or 0) > 0
        row.moneyIcon:SetShown(hasMoney)
        row.money:SetShown(hasMoney)
        row.money:SetText(hasMoney and ns:FormatMoney(money) or "")
        row.meta:SetText(table.concat(flags, " · "))
        if keepSelection == i or inbox.selected == i then
            row:SetBackdropBorderColor(unpack(C.accent))
        else
            row:SetBackdropBorderColor(unpack(C.border))
        end
        if wasRead then row.dot:SetColorTexture(unpack(C.border)) else row.dot:SetColorTexture(unpack(C.accent)) end
        row:SetScript("OnClick", function() ns:SelectMessage(i) end)
        row:Show()
    end
    scrollChild:SetHeight(math.max(1, (loaded or 0) * 66))
    if (loaded or 0) == 0 then
        inbox.selected = nil
        inbox.selectedCOD = 0
        ClearInboxAttachments()
        detailFrom:SetText("INBOX EMPTY")
        detailSubject:SetText("No mail to display")
        detailMeta:SetText("")
        body:SetText("New messages will appear here when they arrive.")
        detailMoneyIcon:Hide()
        detailMoneyLabel:Hide()
        detailMoneyValue:Hide()
    else
        local selection = tonumber(keepSelection) or inbox.selected or 1
        selection = math.min(selection, loaded)
        self:SelectMessage(selection, true)
    end
end

-- Compose
compose = CreateFrame("Frame", nil, content)
compose:SetAllPoints()
frame.pages.Compose = compose

local composeCard = CreateFrame("Frame", nil, compose, "BackdropTemplate")
composeCard:SetPoint("TOPLEFT")
composeCard:SetPoint("BOTTOMLEFT")
composeCard:SetWidth(610)
ApplyBackdrop(composeCard)

local function Label(text, anchor, relativePoint, x, y)
    local label = Font(composeCard, 11, C.muted)
    label:SetPoint("TOPLEFT", anchor, relativePoint, x, y)
    label:SetText(text)
    return label
end

local toLabel = Label("RECIPIENT", composeCard, "TOPLEFT", 18, -18)
local toBox = EditBox(composeCard)
toBox:SetSize(574, 35)
toBox:SetPoint("TOPLEFT", toLabel, "BOTTOMLEFT", 0, -6)
compose.to = toBox

local recipientSuggestions = CreateFrame("Frame", nil, composeCard, "BackdropTemplate")
recipientSuggestions:SetPoint("TOPLEFT", toBox, "BOTTOMLEFT", 0, -3)
recipientSuggestions:SetWidth(574)
recipientSuggestions:SetFrameLevel(composeCard:GetFrameLevel() + 20)
ApplyBackdrop(recipientSuggestions, C.panelAlt)
recipientSuggestions:Hide()
recipientSuggestions.rows = {}
recipientSuggestions.selected = 0
local suppressRecipientSuggestions = false

local function HideRecipientSuggestions()
    recipientSuggestions:Hide()
    recipientSuggestions.selected = 0
end

local function SelectRecipientSuggestion(name)
    toBox:SetText(name)
    toBox:SetCursorPosition(string.len(name))
    HideRecipientSuggestions()
    toBox:SetFocus()
end

local function UpdateRecipientSuggestionSelection()
    for index, row in ipairs(recipientSuggestions.rows) do
        if index <= recipientSuggestions.matchCount then
            if index == recipientSuggestions.selected then
                row:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.22)
            else
                row:SetBackdropColor(unpack(C.panelAlt))
            end
        end
    end
end

local function ShowRecipientSuggestions(_, userInput)
    if suppressRecipientSuggestions or not userInput then HideRecipientSuggestions(); return end
    local query = string.lower(strtrim(toBox:GetText() or ""))
    if query == "" then HideRecipientSuggestions(); return end

    local matches, seen = {}, {}
    local function AddMatch(name, source)
        if not name or name == "" then return end
        local lowered = string.lower(name)
        if seen[lowered] or not string.find(lowered, query, 1, true) then return end
        seen[lowered] = true
        matches[#matches + 1] = { name = name, source = source, startsWith = string.sub(lowered, 1, string.len(query)) == query }
    end

    for _, contact in ipairs(ns:GetContacts()) do AddMatch(contact.name, contact.kind) end
    for _, character in ipairs(ns:GetAlts()) do AddMatch(ns:GetRecipientName(character), "Character") end
    table.sort(matches, function(a, b)
        if a.startsWith ~= b.startsWith then return a.startsWith end
        return string.lower(a.name) < string.lower(b.name)
    end)

    local shown = math.min(#matches, 8)
    if shown == 0 then HideRecipientSuggestions(); return end
    recipientSuggestions.matchCount = shown
    recipientSuggestions.selected = 1
    recipientSuggestions:SetHeight(8 + shown * 30)
    for index = 1, shown do
        local match = matches[index]
        local row = recipientSuggestions.rows[index]
        if not row then
            row = CreateFrame("Button", nil, recipientSuggestions, "BackdropTemplate")
            row:SetHeight(30)
            row:SetPoint("TOPLEFT", 8, -4 - ((index - 1) * 30))
            row:SetPoint("TOPRIGHT", -8, -4 - ((index - 1) * 30))
            ApplyBackdrop(row, C.panelAlt, "button")
            row.label = Font(row, 12, C.text)
            row.label:SetPoint("LEFT", 10, 0)
            row.source = Font(row, 10, C.muted, "RIGHT")
            row.source:SetPoint("RIGHT", -10, 0)
            recipientSuggestions.rows[index] = row
        end
        row.label:SetText(match.name)
        row.source:SetText(match.source or "")
        row:SetScript("OnMouseDown", function() SelectRecipientSuggestion(match.name) end)
        row:Show()
    end
    for index = shown + 1, #recipientSuggestions.rows do recipientSuggestions.rows[index]:Hide() end
    recipientSuggestions:Show()
    UpdateRecipientSuggestionSelection()
end

toBox:SetScript("OnTextChanged", ShowRecipientSuggestions)
toBox:SetScript("OnEditFocusLost", function()
    if not recipientSuggestions:IsMouseOver() then HideRecipientSuggestions() end
end)
toBox:SetScript("OnKeyDown", function(self, key)
    if not recipientSuggestions:IsShown() then return end
    if key == "DOWN" or key == "UP" then
        local direction = key == "DOWN" and 1 or -1
        self:SetPropagateKeyboardInput(false)
        self:SetCursorPosition(string.len(self:GetText() or ""))
        recipientSuggestions.selected = math.max(1, math.min(recipientSuggestions.matchCount, recipientSuggestions.selected + direction))
        UpdateRecipientSuggestionSelection()
    elseif key == "ENTER" then
        self:SetPropagateKeyboardInput(false)
        local row = recipientSuggestions.rows[recipientSuggestions.selected]
        if row and row.label then SelectRecipientSuggestion(row.label:GetText()) end
    elseif key == "ESCAPE" then
        self:SetPropagateKeyboardInput(false)
        HideRecipientSuggestions()
    end
end)

local subjectLabel = Label("SUBJECT", toBox, "BOTTOMLEFT", 0, -14)
local subjectBox = EditBox(composeCard)
subjectBox:SetSize(574, 35)
subjectBox:SetPoint("TOPLEFT", subjectLabel, "BOTTOMLEFT", 0, -6)
compose.subject = subjectBox

function compose:SetRecipient(name, focusSubject)
    suppressRecipientSuggestions = true
    toBox:SetText(name or "")
    toBox:SetCursorPosition(string.len(name or ""))
    suppressRecipientSuggestions = false
    HideRecipientSuggestions()
    if focusSubject then
        ns:SelectTab("Compose")
        HideRecipientSuggestions()
        subjectBox:SetFocus()
    end
end

local bodyLabel = Label("MESSAGE", subjectBox, "BOTTOMLEFT", 0, -14)
local bodyContainer = CreateFrame("Frame", nil, composeCard, "BackdropTemplate")
bodyContainer:SetSize(574, 170)
bodyContainer:SetPoint("TOPLEFT", bodyLabel, "BOTTOMLEFT", 0, -6)
ApplyBackdrop(bodyContainer, C.letter, "letter")
local bodyBox = CreateFrame("EditBox", nil, bodyContainer)
bodyBox:SetPoint("TOPLEFT", 10, -8)
bodyBox:SetPoint("BOTTOMRIGHT", -10, 8)
bodyBox:SetFont(STANDARD_TEXT_FONT, 13, "")
fontObjects[bodyBox] = true
bodyBox:SetTextColor(unpack(C.text))
bodyBox:SetAutoFocus(false)
bodyBox:SetMultiLine(true)
bodyBox:SetMaxLetters(500)
bodyBox:SetJustifyV("TOP")
bodyBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
bodyBox:SetScript("OnTabPressed", function() toBox:SetFocus() end)
compose.body = bodyBox
ClassicInk(bodyBox, "text")

local attachLabel = Label("ATTACHMENTS", bodyContainer, "BOTTOMLEFT", 0, -14)
compose.slots = {}
for i = 1, MAX_SEND do
    local slot = CreateFrame("Button", nil, composeCard, "BackdropTemplate")
    slot:SetSize(42, 42)
    slot:SetPoint("TOPLEFT", attachLabel, "BOTTOMLEFT", (i - 1) * 47, -7)
    ApplyBackdrop(slot, C.panelAlt)
    slot.icon = slot:CreateTexture(nil, "ARTWORK")
    slot.icon:SetPoint("TOPLEFT", 3, -3)
    slot.icon:SetPoint("BOTTOMRIGHT", -3, 3)
    slot.count = Font(slot, 10, C.text, "RIGHT")
    slot.count:SetPoint("BOTTOMRIGHT", -4, 3)
    slot:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    slot:SetScript("OnReceiveDrag", function() ClickSendMailItemButton(i) end)
    slot:SetScript("OnClick", function(_, button)
        if CursorHasItem() then ClickSendMailItemButton(i) else ClickSendMailItemButton(i, true) end
    end)
    slot:SetScript("OnEnter", function(self)
        if HasSendMailItem(i) then GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetSendMailItem(i); GameTooltip:Show() end
    end)
    slot:SetScript("OnLeave", GameTooltip_Hide)
    compose.slots[i] = slot
end

local function EnsureAttachmentSubject()
    if strtrim(subjectBox:GetText() or "") ~= "" then return end
    for i = 1, MAX_SEND do
        local itemName = GetSendMailItem(i)
        if itemName and itemName ~= "" then
            subjectBox:SetText(itemName)
            return
        end
    end
end

local clearAttachments = Button(composeCard, "Clear attachments", 148, 28)
clearAttachments:SetPoint("TOPLEFT", compose.slots[1], "BOTTOMLEFT", 0, -12)
clearAttachments:SetScript("OnClick", function()
    if CursorHasItem() then ClearCursor() end
    local removed = 0
    for i = 1, MAX_SEND do
        if HasSendMailItem(i) then
            ClickSendMailItemButton(i, true)
            removed = removed + 1
        end
    end
    ns:RefreshCompose()
    if removed > 0 then
        ns:SetStatus(string.format("Cleared %d attachment%s.", removed, removed == 1 and "" or "s"))
    else
        ns:SetStatus("There are no attachments to clear.")
    end
end)

local function ScanBagItems(mode, categoryKey)
    local matches = {}
    if not C_Container or not C_Container.GetContainerNumSlots or not C_Container.GetContainerItemInfo then return matches end
    local tradeGoodsClass = Enum and Enum.ItemClass and Enum.ItemClass.Tradegoods or 7
    local bindOnEquip = Enum and Enum.ItemBind and Enum.ItemBind.OnEquip or 2
    local lastBag = NUM_TOTAL_EQUIPPED_BAG_SLOTS or 5
    for bag = 0, lastBag do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local containerInfo = C_Container.GetContainerItemInfo(bag, slot)
            if containerInfo and not containerInfo.isLocked and not containerInfo.isBound and containerInfo.itemID then
                local itemName, itemLink, _, _, _, _, itemSubType, _, _, itemTexture, _, classID, subclassID, bindType, _, _, isCraftingReagent = C_Item.GetItemInfo(containerInfo.hyperlink or containerInfo.itemID)
                local isProfessionItem = isCraftingReagent or classID == tradeGoodsClass
                local isBindOnEquip = bindType == bindOnEquip
                local itemCategoryKey = tostring(classID or -1) .. ":" .. tostring(subclassID or -1)
                local wanted = (mode == "profession" and isProfessionItem) or (mode == "boe" and isBindOnEquip)
                if wanted and (not categoryKey or categoryKey == itemCategoryKey) then
                    local category = itemSubType
                    if (not category or category == "") and C_Item.GetItemSubClassInfo and classID and subclassID then
                        category = C_Item.GetItemSubClassInfo(classID, subclassID)
                    end
                    matches[#matches + 1] = {
                        bag = bag,
                        slot = slot,
                        name = itemName or containerInfo.itemName or UNKNOWN,
                        link = itemLink or containerInfo.hyperlink,
                        icon = itemTexture or containerInfo.iconFileID,
                        count = containerInfo.stackCount or 1,
                        category = category or OTHER or "Other",
                        categoryKey = itemCategoryKey,
                    }
                end
            end
        end
    end
    table.sort(matches, function(a, b)
        if a.category ~= b.category then return a.category < b.category end
        if a.name ~= b.name then return a.name < b.name end
        if a.bag ~= b.bag then return a.bag < b.bag end
        return a.slot < b.slot
    end)
    return matches
end

local function FreeAttachmentSlots()
    local free = {}
    for i = 1, MAX_SEND do
        if not HasSendMailItem(i) then free[#free + 1] = i end
    end
    return free
end

local function AttachMatchingItems(mode, categoryKey, label)
    if CursorHasItem() then
        ns:SetStatus("Place the item on your cursor before using Quick Attach.", true)
        return
    end
    local freeSlots = FreeAttachmentSlots()
    if #freeSlots == 0 then
        ns:SetStatus("All mail attachment slots are already occupied.", true)
        return
    end
    local candidates = ScanBagItems(mode, categoryKey)
    if #candidates == 0 then
        ns:SetStatus("No matching unlocked bag items found for " .. label .. ".", true)
        return
    end
    local attached, failed = 0, 0
    for _, candidate in ipairs(candidates) do
        if attached >= #freeSlots then break end
        local current = C_Container.GetContainerItemInfo(candidate.bag, candidate.slot)
        if current and not current.isLocked and not current.isBound then
            local targetSlot = freeSlots[attached + 1]
            C_Container.PickupContainerItem(candidate.bag, candidate.slot)
            if CursorHasItem() then
                ClickSendMailItemButton(targetSlot)
                if HasSendMailItem(targetSlot) then
                    attached = attached + 1
                else
                    failed = failed + 1
                    if CursorHasItem() then ClearCursor() end
                end
            end
        end
    end
    if CursorHasItem() then ClearCursor() end
    ns:RefreshCompose()
    local remaining = math.max(0, #candidates - attached - failed)
    if attached == 0 then
        ns:SetStatus("No items could be attached. Check that the mailbox is open and the items are mailable.", true)
    elseif remaining > 0 then
        ns:SetStatus(string.format("Attached %d stack%s of %s; %d remain because the mail is full.", attached, attached == 1 and "" or "s", label, remaining))
    elseif failed > 0 then
        ns:SetStatus(string.format("Attached %d stack%s of %s; %d item%s could not be mailed.", attached, attached == 1 and "" or "s", label, failed, failed == 1 and "" or "s"), true)
    else
        ns:SetStatus(string.format("Attached %d stack%s of %s.", attached, attached == 1 and "" or "s", label))
    end
end

local function GetMaterialCategories()
    local categories, seen = {}, {}
    for _, candidate in ipairs(ScanBagItems("profession")) do
        if not seen[candidate.categoryKey] then
            seen[candidate.categoryKey] = true
            categories[#categories + 1] = { key = candidate.categoryKey, label = candidate.category }
        end
    end
    table.sort(categories, function(a, b) return a.label < b.label end)
    return categories
end

local moneyPanel = CreateFrame("Frame", nil, compose, "BackdropTemplate")
moneyPanel:SetPoint("TOPLEFT", composeCard, "TOPRIGHT", 12, 0)
moneyPanel:SetPoint("BOTTOMRIGHT")
ApplyBackdrop(moneyPanel)
local moneyTitle = Font(moneyPanel, 13, C.muted)
moneyTitle:SetPoint("TOPLEFT", 16, -16)
moneyTitle:SetText("COINS")

local goldLabel = Font(moneyPanel, 10, {1, .82, 0}); goldLabel:SetPoint("TOPLEFT", 16, -47); goldLabel:SetText("GOLD")
local silverLabel = Font(moneyPanel, 10, {.75, .75, .78}); silverLabel:SetPoint("TOPLEFT", 96, -47); silverLabel:SetText("SILVER")
local copperLabel = Font(moneyPanel, 10, {.82, .48, .25}); copperLabel:SetPoint("TOPLEFT", 162, -47); copperLabel:SetText("COPPER")

compose.gold = EditBox(moneyPanel); compose.gold:SetSize(72, 34); compose.gold:SetPoint("TOPLEFT", 16, -65); compose.gold:SetNumeric(true); compose.gold:SetText("0")
compose.silver = EditBox(moneyPanel); compose.silver:SetSize(58, 34); compose.silver:SetPoint("LEFT", compose.gold, "RIGHT", 8, 0); compose.silver:SetNumeric(true); compose.silver:SetText("0")
compose.copper = EditBox(moneyPanel); compose.copper:SetSize(58, 34); compose.copper:SetPoint("LEFT", compose.silver, "RIGHT", 8, 0); compose.copper:SetNumeric(true); compose.copper:SetText("0")

local cod = CreateFrame("CheckButton", nil, moneyPanel, "UICheckButtonTemplate")
cod:SetPoint("TOPLEFT", 10, -110)
cod.text:SetText("Cash on delivery")
cod.text:SetTextColor(unpack(C.text))
compose.cod = cod

local hint = Font(moneyPanel, 11, C.muted)
hint:SetPoint("TOPLEFT", 16, -152)
hint:SetPoint("TOPRIGHT", -16, -152)
hint:SetWordWrap(true)
hint:SetText("Drag items from your bags into the attachment slots. Click a slot to remove its item.")

local quickTitle = Font(moneyPanel, 13, C.muted)
quickTitle:SetPoint("TOPLEFT", 16, -215)
quickTitle:SetText("QUICK ATTACH")

local attachProfession = Button(moneyPanel, "All profession items", 238, 30)
attachProfession:SetPoint("TOPLEFT", 16, -240)
attachProfession:SetScript("OnClick", function() AttachMatchingItems("profession", nil, "profession items") end)

local attachBoE = Button(moneyPanel, "All bind-on-equip", 238, 30)
attachBoE:SetPoint("TOPLEFT", 16, -276)
attachBoE:SetScript("OnClick", function() AttachMatchingItems("boe", nil, "bind-on-equip items") end)

local materialButton = Button(moneyPanel, "Material type...", 238, 30)
materialButton:SetPoint("TOPLEFT", 16, -312)

local materialMenu = CreateFrame("Frame", nil, moneyPanel, "BackdropTemplate")
materialMenu:SetWidth(258)
materialMenu:SetPoint("BOTTOMRIGHT", materialButton, "TOPRIGHT", 0, 4)
materialMenu:SetFrameLevel(moneyPanel:GetFrameLevel() + 40)
ApplyBackdrop(materialMenu, C.bg)
materialMenu.buttons = {}
materialMenu:Hide()
frame.materialMenu = materialMenu

local function ShowMaterialMenu()
    if materialMenu:IsShown() then materialMenu:Hide(); return end
    local categories = GetMaterialCategories()
    for _, button in ipairs(materialMenu.buttons) do button:Hide() end
    if #categories == 0 then
        ns:SetStatus("No profession materials were found in your bags.", true)
        return
    end
    local shown = math.min(#categories, 9)
    materialMenu:SetHeight(16 + (shown * 30))
    for i = 1, shown do
        local category = categories[i]
        local categoryKey = category.key
        local categoryLabel = category.label
        local button = materialMenu.buttons[i]
        if not button then
            button = Button(materialMenu, "", activeSkin == "classic" and 206 or 238, 28)
            button:SetPoint("TOPLEFT", 10, -8 - ((i - 1) * 30))
            button.label:SetFont(STANDARD_TEXT_FONT, 11, "")
            materialMenu.buttons[i] = button
        end
        button.label:SetText(categoryLabel)
        button:SetScript("OnClick", function()
            materialMenu:Hide()
            AttachMatchingItems("profession", categoryKey, categoryLabel)
        end)
        button:Show()
    end
    materialMenu:Show()
    if #categories > shown then ns:SetStatus("Showing the first 9 material types found in your bags.") end
end
materialButton:SetScript("OnClick", ShowMaterialMenu)

local send = Button(moneyPanel, "Send mail", 238, 36)
send:SetPoint("BOTTOM", 0, 16)
send:SetBackdropBorderColor(unpack(C.accent))
send:SetScript("OnClick", function()
    local recipient = strtrim(toBox:GetText() or "")
    EnsureAttachmentSubject()
    local subjectText = strtrim(subjectBox:GetText() or "")
    if recipient == "" then ns:SetStatus("Choose a recipient.", true); toBox:SetFocus(); return end
    if subjectText == "" then ns:SetStatus("Add a subject.", true); subjectBox:SetFocus(); return end
    local amount = ((tonumber(compose.gold:GetText()) or 0) * 10000) + ((tonumber(compose.silver:GetText()) or 0) * 100) + (tonumber(compose.copper:GetText()) or 0)
    if cod:GetChecked() then SetSendMailMoney(0); SetSendMailCOD(amount) else SetSendMailCOD(0); SetSendMailMoney(amount) end
    ns:SetStatus("Sending...")
    SendMail(recipient, subjectText, bodyBox:GetText() or "")
end)
frame.composeSidebarButtons = { attachProfession, attachBoE, materialButton, send }

function ns:RefreshCompose()
    for i, slot in ipairs(compose.slots) do
        local itemName, _, texture, count = GetSendMailItem(i)
        slot.icon:SetTexture(texture)
        slot.icon:SetShown(itemName ~= nil)
        slot.count:SetText(itemName and (count or 1) > 1 and count or "")
    end
    EnsureAttachmentSubject()
end

function ns:OnMailSent()
    toBox:SetText(""); subjectBox:SetText(""); bodyBox:SetText("")
    compose.gold:SetText("0"); compose.silver:SetText("0"); compose.copper:SetText("0"); cod:SetChecked(false)
    self:RefreshCompose()
    self:SetStatus("Mail sent successfully.")
end

ns.events:HookScript("OnEvent", function(_, event)
    if event == "MAIL_SEND_INFO_UPDATE" or event == "MAIL_LOCK_SEND_ITEMS" or event == "MAIL_UNLOCK_SEND_ITEMS" then ns:RefreshCompose() end
end)
ns.events:RegisterEvent("MAIL_SEND_INFO_UPDATE")
ns.events:RegisterEvent("MAIL_LOCK_SEND_ITEMS")
ns.events:RegisterEvent("MAIL_UNLOCK_SEND_ITEMS")

-- Contacts
local contactsPage = CreateFrame("Frame", nil, content)
contactsPage:SetAllPoints()
frame.pages.Contacts = contactsPage
local contactsCard = CreateFrame("Frame", nil, contactsPage, "BackdropTemplate")
contactsCard:SetAllPoints()
ApplyBackdrop(contactsCard)
local contactsTitle = Font(contactsCard, 13, C.muted)
contactsTitle:SetPoint("TOPLEFT", 16, -16)
contactsTitle:SetText("RECIPIENT DIRECTORY")
local search = EditBox(contactsCard)
search:SetSize(280, 32)
search:SetPoint("TOPRIGHT", -16, -10)
search:SetTextInsets(10, 10, 6, 6)
contactsPage.search = search

contactsPage.source = "All"
local sourceButton = Button(contactsCard, "All Contacts", 190, 32)
sourceButton:SetPoint("TOPLEFT", 190, -10)
sourceButton.label:ClearAllPoints()
sourceButton.label:SetPoint("LEFT", 31, 0)
sourceButton:SetScript("OnMouseDown", function(self) self.label:SetPoint("LEFT", 32, -1) end)
sourceButton:SetScript("OnMouseUp", function(self) self.label:SetPoint("LEFT", 31, 0) end)

for i = 1, 3 do
    local line = sourceButton:CreateTexture(nil, "OVERLAY")
    line:SetColorTexture(unpack(C.accent))
    line:SetSize(12, 1)
    line:SetPoint("LEFT", 11, 4 - ((i - 1) * 4))
end

local sourceMenu = CreateFrame("Frame", nil, contactsCard, "BackdropTemplate")
sourceMenu:SetSize(210, 136)
sourceMenu:SetPoint("TOPLEFT", sourceButton, "BOTTOMLEFT", 0, -4)
sourceMenu:SetFrameLevel(contactsCard:GetFrameLevel() + 30)
ApplyBackdrop(sourceMenu, C.bg)
sourceMenu:Hide()

local sourceOptions = {
    { label = "All Contacts", source = "All" },
    { label = "Guild Members", source = "Guild" },
    { label = "Battle.net Characters", source = "Battle.net" },
    { label = "Character Friends", source = "Friend" },
}
for i, option in ipairs(sourceOptions) do
    local optionLabel = option.label
    local optionSource = option.source
    local optionButton = Button(sourceMenu, optionLabel, 190, 28)
    optionButton:SetPoint("TOPLEFT", 10, -8 - ((i - 1) * 30))
    optionButton.label:SetFont(STANDARD_TEXT_FONT, 11, "")
    optionButton:SetScript("OnClick", function()
        contactsPage.source = optionSource
        sourceButton.label:SetText(optionLabel)
        sourceMenu:Hide()
        ns:RefreshContacts()
    end)
end
sourceButton:SetScript("OnClick", function() sourceMenu:SetShown(not sourceMenu:IsShown()) end)

local onlineOnly = CreateFrame("CheckButton", nil, contactsCard, "UICheckButtonTemplate")
onlineOnly:SetPoint("TOPLEFT", 402, -13)
onlineOnly:SetSize(26, 26)
onlineOnly.text:SetText("Online only")
onlineOnly.text:SetTextColor(unpack(C.text))
onlineOnly:SetHitRectInsets(0, -78, 0, 0)
styledText[onlineOnly.text] = "text"
fontObjects[onlineOnly.text] = true
onlineOnly:SetScript("OnClick", function(self)
    if not ns.db then return end
    ns.db.settings.showOfflineContacts = not self:GetChecked()
    if IsInGuild() and C_GuildInfo and C_GuildInfo.GuildRoster then C_GuildInfo.GuildRoster() end
    ns:RefreshContacts()
end)

local contactsScroll = CreateFrame("ScrollFrame", nil, contactsCard, "UIPanelScrollFrameTemplate")
contactsScroll:SetPoint("TOPLEFT", 10, -52)
contactsScroll:SetPoint("BOTTOMRIGHT", -30, 10)
local contactsChild = CreateFrame("Frame", nil, contactsScroll)
contactsChild:SetSize(836, 1)
contactsScroll:SetScrollChild(contactsChild)
contactsPage.child = contactsChild
contactsPage.rows = {}

search:SetScript("OnTextChanged", function() ns:RefreshContacts() end)

function ns:RefreshContacts()
    if not contactsPage or not contactsPage:IsShown() then return end
    onlineOnly:SetChecked(self.db and not self.db.settings.showOfflineContacts)
    local rowWidth = activeSkin == "classic" and 817 or 831
    contactsChild:SetWidth(activeSkin == "classic" and 822 or 836)
    local query = string.lower(strtrim(search:GetText() or ""))
    local source = contactsPage.source or "All"
    local filtered = {}
    for _, contact in ipairs(self:GetContacts()) do
        local matchesSource = source == "All" or (contact.sources and contact.sources[source])
        if matchesSource and (self.db.settings.showOfflineContacts or contact.online) and
           (query == "" or string.find(string.lower(contact.name .. " " .. contact.kind .. " " .. (contact.detail or "")), query, 1, true)) then
            filtered[#filtered + 1] = contact
        end
    end
    for _, row in ipairs(contactsPage.rows) do row:Hide() end
    for i, contact in ipairs(filtered) do
        local row = contactsPage.rows[i]
        if not row then
            row = CreateFrame("Button", nil, contactsChild, "BackdropTemplate")
            row:SetSize(rowWidth, 43)
            row:SetPoint("TOPLEFT", 0, -((i - 1) * 48))
            ApplyBackdrop(row, C.panelAlt)
            row.name = Font(row, 13, C.text); row.name:SetPoint("LEFT", 14, 0); row.name:SetWidth(270)
            row.kind = Font(row, 11, C.accent); row.kind:SetPoint("LEFT", 300, 0); row.kind:SetWidth(140)
            row.detail = Font(row, 11, C.muted); row.detail:SetPoint("LEFT", 450, 0); row.detail:SetWidth(280)
            row.action = Font(row, 11, C.accent2, "RIGHT"); row.action:SetPoint("RIGHT", -34, 0); row.action:SetText("WRITE")
            contactsPage.rows[i] = row
        end
        row:SetWidth(rowWidth)
        local color = contact.classFile and RAID_CLASS_COLORS[contact.classFile]
        row.name:SetText(contact.name)
        row.name:SetTextColor(color and color.r or C.text[1], color and color.g or C.text[2], color and color.b or C.text[3])
        row.kind:SetText((contact.online and "ONLINE - " or "OFFLINE - ") .. contact.kind)
        row.detail:SetText(contact.detail or "")
        row:SetScript("OnClick", function()
            compose:SetRecipient(contact.name, true)
        end)
        row:Show()
    end
    contactsChild:SetHeight(math.max(1, #filtered * 48))
end

-- Alts
local altsPage = CreateFrame("Frame", nil, content)
altsPage:SetAllPoints()
frame.pages.Alts = altsPage
local altCard = CreateFrame("Frame", nil, altsPage, "BackdropTemplate")
altCard:SetAllPoints()
ApplyBackdrop(altCard)
local altTitle = Font(altCard, 13, C.muted)
altTitle:SetPoint("TOPLEFT", 16, -16)
altTitle:SetText("ACCOUNT CHARACTERS")
local altSummary = Font(altCard, 12, C.accent2, "RIGHT")
altSummary:SetPoint("TOPRIGHT", -16, -16)
local altScroll = CreateFrame("ScrollFrame", nil, altCard, "UIPanelScrollFrameTemplate")
altScroll:SetPoint("TOPLEFT", 10, -52)
altScroll:SetPoint("BOTTOMRIGHT", -30, 10)
local altChild = CreateFrame("Frame", nil, altScroll)
altChild:SetSize(836, 1)
altScroll:SetScrollChild(altChild)
altsPage.child, altsPage.rows = altChild, {}

function ns:RefreshAlts()
    if not altsPage or not altsPage:IsShown() then return end
    local rowWidth = activeSkin == "classic" and 817 or 831
    altChild:SetWidth(activeSkin == "classic" and 822 or 836)
    local characters, totalMoney = self:GetAlts(), 0
    for _, character in ipairs(characters) do
        totalMoney = totalMoney + (character.money or 0)
    end
    table.sort(characters, function(a, b) return (a.lastSeen or 0) > (b.lastSeen or 0) end)
    altSummary:SetText(#characters .. " characters  ·  " .. self:FormatMoney(totalMoney))
    for _, row in ipairs(altsPage.rows) do row:Hide() end
    for i, character in ipairs(characters) do
        local row = altsPage.rows[i]
        if not row then
            row = CreateFrame("Button", nil, altChild, "BackdropTemplate")
            row:SetSize(rowWidth, 64)
            row:SetPoint("TOPLEFT", 0, -((i - 1) * 70))
            ApplyBackdrop(row, C.panelAlt)
            row.name = Font(row, 14, C.text); row.name:SetPoint("TOPLEFT", 14, -11); row.name:SetWidth(235)
            row.realm = Font(row, 11, C.muted); row.realm:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -5)
            row.money = Font(row, 12, C.text); row.money:SetPoint("LEFT", 275, 0); row.money:SetWidth(160)
            row.mail = Font(row, 12, C.text); row.mail:SetPoint("LEFT", 465, 0); row.mail:SetWidth(210)
            row.seen = Font(row, 11, C.muted, "RIGHT"); row.seen:SetPoint("RIGHT", -76, 0); row.seen:SetWidth(100)
            row.action = Font(row, 11, C.accent2, "RIGHT"); row.action:SetPoint("RIGHT", -34, 0); row.action:SetText("WRITE")
            row:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(unpack(C.accent)) end)
            row:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(unpack(C.border)) end)
            altsPage.rows[i] = row
        end
        row:SetWidth(rowWidth)
        local color = character.classFile and RAID_CLASS_COLORS[character.classFile]
        row.name:SetText(string.format("%s  ·  %d", character.name or UNKNOWN, character.level or 0))
        row.name:SetTextColor(color and color.r or C.text[1], color and color.g or C.text[2], color and color.b or C.text[3])
        row.realm:SetText((character.realm or "Unknown realm") .. "  ·  " .. (character.faction or ""))
        row.money:SetText(self:FormatMoney(character.money or 0))
        local mail = character.inbox or {}
        row.mail:SetText(string.format("%d mail  ·  %d unread  ·  %d items", mail.total or 0, mail.unread or 0, mail.items or 0))
        row.seen:SetText(self:FormatAge(character.lastSeen))
        local recipient = self:GetRecipientName(character)
        row:SetScript("OnClick", function()
            compose:SetRecipient(recipient, true)
        end)
        row:Show()
    end
    altChild:SetHeight(math.max(1, #characters * 70))
end

-- Settings
local function NotifySharedSettings()
    if RevathsEnchantedFrames_RefreshSettings then RevathsEnchantedFrames_RefreshSettings() end
end

local settingsPage = CreateFrame("Frame", nil, content)
settingsPage:SetAllPoints()
frame.pages.Settings = settingsPage

local appearanceCard = CreateFrame("Frame", nil, settingsPage, "BackdropTemplate")
appearanceCard:SetPoint("TOPLEFT")
appearanceCard:SetPoint("TOPRIGHT")
appearanceCard:SetHeight(320)
ApplyBackdrop(appearanceCard)

local settingsTitle = Font(appearanceCard, 18, C.text)
settingsTitle:SetPoint("TOPLEFT", 22, -20)
settingsTitle:SetText("Appearance")
local settingsHint = Font(appearanceCard, 12, C.muted)
settingsHint:SetPoint("TOPLEFT", settingsTitle, "BOTTOMLEFT", 0, -9)
settingsHint:SetText("Choose a skin, palette, font, transparency, and comfortable window size.")

local modernButton = Button(appearanceCard, "Modern", 170, 36)
modernButton:SetPoint("TOPLEFT", 22, -75)
local modernDescription = Font(appearanceCard, 11, C.muted)
modernDescription:SetPoint("TOPLEFT", modernButton, "BOTTOMLEFT", 2, -9)
modernDescription:SetWidth(166)
modernDescription:SetText("Custom palettes and transparency.")

local classicButton = Button(appearanceCard, "Classic", 170, 36)
classicButton:SetPoint("TOPLEFT", 210, -75)
local classicDescription = Font(appearanceCard, 11, C.muted)
classicDescription:SetPoint("TOPLEFT", classicButton, "BOTTOMLEFT", 2, -9)
classicDescription:SetWidth(170)
classicDescription:SetText("Old-WoW frames and parchment.")

modernButton:SetScript("OnClick", function()
    if ns:ApplySkinSafe("modern") then ns:SetStatus("Modern skin selected.")
    else ns:SetStatus("The skin could not be loaded.", true) end
    NotifySharedSettings()
end)
classicButton:SetScript("OnClick", function()
    if ns:ApplySkinSafe("classic") then ns:SetStatus("Classic skin selected.")
    else ns:SetStatus("Classic could not load and was reset to Modern.", true) end
    NotifySharedSettings()
end)

local paletteLabel = Font(appearanceCard, 12, C.muted)
paletteLabel:SetPoint("TOPLEFT", 22, -158)
paletteLabel:SetText("MODERN PALETTE")
local paletteButton = Button(appearanceCard, "Midnight Cyan", 250, 34)
paletteButton:SetPoint("TOPLEFT", 22, -177)
AddDropdownArrow(paletteButton)

local fontLabel = Font(appearanceCard, 12, C.muted)
fontLabel:SetPoint("TOPLEFT", 292, -158)
fontLabel:SetText("ADDON FONT")
local fontButton = Button(appearanceCard, "Friz Quadrata", 250, 34)
fontButton:SetPoint("TOPLEFT", 292, -177)
AddDropdownArrow(fontButton)

local function SettingsSlider(label, x, y, width)
    local labelText = Font(appearanceCard, 12, C.muted)
    labelText:SetPoint("TOPLEFT", x, y)
    labelText:SetText(label)
    local valueText = Font(appearanceCard, 12, C.accent2, "RIGHT")
    valueText:SetPoint("TOPRIGHT", -(858 - x - width), y)
    valueText:SetWidth(62)
    local slider = CreateFrame("Slider", nil, appearanceCard)
    slider:SetPoint("TOPLEFT", x, y - 25)
    slider:SetSize(width, 18)
    slider:SetOrientation("HORIZONTAL")
    slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    local track = slider:CreateTexture(nil, "BACKGROUND")
    track:SetColorTexture(C.border[1], C.border[2], C.border[3], 0.8)
    track:SetPoint("LEFT", 2, 0)
    track:SetPoint("RIGHT", -2, 0)
    track:SetHeight(4)
    slider.track = track
    return slider, valueText
end

local opacitySlider, opacityValue = SettingsSlider("MODERN OPACITY", 570, -70, 250)
opacitySlider:SetMinMaxValues(0.55, 1)
opacitySlider:SetValueStep(0.05)
opacitySlider:SetObeyStepOnDrag(true)

local scaleSlider, scaleValue = SettingsSlider("WINDOW SCALE", 570, -158, 250)
scaleSlider:SetMinMaxValues(0.65, 1.10)
scaleSlider:SetValueStep(0.05)
scaleSlider:SetObeyStepOnDrag(true)

local settingsHelp = Font(appearanceCard, 11, C.muted)
settingsHelp:SetPoint("BOTTOMLEFT", 22, 20)
settingsHelp:SetText("Tip: 80–85% scale is designed to fit comfortably on 1080p displays.")

local paletteMenu, fontMenu
local function ChoiceMenu(anchor, order, options, onChoose, columns)
    columns = columns or 1
    local rows = math.ceil(#order / columns)
    local menu = CreateFrame("Frame", nil, appearanceCard, "BackdropTemplate")
    menu:SetSize((anchor:GetWidth() * columns) + ((columns - 1) * 6), (rows * 29) + 12)
    menu:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, 4)
    menu:SetFrameLevel(appearanceCard:GetFrameLevel() + 20)
    menu:SetClampedToScreen(true)
    ApplyBackdrop(menu, C.panel, "panel")
    menu.buttons = {}
    for i, key in ipairs(order) do
        local column = math.floor((i - 1) / rows)
        local row = (i - 1) % rows
        local option = Button(menu, options[key].label, anchor:GetWidth() - 6, 27)
        option:SetPoint("TOPLEFT", 6 + (column * anchor:GetWidth()), -6 - (row * 29))
        option:SetScript("OnClick", function()
            onChoose(key)
            menu:Hide()
        end)
        menu.buttons[#menu.buttons + 1] = option
    end
    menu:Hide()
    return menu
end

paletteMenu = ChoiceMenu(paletteButton, PALETTE_ORDER, MODERN_PALETTES, function(key)
    if not ns.db then return end
    ns.db.settings.palette = key
    if activeSkin == "modern" then ns:ApplySkinSafe("modern") else ns:RefreshSettings() end
    ns:SetStatus(MODERN_PALETTES[key].label .. " palette selected.")
    NotifySharedSettings()
end)

local function PagedFontMenu(anchor)
    local columns, rows, perPage = 2, 5, 10
    local menu = CreateFrame("Frame", nil, appearanceCard, "BackdropTemplate")
    menu:SetSize((anchor:GetWidth() * columns) + 6, (rows * 29) + 42)
    menu:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, 4)
    menu:SetFrameLevel(appearanceCard:GetFrameLevel() + 20)
    menu:SetClampedToScreen(true)
    ApplyBackdrop(menu, C.panel, "panel")
    menu.page, menu.buttons = 1, {}

    for slot = 1, perPage do
        local column = math.floor((slot - 1) / rows)
        local row = (slot - 1) % rows
        local option = Button(menu, "", anchor:GetWidth() - 6, 27)
        option:SetPoint("TOPLEFT", 6 + (column * anchor:GetWidth()), -6 - (row * 29))
        option:SetScript("OnClick", function(self)
            local selected = self.fontKey and FONT_OPTIONS[self.fontKey]
            if not selected or not ns.db then return end
            ns.db.settings.font = self.fontKey
            ApplySelectedFont()
            ns:RefreshSettings()
            ns:SetStatus(selected.label .. " font selected.")
            NotifySharedSettings()
            menu:Hide()
        end)
        menu.buttons[slot] = option
    end

    menu.previous = Button(menu, "<", 32, 25)
    menu.previous:SetPoint("BOTTOMLEFT", 6, 6)
    menu.next = Button(menu, ">", 32, 25)
    menu.next:SetPoint("BOTTOMRIGHT", -6, 6)
    menu.pageText = Font(menu, 11, C.muted, "CENTER")
    menu.pageText:SetPoint("BOTTOM", 0, 12)
    menu.pageText:SetWidth(180)

    function menu:Refresh()
        DiscoverSharedMediaFonts()
        local pages = math.max(1, math.ceil(#FONT_ORDER / perPage))
        self.page = math.max(1, math.min(self.page, pages))
        local offset = (self.page - 1) * perPage
        for slot, option in ipairs(self.buttons) do
            local key = FONT_ORDER[offset + slot]
            local font = key and FONT_OPTIONS[key]
            option.fontKey = key
            option:SetShown(font ~= nil)
            if font then
                option.label:SetText(font.label)
                local _, size = option.label:GetFont()
                local ok, loaded = pcall(option.label.SetFont, option.label, font.path, size or 11, font.flags or "")
                if not ok or loaded == false then option.label:SetFont(STANDARD_TEXT_FONT, size or 11, "") end
            end
        end
        self.previous:SetEnabled(self.page > 1)
        self.next:SetEnabled(self.page < pages)
        self.previous:SetAlpha(self.page > 1 and 1 or 0.35)
        self.next:SetAlpha(self.page < pages and 1 or 0.35)
        self.pageText:SetText(string.format("Fonts %d / %d  ·  %d available", self.page, pages, #FONT_ORDER))
    end

    menu.previous:SetScript("OnClick", function()
        if menu.page > 1 then menu.page = menu.page - 1; menu:Refresh() end
    end)
    menu.next:SetScript("OnClick", function()
        local pages = math.max(1, math.ceil(#FONT_ORDER / perPage))
        if menu.page < pages then menu.page = menu.page + 1; menu:Refresh() end
    end)
    menu:EnableMouseWheel(true)
    menu:SetScript("OnMouseWheel", function(_, delta)
        local pages = math.max(1, math.ceil(#FONT_ORDER / perPage))
        menu.page = math.max(1, math.min(pages, menu.page - delta))
        menu:Refresh()
    end)
    menu:Refresh()
    menu:Hide()
    return menu
end

fontMenu = PagedFontMenu(fontButton)

paletteButton:SetScript("OnClick", function()
    fontMenu:Hide()
    paletteMenu:SetShown(not paletteMenu:IsShown())
end)
fontButton:SetScript("OnClick", function()
    paletteMenu:Hide()
    fontMenu:Refresh()
    fontMenu:SetShown(not fontMenu:IsShown())
end)

local settingsRefreshing = false
opacitySlider:SetScript("OnValueChanged", function(_, value)
    value = math.floor((value * 20) + 0.5) / 20
    opacityValue:SetText(string.format("%d%%", value * 100))
    if settingsRefreshing or not ns.db then return end
    ns.db.settings.modernOpacity = value
    if activeSkin == "modern" then ns:ApplySkinSafe("modern") end
    NotifySharedSettings()
end)
local pendingScale, scaleDragging, scaleCommitToken
local function CommitWindowScale()
    if not pendingScale or not ns.db then return end
    ns.db.settings.scale = pendingScale
    frame:SetScale(pendingScale)
    pendingScale = nil
    NotifySharedSettings()
end
scaleSlider:SetScript("OnMouseDown", function() scaleDragging = true end)
scaleSlider:SetScript("OnMouseUp", function()
    scaleDragging = false
    CommitWindowScale()
end)
scaleSlider:SetScript("OnValueChanged", function(_, value)
    value = math.floor((value * 20) + 0.5) / 20
    scaleValue:SetText(string.format("%d%%", value * 100))
    if settingsRefreshing or not ns.db then return end
    pendingScale = value
    if scaleDragging then return end
    scaleCommitToken = (scaleCommitToken or 0) + 1
    local token = scaleCommitToken
    if C_Timer and C_Timer.After then
        C_Timer.After(0.2, function()
            if token == scaleCommitToken and not scaleDragging then CommitWindowScale() end
        end)
    else
        CommitWindowScale()
    end
end)

local aboutCard = CreateFrame("Frame", nil, settingsPage, "BackdropTemplate")
aboutCard:SetPoint("TOPLEFT", appearanceCard, "BOTTOMLEFT", 0, -12)
aboutCard:SetPoint("BOTTOMRIGHT")
ApplyBackdrop(aboutCard)
local aboutTitle = Font(aboutCard, 18, C.text)
aboutTitle:SetPoint("TOPLEFT", 22, -20)
aboutTitle:SetText("About Revath's Enchanted Mailbox")
local aboutDescription = Font(aboutCard, 12, C.muted)
aboutDescription:SetPoint("TOPLEFT", aboutTitle, "BOTTOMLEFT", 0, -12)
aboutDescription:SetWidth(790)
aboutDescription:SetWordWrap(true)
aboutDescription:SetText("A mailbox replacement for managing mail, recipients, profession materials, and account characters from one interface.")
local authorLabel = Font(aboutCard, 12, C.muted)
authorLabel:SetPoint("TOPLEFT", aboutDescription, "BOTTOMLEFT", 0, -18)
authorLabel:SetText("AUTHOR")
local authorValue = Font(aboutCard, 15, C.text)
authorValue:SetPoint("TOPLEFT", authorLabel, "BOTTOMLEFT", 0, -7)
authorValue:SetText("Revath#2331")
local versionLabel = Font(aboutCard, 12, C.muted)
versionLabel:SetPoint("TOPLEFT", 420, -82)
versionLabel:SetText("VERSION")
local versionValue = Font(aboutCard, 15, C.accent2)
versionValue:SetPoint("TOPLEFT", versionLabel, "BOTTOMLEFT", 0, -7)
versionValue:SetText(ns.version)

function ns:RefreshSettings()
    if not settingsPage:IsShown() then return end
    local skin = self.db and self.db.settings.skin or activeSkin
    local paletteKey = self.db and self.db.settings.palette or "midnight"
    local fontKey = self.db and self.db.settings.font or "friz"
    for name, button in pairs({ modern = modernButton, classic = classicButton }) do
        if name == skin then
            button:SetBackdropColor(C.accent[1], C.accent[2], C.accent[3], 0.25)
            button:SetBackdropBorderColor(unpack(C.accent))
            button.label:SetText(name == "modern" and "Modern" or "Classic")
            if activeSkin == "classic" and button:GetNormalTexture() then button:GetNormalTexture():SetVertexColor(0.76, 0.53, 0.10, 1) end
        else
            button:SetBackdropColor(unpack(C.panelAlt))
            button:SetBackdropBorderColor(unpack(C.border))
            button.label:SetText(name == "modern" and "Modern" or "Classic")
            if activeSkin == "classic" and button:GetNormalTexture() then button:GetNormalTexture():SetVertexColor(0.78, 0.20, 0.08, 1) end
        end
    end
    paletteButton.label:SetText((MODERN_PALETTES[paletteKey] or MODERN_PALETTES.midnight).label)
    fontButton.label:SetText((FONT_OPTIONS[fontKey] or FONT_OPTIONS.friz).label)
    if fontMenu then fontMenu:Refresh() end
    settingsRefreshing = true
    opacitySlider:SetValue(math.max(0.55, math.min(1, tonumber(self.db and self.db.settings.modernOpacity) or 0.96)))
    scaleSlider:SetValue(math.max(0.65, math.min(1.10, tonumber(self.db and self.db.settings.scale) or 1)))
    settingsRefreshing = false
    versionValue:SetText(self.version)
end

function ns:Show()
    if not self.mailOpen then return end
    self:DisableBlizzardMailbox()
    if C_Timer and C_Timer.After then
        C_Timer.After(0, function()
            if ns.mailOpen then ns:DisableBlizzardMailbox() end
        end)
        C_Timer.After(0.1, function()
            if ns.mailOpen then ns:DisableBlizzardMailbox() end
        end)
    end
    SetSendMailShowing(false)
    frame:SetScale(math.max(0.65, math.min(1.10, tonumber(self.db and self.db.settings.scale) or 1)))
    local requestedSkin = (self.db and self.db.settings.skin) or savedSkin
    local skinLoaded = self:ApplySkinSafe(requestedSkin)
    frame:Show()
    self:SelectTab("Inbox")
    if skinLoaded then self:SetStatus("Mailbox ready")
    else self:SetStatus("Classic failed safely; using Modern.", true) end
end

function ns:Hide(fromGame)
    self.suppressClose = fromGame
    frame:Hide()
    self.suppressClose = nil
    if self.mailOpen then SetSendMailShowing(false) end
    if MailFrame then MailFrame:SetAlpha(1); MailFrame:EnableMouse(true) end
end

frame:SetScript("OnHide", function()
    ClearCursor()
    if ns.mailOpen and not ns.suppressClose then
        SetSendMailShowing(false)
        CloseMail()
    end
end)

table.insert(UISpecialFrames, frame:GetName())
ns:SelectTab("Inbox")

function RevathsEnchantedMailbox_ApplySettings()
    if not ns.db or not ns.db.settings then return end
    frame:SetScale(math.max(0.65, math.min(1.10, tonumber(ns.db.settings.scale) or 1)))
    ns:ApplySkinSafe(ns.db.settings.skin or "modern")
    if ns.RefreshSettings then ns:RefreshSettings() end
    if ns.RefreshContacts then ns:RefreshContacts() end
end
