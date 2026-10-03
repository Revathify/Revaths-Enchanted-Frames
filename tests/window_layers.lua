assert(loadfile("RevathsEnchantedFrames/Hud.lua"))()
local function Frame(level,children,kind)
    local f={level=level,children=children or {},hooks={},kind=kind or "Frame",mouse=kind=="Button"}
    function f:GetObjectType() return self.kind end
    function f:GetFrameLevel() return self.level end
    function f:GetChildren() return unpack(self.children) end
    function f:SetToplevel(v) self.toplevel=v end
    function f:HookScript(event,fn)
        self.hooks[event]=fn
        -- WoW mouse-script registration opts Frames into mouse handling.
        if event=="OnMouseDown" or event=="OnMouseUp" then self.mouse=true end
    end
    function f:SetFrameLevel(v)
        local delta=v-self.level
        self.level=v
        for _,child in ipairs(self.children) do child:SetFrameLevel(child.level+delta) end
    end
    return f
end
local button=Frame(511,nil,"Button")
local title=Frame(510,{button})
local whispers=Frame(1,{title})
local mailbox=Frame(1,{Frame(2)})
RevathsEnchantedFrames_NormalizeWindowLayers(whispers)
RevathsEnchantedFrames_NormalizeWindowLayers(mailbox)
assert(title.level==whispers.level+1 and button.level==title.level+1,"native template's 500-level offsets are removed")
assert(mailbox.level>button.level,"the foreground window covers all controls of the other window")
assert(not title.mouse and not title.hooks.OnMouseDown and not title.hooks.OnMouseUp,"decorative chrome stays click-through")
assert(not button.hooks.OnMouseDown,"pressed buttons are never moved between mouse down and click")
button.hooks.OnClick()
assert(whispers.level>mailbox.children[1].level,"clicking a child brings its entire window forward")
mailbox.hooks.OnShow()
assert(mailbox.level>button.level,"opening another frame covers native whisper controls")
for i=1,100 do button.hooks.OnClick(); mailbox.hooks.OnMouseUp() end
assert(mailbox.level<=80 and whispers.level<=80,"repeated focus cannot accumulate huge frame levels")
local settings=Frame(2,nil,"Button")
local fullWindowChrome=Frame(500)
local classic=Frame(1,{settings,fullWindowChrome})
RevathsEnchantedFrames_NormalizeWindowLayers(classic)
assert(not fullWindowChrome.mouse,"the full-window Classic overlay must never capture Settings clicks")
local hit
for _,child in ipairs(classic.children) do if child.mouse then hit=child end end
assert(hit==settings,"hit testing reaches Settings through the native overlay")
local opened=false
local function ClickSettings()
    opened=true -- Original OnClick callback runs before the focus hook.
    settings.hooks.OnClick()
end
ClickSettings(); assert(opened)
print("Window layering tests passed: native offsets, overlapping controls, child clicks, reopening and bounded levels.")
