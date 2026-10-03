local ns = {store={}, compose={SetFocus=function(self) self.focus=true end}}
local restricted=false
ns.Public=function(v) return type(v)~="table" or not v.secret end
ns.Locked=function() return restricted end
ns.GetChat=function(self,kind,target,label)
    if target==nil then return end
    local key=kind..":"..tostring(target)
    self.store[key]=self.store[key] or {key=key,draft="saved draft"}
    return self.store[key]
end
ns.Open=function(self,key) self.opened=key end
local box={focused=true,kind="WHISPER",target="Alice-Realm",text="hello",ParseText=function() end,UpdateHeader=function() end}
box.HasFocus=function(self) return self.focused end
box.GetChatType=function(self) return self.kind end
box.GetTellTarget=function(self) return self.target end
box.GetText=function(self) return self.text end
local queue,hooks={},{}
C_Timer={After=function(_,fn) queue[#queue+1]=fn end}
ChatFrameUtil={ActivateChat=function() end,DeactivateChat=function(b) b.focused=false end}
ChatFrame1={editBox=box}; NUM_CHAT_WINDOWS=1
hooksecurefunc=function(object,key,fn) hooks[object]=hooks[object] or {}; hooks[object][key]=fn end
BNet_GetBNetIDAccount=function(name) assert(name=="Friend"); return 42 end
assert(loadfile("RevathsWhispers/ChatIntegration.lua"))("RevathsWhispers",ns)
ns:InstallChatIntegration()
hooks[box].ParseText(box); hooks[box].UpdateHeader(box)
assert(#queue==1,"header and parser hooks coalesce into one handoff")
queue[1]()
assert(ns.opened=="wow:Alice-Realm" and not box.focused and ns.compose.focus)
assert(ns.store[ns.opened].draft=="hello","typed text becomes a draft, never a sent message")
box.focused=true; box.text=""; ns:HandOffWhisper(box)
assert(ns.store[ns.opened].draft=="hello","opening reply retains the existing draft")
box.focused=true; box.kind="BN_WHISPER"; box.target="Friend"; box.text="BNet draft"
ns:HandOffWhisper(box); assert(ns.opened=="bn:42" and ns.store[ns.opened].draft=="BNet draft")
ns.opened=nil; box.focused=true; restricted=true; ns:HandOffWhisper(box)
assert(not ns.opened and box.focused,"restricted chat keeps Blizzard input untouched")
restricted=false; box.target={secret=true}; ns:HandOffWhisper(box)
assert(not ns.opened and box.focused)
box.target="Alice-Realm"; box.kind="SAY"; ns:HandOffWhisper(box); assert(not ns.opened)
box.kind="WHISPER"; box.text="/w Unparsed"; ns:HandOffWhisper(box); assert(not ns.opened)
box.text="Already sent"; box.focused=false; ns:HandOffWhisper(box); assert(not ns.opened)
print("Whisper handoff tests passed: coalescing, drafts, reply, BNet, restrictions, secret values and unrelated chat.")
