local ns={}
local ticks,combat,locked=100,false,false
time=function() return ticks end
UnitGUID=function() return "Player-Test" end
CreateFrame=function() return {RegisterEvent=function() end,SetScript=function(self,_,fn) self.event=fn end} end
InCombatLockdown=function() return combat end
C_ChatInfo={InChatMessagingLockdown=function() return locked end}
issecretvalue=function(v) return type(v)=="table" and v.secret end
SOUNDKIT={TELL_MESSAGE=1,RAID_WARNING=2}
local sounds,sent=0,{}
PlaySound=function() sounds=sounds+1 end
PlaySoundFile=function() sounds=sounds+1 end
assert(loadfile("RevathsWhispers/Core.lua"))("RevathsWhispers",ns)
assert(ns:Initialize())
local alice=assert(ns:Receive("wow","Hello","Alice-Realm","Alice-Realm"))
assert(alice.unread==1 and sounds==1)
assert(ns:GetChat("wow","alice-realm")==alice,"case variants share a conversation")
alice.draft="Saved draft"; ns:Select(alice.key)
assert(alice.unread==0 and alice.draft=="Saved draft")
combat=true
assert(ns:Receive("wow","During ordinary combat","Bob-Realm","Bob-Realm"))
C_ChatInfo.SendChatMessage=function(text,kind,language,target) sent={text,kind,target} end
assert(ns:Send(alice,"Reply in combat"))
assert(sent[1]=="Reply in combat" and sent[2]=="WHISPER" and sent[3]=="Alice-Realm")
assert(#alice.messages==1,"outgoing messages are recorded only by Blizzard echo")
ns.events.event(nil,"CHAT_MSG_WHISPER_INFORM","Reply in combat","Alice-Realm")
assert(#alice.messages==2 and alice.messages[2].outgoing)
locked=true
assert(not ns:Send(alice,"Keep this")); assert(alice.draft=="Keep this")
assert(not ns:Receive("wow","Restricted","Alice-Realm","Alice-Realm"))
locked=false
ns.events.event(nil,"ADDON_RESTRICTION_STATE_CHANGED",2,2)
assert(not ns:Send(alice,"Challenge draft")); assert(alice.draft=="Challenge draft")
ns.events.event(nil,"ADDON_RESTRICTION_STATE_CHANGED",2,0)
local secret=setmetatable({secret=true},{__tostring=function() error("Secret converted") end})
assert(not ns:Receive("wow",secret,"Alice-Realm","Alice-Realm"))
assert(not ns:Receive("wow","Text",secret,"Alice-Realm"))
assert(not ns:Receive("wow","Text","Alice-Realm",secret))
assert(not ns:Send(alice,string.rep("x",256)))
C_ChatInfo.SendChatMessage=function() error("Cannot send") end
assert(not ns:Send(alice,"Retained after error") and alice.draft=="Retained after error")
assert(not ns:GetChat("wow","bad name"))
for i=1,120 do ticks=ticks+1; ns:Receive("wow","Message "..i,"Alice-Realm","Alice-Realm",true) end
assert(#alice.messages==100 and alice.messages[1].text=="Message 21","history bounded")
C_BattleNet={GetAccountInfoByID=function(id) return {battleTag=id==10 and "Friend#1234" or "Different#5678"} end,
SendWhisper=function(id,text) sent={id,text} end}
local bn=assert(ns:Receive("bn","BNet hello",10,"Friend"))
assert(bn.key=="bn:friend#1234" and ns:Send(bn,"BNet reply"))
assert(sent[1]==10 and sent[2]=="BNet reply")
assert(ns:Initialize())
assert(not ns:Send(bn,"After relog"),"stale account IDs cannot send after relog")
local other=assert(ns:GetChat("bn",11,"Different"))
assert(other~=bn and not ns:Send(bn,"Wrong session target"))
assert(ns:GetChat("bn",10,"Friend")==bn and ns:Send(bn,"Reconnected"))
local eventCount=#bn.messages
ns.events.event(nil,"CHAT_MSG_BN_WHISPER","Event","Friend",nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,10)
assert(#bn.messages==eventCount+1,"BNet event account ID is argument 13")
-- Capacity retains drafts and unread messages instead of deleting them to make room.
ns.store.chats={}; ns.selected=nil
for i=1,50 do local c=ns:GetChat("wow","Alt"..i,"Alt"..i); c.draft="Keep" end
assert(not ns:GetChat("wow","Overflow","Overflow"))
local victim=ns.store.chats["wow:alt1"]; victim.draft=""; victim.unread=0
assert(ns:GetChat("wow","Replacement","Replacement") and not ns.store.chats[victim.key])
print("Whispers tests passed: drafts, combat, restrictions, secret data, echoes, bounds and Battle.net identity.")
