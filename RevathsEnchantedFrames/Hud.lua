-- Optional Blizzard chrome; existing window layouts and interactions stay intact.
function RevathsEnchantedFrames_ApplyNativeChrome(frame, enabled)
    if not frame then return end
    local chrome=frame.revathsNativeChrome
    if enabled and not chrome then
        chrome=CreateFrame("Frame",nil,frame,"PortraitFrameTemplate")
        chrome:SetAllPoints(frame); chrome:EnableMouse(false)
        -- Only the native NineSlice border is used on existing custom windows.
        for _,region in ipairs({chrome:GetRegions()}) do region:Hide() end
        for _,key in ipairs({"Bg","TitleBg","TitleText","PortraitContainer","CloseButton"}) do
            if chrome[key] then chrome[key]:Hide() end
        end
        if chrome.NineSlice then chrome.NineSlice:EnableMouse(false) end
        frame.revathsNativeChrome=chrome
    end
    if chrome then chrome:SetShown(enabled==true) end
end

-- One Classic surface treatment for every suite window. Native border overlays
-- stay click-through; content keeps its normal layout and opacity setting.
function RevathsEnchantedFrames_StyleClassicSurface(surface, role, opacity)
    for _, key in ipairs({"classicTexture", "revathsClassicTexture"}) do
        if surface[key] then surface[key]:Hide() end
    end
    local button = role == "button" and surface.SetNormalTexture
    surface:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", edgeSize=12,
        insets={left=3,right=3,top=3,bottom=3}})
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
        local outer = role == "bg" or role == "background"
        surface:SetBackdropColor(.035,.04,.05,math.max(.55,math.min(1,tonumber(opacity) or .96)))
        surface:SetBackdropBorderColor(.32,.39,.48,outer and 0 or 1)
    end
end
