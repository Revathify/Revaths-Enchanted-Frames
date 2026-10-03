local created=0
local function Part() return {Hide=function(self) self.hidden=true end,EnableMouse=function(self,v) self.mouse=v end} end
CreateFrame=function(_,_,parent,template)
    assert(template=="PortraitFrameTemplate")
    created=created+1
    local region=Part()
    return {parent=parent,NineSlice=Part(),Bg=Part(),PortraitContainer=Part(),CloseButton=Part(),
        SetAllPoints=function(self,p) self.anchored=p end,EnableMouse=function(self,v) self.mouse=v end,
        GetRegions=function() return region end,SetShown=function(self,v) self.shown=v end}
end
assert(loadfile("RevathsEnchantedFrames/Hud.lua"))()
local frame={}
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
assert(surface.classicTexture.hidden and surface.color[4]==.7)
assert(surface.color[1]==.035 and surface.border[4]==1,"letters use readable dark panels at the selected opacity")
RevathsEnchantedFrames_StyleClassicSurface(surface,"bg",.8)
assert(surface.border[4]==0,"native outer chrome replaces the old double border")
print("Native HUD tests passed: opt-in, reuse, transparent chrome and click-through decoration.")
