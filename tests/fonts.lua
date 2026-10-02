local locale="enUS"
STANDARD_TEXT_FONT="Fonts\\FRIZQT__.TTF"
GameFontNormal={GetFont=function() return STANDARD_TEXT_FONT,12,"" end}
GetLocale=function() return locale end
local valid={[STANDARD_TEXT_FONT]=true,["Fonts\\ARIALN.TTF"]=true,["Fonts\\MORPHEUS.TTF"]=true,
    ["Fonts\\MORPHEUS_CYR.TTF"]=true,["Fonts\\SKURRI.TTF"]=true,["Interface\\AddOns\\Media\\OutlineTest.ttf"]=true}
CreateFont=function() return {SetFont=function(_,path) return valid[path]==true end} end
assert(loadfile("RevathsEnchantedFrames/Fonts.lua"))()
local path,flags,ok=RevathsEnchantedFrames_ResolveFont("arialOutline")
assert(ok and path=="Fonts\\ARIALN.TTF" and flags=="OUTLINE")
LibStub=function() return {Fetch=function(_,kind,name) return name=="Outline Test" and "Interface\\AddOns\\Media\\OutlineTest.ttf" end} end
path,flags,ok=RevathsEnchantedFrames_ResolveFont("shared:Outline Test")
assert(ok and flags=="", "shared font names never enable outline styling")
path,flags,ok=RevathsEnchantedFrames_ResolveFont("shared:Missing font")
assert(not ok and path==STANDARD_TEXT_FONT and flags=="", "missing shared providers fall back safely")
valid["Fonts\\SKURRI.TTF"]=nil
path,flags,ok=RevathsEnchantedFrames_ResolveFont("skurri")
assert(not ok and path==STANDARD_TEXT_FONT, "failed in-client font probes prevent invalid selections")
locale="ruRU"; path=RevathsEnchantedFrames_ResolveFont("morpheus"); assert(path=="Fonts\\MORPHEUS_CYR.TTF")
locale="koKR"; path=RevathsEnchantedFrames_ResolveFont("arial"); assert(path==STANDARD_TEXT_FONT,"non-Latin clients use their native font")
locale="enUS"
local target={SetFont=function(self,path) self.path=path; return path~= "Fonts\\MORPHEUS.TTF" end}
assert(not RevathsEnchantedFrames_ApplyFont(target,"morpheus",12) and target.path==STANDARD_TEXT_FONT,"object font failures restore native text")
print("Font tests passed: valid paths, locale fallback, unavailable providers, shared font names, probe failures and object failures.")
