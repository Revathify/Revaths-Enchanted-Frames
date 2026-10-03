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
