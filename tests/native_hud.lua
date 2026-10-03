local created=0
local function Part() return {Hide=function(self) self.hidden=true end,Show=function(self) self.hidden=false end,
    SetScript=function(self,_,fn) self.click=fn end,
    SetPoint=function() end,SetTexture=function(self,v) self.asset=v end,SetHorizTile=function(self,v) self.horizTile=v end,
    SetVertTile=function(self,v) self.vertTile=v end,
    SetShown=function(self,v) self.hidden=not v end,EnableMouse=function(self,v) self.mouse=v end} end
CreateFrame=function(_,_,parent,template)
    assert(template=="ButtonFrameTemplate")
    created=created+1
    local region=Part()
    return {parent=parent,NineSlice=Part(),Bg=Part(),TitleContainer=Part(),PortraitContainer=Part(),CloseButton=Part(),
        SetTitle=function(self,v) self.title=v end,SetPortraitToAsset=function(self,v) self.icon=v end,
        SetAllPoints=function(self,p) self.anchored=p end,EnableMouse=function(self,v) self.mouse=v end,
        GetRegions=function() return region end,SetShown=function(self,v) self.shown=v end}
end
assert(loadfile("RevathsEnchantedFrames/Hud.lua"))()
local frame={}
frame.CreateTexture=function() return Part() end
RevathsEnchantedFrames_ApplyNativeChrome(frame,false)
assert(created==0,"no template cost for users keeping existing chrome")
RevathsEnchantedFrames_ApplyNativeChrome(frame,true)
local c=frame.revathsNativeChrome
assert(created==1 and c.shown and c.anchored==frame)
assert(c.Bg.hidden and c.PortraitContainer.hidden and c.CloseButton.hidden)
assert(c.mouse==false and c.NineSlice.mouse==false,"decoration never intercepts window controls")
RevathsEnchantedFrames_ApplyNativeChrome(frame,true)
assert(created==1,"appearance changes reuse the native template")
RevathsEnchantedFrames_ApplyNativeChrome(frame,false)
assert(not c.shown)
local surface={classicTexture=Part(),
    SetBackdrop=function(self,v) self.backdrop=v end,
    SetBackdropColor=function(self,...) self.color={...} end,
    SetBackdropBorderColor=function(self,...) self.border={...} end}
RevathsEnchantedFrames_StyleClassicSurface(surface,"letter",.7)
assert(surface.classicTexture.hidden and surface.color[4]==1)
assert(surface.backdrop.bgFile=="Interface\\DialogFrame\\UI-DialogBox-Background" and surface.border[4]==1,"Classic uses native textured panels independently of Modern opacity")
RevathsEnchantedFrames_StyleClassicSurface(surface,"bg",.8)
assert(surface.border[4]==0,"native outer chrome replaces the old double border")
local closed=false
local close={GetScript=function() return function() closed=true end end}
RevathsEnchantedFrames_ApplyNativeChrome(frame,true,{title="Classic window",icon="AddonIcon",close=close})
assert(c.title=="Classic window" and c.icon=="AddonIcon")
assert(not c.TitleContainer.hidden and not c.PortraitContainer.hidden and not c.CloseButton.hidden)
assert(frame.revathsClassicBackground.asset=="Interface\\FrameGeneral\\UI-Background-Rock" and frame.revathsClassicBackground.horizTile)
c.CloseButton.click(); assert(closed,"native close preserves the module's close behavior")
RevathsEnchantedFrames_ApplyNativeChrome(frame,false)
assert(frame.revathsClassicBackground.hidden and c.TitleContainer.hidden and c.CloseButton.hidden,"switching to Modern removes the full Classic treatment")
local insetBg=Part()
insetBg.SetParent=function(self,v) self.parent=v end
insetBg.ClearAllPoints=function() end
insetBg.SetAllPoints=function() end
insetBg.SetDrawLayer=function(self,v) self.layer=v end
CreateFrame=function(_,_,parent,template)
    assert(template=="InsetFrameTemplate","Classic uses Blizzard's actual inset template")
    local inset=Part(); inset.Bg=insetBg; inset.NineSlice=Part()
    inset.SetAllPoints=function() end
    inset.SetFrameLevel=function(self,v) self.level=v end
    return inset
end
surface.GetFrameLevel=function() return 4 end
RevathsEnchantedFrames_StyleClassicSurface(surface,"panel",.6)
assert(surface.revathsClassicInset.level==4 and insetBg.parent==surface and insetBg.layer=="BACKGROUND")
assert(surface.color[4]==0,"custom fill is removed when the real inset is present")
RevathsEnchantedFrames_ResetClassicSurface(surface)
assert(surface.revathsClassicInset.hidden and insetBg.hidden,"Modern restores its own panel art")
print("Native HUD tests passed: opt-in, reuse, transparent chrome and click-through decoration.")
