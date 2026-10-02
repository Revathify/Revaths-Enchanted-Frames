local probe
local function NativeFont()
    if GameFontNormal and GameFontNormal.GetFont then
        local path=GameFontNormal:GetFont()
        if type(path)=="string" and path~="" then return path end
    end
    return STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
end

function RevathsEnchantedFrames_FontAvailable(path)
    if type(path)~="string" or path=="" then return false end
    if not CreateFont then return true end
    probe=probe or CreateFont("RevathsEnchantedFramesFontProbe")
    local ok,loaded=pcall(probe.SetFont,probe,path,12,"")
    return ok and loaded~=false
end

function RevathsEnchantedFrames_ResolveFont(key)
    key=type(key)=="string" and key or "friz"
    local path,flags
    if key:sub(1,7)=="shared:" then
        -- A registered shared font's name is opaque; never parse 'Outline' inside it.
        local ok,value=pcall(function()
            local media=LibStub and LibStub("LibSharedMedia-3.0",true)
            return media and media:Fetch("font",key:sub(8),true)
        end)
        path=ok and value or nil; flags=""
    else
        local base=key:gsub("Outline$","")
        flags=key:match("Outline$") and "OUTLINE" or ""
        local locale=GetLocale and GetLocale() or "enUS"
        local paths={friz=NativeFont(),arial="Fonts\\ARIALN.TTF",morpheus="Fonts\\MORPHEUS.TTF",skurri="Fonts\\SKURRI.TTF"}
        if locale=="ruRU" then
            paths.morpheus="Fonts\\MORPHEUS_CYR.TTF"; paths.skurri=NativeFont()
        elseif locale=="koKR" or locale=="zhCN" or locale=="zhTW" then
            paths.arial,paths.morpheus,paths.skurri=NativeFont(),NativeFont(),NativeFont()
        end
        path=paths[base]
    end
    local valid=RevathsEnchantedFrames_FontAvailable(path)
    return valid and path or NativeFont(), valid and flags or "", valid
end

function RevathsEnchantedFrames_ApplyFont(object,key,size)
    local path,flags,valid=RevathsEnchantedFrames_ResolveFont(key)
    local ok,loaded=pcall(object.SetFont,object,path,size,flags)
    if not ok or loaded==false then
        object:SetFont(NativeFont(),size,"")
        return false
    end
    return valid
end
