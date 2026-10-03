-- Exercise actual window construction and chat switching without a live WoW client.
local allowed={SetText=true,GetText=true,SetPoint=true,ClearAllPoints=true,SetSize=true,GetSize=true,GetWidth=true,GetHeight=true,
    SetWidth=true,SetHeight=true,SetJustifyH=true,SetTextColor=true,SetFont=true,SetAlpha=true,SetAutoFocus=true,SetMaxLetters=true,
    SetScript=true,RegisterEvent=true,Show=true,Hide=true,SetShown=true,IsShown=true,SetEnabled=true,Enable=true,Disable=true,
    SetFocus=true,ClearFocus=true,EnableMouse=true,EnableMouseWheel=true,SetBackdrop=true,SetBackdropColor=true,
    SetBackdropBorderColor=true,SetFrameLevel=true,GetFrameLevel=true,SetFrameStrata=true,SetAllPoints=true,SetTexture=true,
    SetNormalTexture=true,SetHighlightTexture=true,SetTitle=true,SetClampedToScreen=true,SetMovable=true,SetResizable=true,
    SetResizeBounds=true,RegisterForDrag=true,RegisterForClicks=true,StartMoving=true,StartSizing=true,StopMovingOrSizing=true,
    GetCenter=true,GetEffectiveScale=true,SetFading=true,SetMaxLines=true,SetSpacing=true,SetHyperlinksEnabled=true,
    AtBottom=true,GetScrollOffset=true,SetScrollOffset=true,Clear=true,AddMessage=true,ScrollToBottom=true,ScrollUp=true,ScrollDown=true}
local function Widget(parent,kind)
    local w={parent=parent,kind=kind,scripts={},shown=true,text="",messages={},width=138,height=256}
    return setmetatable(w,{__index=function(self,key)
        if key=="CreateFontString" or key=="CreateTexture" then return function() return Widget(self,"region") end end
        assert(allowed[key],"Unexpected widget method: "..key)
        return function(_,a,b)
            if key=="SetScript" then self.scripts[a]=b
            elseif key=="SetText" then self.text=a; if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self) end
            elseif key=="GetText" then return self.text
            elseif key=="SetSize" then self.width,self.height=a,b
            elseif key=="GetSize" then return self.width,self.height
            elseif key=="SetWidth" then self.width=a
            elseif key=="GetWidth" then return self.width
            elseif key=="SetHeight" then self.height=a
            elseif key=="GetHeight" then return self.height
            elseif key=="SetShown" then self.shown=a
            elseif key=="Show" then self.shown=true; if self.scripts.OnShow then self.scripts.OnShow(self) end
            elseif key=="Hide" then self.shown=false; if self.scripts.OnHide then self.scripts.OnHide(self) end
            elseif key=="IsShown" then return self.shown
            elseif key=="Enable" then assert(self.kind=="EditBox"); self.enabled=true
            elseif key=="Disable" then assert(self.kind=="EditBox"); self.enabled=false
            elseif key=="SetEnabled" then assert(self.kind=="Button","SetEnabled is a Button API"); self.enabled=a
            elseif key=="SetFocus" then self.focused=true
            elseif key=="ClearFocus" then self.focused=false
            elseif key=="GetFrameLevel" then return 1
            elseif key=="GetCenter" then return 500,400
            elseif key=="GetEffectiveScale" then return 1
            elseif key=="AtBottom" then return true
            elseif key=="GetScrollOffset" then return 0
            elseif key=="Clear" then self.messages={}
            elseif key=="AddMessage" then self.messages[#self.messages+1]=a
            end
        end
    end})
end
CreateFrame=function(kind,_,parent,template)
    local w=Widget(parent,kind)
    if template=="ButtonFrameTemplate" then w.NineSlice=Widget(w); w.Bg=Widget(w); w.TitleBg=Widget(w); w.TitleText=Widget(w); w.TitleContainer=Widget(w); w.PortraitContainer={portrait=Widget(w)}; w.Inset=Widget(w); w.Inset.Bg=Widget(w.Inset); w.Inset.NineSlice=Widget(w.Inset) end
    return w
end
UIParent=Widget(); Minimap=Widget(); UISpecialFrames={}; StaticPopupDialogs={}; SlashCmdList={}
YES,NO="Yes","No"; date=function() return "12:00" end
RevathsEnchantedFrames_ApplyFont=function(object,key,size) object.fontKey,object.fontSize=key,size end
time=function() return 100 end; UnitGUID=function() return "UI-Test" end
PlaySound=function() end; C_ChatInfo={InChatMessagingLockdown=function() return false end,SendChatMessage=function() end}
C_BattleNet={GetFriendAccountInfo=function() return {accountName="Friend",bnetAccountID=42,gameAccountInfo={isOnline=true}} end,
    GetAccountInfoByID=function() return {battleTag="Friend#1234"} end,SendWhisper=function() return true end}
BNGetNumFriends=function() return 1 end
local ns={}
assert(loadfile("RevathsWhispers/Core.lua"))("RevathsWhispers",ns)
assert(loadfile("RevathsWhispers/UI.lua"))("RevathsWhispers",ns)
ns:Initialize(); ns:Build()
assert(ns.frame.width==540 and ns.frame.height==360 and not ns.frame.shown)
assert(ns.sidebar.width==138)
ns:Start("Alice-Realm")
assert(ns.frame.shown and ns.compose.enabled and ns.compose.focused)
local alice=ns.store.chats[ns.selected]
ns.compose:SetText("Alice draft")
ns:Start("Bob-Realm"); local bob=ns.store.chats[ns.selected]
ns.compose:SetText("Bob draft")
ns:Select(alice.key)
assert(ns.compose:GetText()=="Alice draft" and bob.draft=="Bob draft")
ns.compose.scripts.OnEnterPressed(ns.compose)
assert(ns.compose:GetText()=="" and alice.draft=="")
ns:RefreshFriends()
assert(ns.friends.rows[1].text=="Friend" and ns.friends.rows[1].enabled)
ns.friends.rows[1].scripts.OnClick(ns.friends.rows[1])
assert(ns.selected=="bn:friend#1234" and ns.compose.enabled)
ns.db.settings.skin="modern"; ns.db.settings.font="arial"; ns:ApplyAppearance()
assert(not ns.frame.NineSlice.shown and ns.frame.custom.shown and ns.compose.fontKey=="arial")
ns.db.settings.skin="classic"; ns:ApplyAppearance()
assert(ns.frame.NineSlice.shown and not ns.frame.custom.shown)
ns.frame.scripts.OnHide(); assert(not ns.compose.focused and not ns.friends.shown)
print("Whisper UI tests passed: construction, compact size, draft switching, send, friends, appearance and focus cleanup.")
