-- Optional Blizzard chrome; existing window layouts and interactions stay intact.
local windows={}
local function FocusWindow(frame)
    for i,window in ipairs(windows) do
        if window==frame then table.remove(windows,i); break end
    end
    windows[#windows+1]=frame
    -- Reserve enough room for each window's descendants and its small popups.
    -- Repack instead of accumulating frame levels with every click.
    for i,window in ipairs(windows) do window:SetFrameLevel(i*40) end
end

function RevathsEnchantedFrames_NormalizeWindowLayers(frame)
    if not frame or not frame.GetChildren or not frame.GetFrameLevel then return end
    frame:SetToplevel(true)
    if not frame.revathsLayerGroup then
        frame.revathsLayerGroup=true
        windows[#windows+1]=frame
        frame:HookScript("OnShow",function() FocusWindow(frame) end)
        FocusWindow(frame)
    end
    local function Normalize(parent)
        if not parent.revathsFocusHook then
            parent.revathsFocusHook=true
            -- Mouse scripts make decorative Frames hit-testable. Never attach
            -- them to chrome/insets, and never reorder a pressed control.
            if parent==frame then
                parent:HookScript("OnMouseUp",function() FocusWindow(frame) end)
            elseif parent.GetObjectType then
                local kind=parent:GetObjectType()
                if kind=="Button" or kind=="CheckButton" then
                    parent:HookScript("OnClick",function() FocusWindow(frame) end)
                end
            end
        end
        for _, child in ipairs({parent:GetChildren()}) do
            child:SetFrameLevel(parent:GetFrameLevel()+1)
            Normalize(child)
        end
    end
    Normalize(frame)
end

function RevathsEnchantedFrames_ApplyNativeChrome(frame, enabled, classic)
    if not frame then return end
    RevathsEnchantedFrames_NormalizeWindowLayers(frame)
    local chrome=frame.revathsNativeChrome
    if enabled and not chrome then
        chrome=CreateFrame("Frame",nil,frame,"ButtonFrameTemplate")
        chrome:SetAllPoints(frame); chrome:EnableMouse(false)
        if ButtonFrameTemplate_HideButtonBar then ButtonFrameTemplate_HideButtonBar(chrome) end
        -- Only the native NineSlice border is used on existing custom windows.
        for _,region in ipairs({chrome:GetRegions()}) do region:Hide() end
        for _,key in ipairs({"Bg","TitleBg","TitleText","PortraitContainer","CloseButton","Inset"}) do
            if chrome[key] then chrome[key]:Hide() end
        end
        if chrome.NineSlice then chrome.NineSlice:EnableMouse(false) end
        frame.revathsNativeChrome=chrome
    end
    if chrome then chrome:SetShown(enabled==true) end
    if not chrome then return end
    if chrome.TitleContainer then chrome.TitleContainer:SetShown(classic ~= nil) end
    if chrome.PortraitContainer then chrome.PortraitContainer:SetShown(classic ~= nil) end
    if classic then
        if chrome.SetTitle then chrome:SetTitle(classic.title) end
        if chrome.SetPortraitToAsset then chrome:SetPortraitToAsset(classic.icon) end
        if chrome.CloseButton and classic.close then
            chrome.CloseButton:Show()
            chrome.CloseButton:SetScript("OnClick",function()
                local handler=classic.close:GetScript("OnClick")
                if handler then handler(classic.close) else frame:Hide() end
            end)
        end
    elseif chrome.CloseButton then
        chrome.CloseButton:Hide()
    end
    if not frame.revathsClassicBackground and classic then
        local bg = frame:CreateTexture(nil,"BACKGROUND",nil,-7)
        bg:SetPoint("TOPLEFT",6,-21); bg:SetPoint("BOTTOMRIGHT",-2,2)
        bg:SetTexture("Interface\\FrameGeneral\\UI-Background-Rock")
        bg:SetHorizTile(true); bg:SetVertTile(true)
        frame.revathsClassicBackground = bg
    end
    if frame.revathsClassicBackground then frame.revathsClassicBackground:SetShown(classic ~= nil) end
    RevathsEnchantedFrames_NormalizeWindowLayers(frame)
end

function RevathsEnchantedFrames_ResetClassicSurface(surface)
    if surface.revathsClassicInset then surface.revathsClassicInset:Hide() end
    if surface.revathsClassicInsetBg then surface.revathsClassicInsetBg:Hide() end
end

-- Native inset art is kept separate from controls and content so it cannot
-- intercept clicks or paint over labels on the parent frame.
function RevathsEnchantedFrames_StyleClassicSurface(surface, role, opacity)
    RevathsEnchantedFrames_ResetClassicSurface(surface)
    for _, key in ipairs({"classicTexture", "revathsClassicTexture"}) do
        if surface[key] then surface[key]:Hide() end
    end
    local button = role == "button" and surface.SetNormalTexture
    local outer = role == "bg" or role == "background"
    surface:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background", tile=true, tileSize=32,
        edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize=outer and 32 or 18,
        insets={left=5,right=5,top=5,bottom=5}})
    if button then
        for _, state in ipairs({"Normal", "Pushed", "Highlight"}) do
            local asset = state == "Normal" and "Up" or state == "Pushed" and "Down" or "Highlight"
            surface["Set"..state.."Texture"](surface,"Interface\\Buttons\\UI-Panel-Button-"..asset)
            local texture = surface["Get"..state.."Texture"](surface)
            if texture then
                texture:SetTexCoord(0,.625,0,.6875)
                texture:SetVertexColor(1,1,1,1); texture:SetAlpha(1)
            end
        end
        surface:SetBackdropColor(0,0,0,0); surface:SetBackdropBorderColor(0,0,0,0)
    else
        for _, state in ipairs({"Normal","Pushed","Highlight"}) do
            local getter=surface["Get"..state.."Texture"]
            local texture=getter and getter(surface)
            if texture then texture:SetAlpha(0) end
        end
        surface:SetBackdropColor(1,1,1,outer and 0 or 1)
        surface:SetBackdropBorderColor(1,1,1,outer and 0 or 1)
        if not outer and surface.GetFrameLevel then
            if not surface.revathsClassicInset then
                local inset=CreateFrame("Frame",nil,surface,"InsetFrameTemplate")
                inset:SetAllPoints(surface); inset:EnableMouse(false)
                if inset.NineSlice then inset.NineSlice:EnableMouse(false) end
                if inset.Bg then
                    inset.Bg:SetParent(surface); inset.Bg:ClearAllPoints()
                    inset.Bg:SetAllPoints(surface); inset.Bg:SetDrawLayer("BACKGROUND",-6)
                    surface.revathsClassicInsetBg=inset.Bg
                end
                surface.revathsClassicInset=inset
            end
            surface.revathsClassicInset:SetFrameLevel(surface:GetFrameLevel())
            surface.revathsClassicInset:Show()
            if surface.revathsClassicInsetBg then surface.revathsClassicInsetBg:Show() end
            surface:SetBackdropColor(0,0,0,0); surface:SetBackdropBorderColor(0,0,0,0)
        end
    end
end
