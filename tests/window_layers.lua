assert(loadfile("RevathsEnchantedFrames/Hud.lua"))()
local function Frame(level,children)
    local f={level=level,children=children or {},hooks={}}
    function f:GetFrameLevel() return self.level end
    function f:GetChildren() return unpack(self.children) end
    function f:SetToplevel(v) self.toplevel=v end
    function f:HookScript(event,fn) self.hooks[event]=fn end
    function f:SetFrameLevel(v)
        local delta=v-self.level
        self.level=v
        for _,child in ipairs(self.children) do child:SetFrameLevel(child.level+delta) end
    end
    return f
end
local button=Frame(511)
local title=Frame(510,{button})
local whispers=Frame(1,{title})
local mailbox=Frame(1,{Frame(2)})
RevathsEnchantedFrames_NormalizeWindowLayers(whispers)
RevathsEnchantedFrames_NormalizeWindowLayers(mailbox)
assert(title.level==whispers.level+1 and button.level==title.level+1,"native template's 500-level offsets are removed")
assert(mailbox.level>button.level,"the foreground window covers all controls of the other window")
button.hooks.OnMouseDown()
assert(whispers.level>mailbox.children[1].level,"clicking a child brings its entire window forward")
mailbox.hooks.OnShow()
assert(mailbox.level>button.level,"opening another frame covers native whisper controls")
for i=1,100 do button.hooks.OnMouseDown(); mailbox.hooks.OnMouseDown() end
assert(mailbox.level<=80 and whispers.level<=80,"repeated focus cannot accumulate huge frame levels")
print("Window layering tests passed: native offsets, overlapping controls, child clicks, reopening and bounded levels.")
