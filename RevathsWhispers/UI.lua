local _, ns = ...
local function Label(parent, text, size)
    local f = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f:SetText(text or ""); f:SetJustifyH("LEFT")
    RevathsEnchantedFrames_ApplyFont(f, ns.db.settings.font, size or 12)
    return f
end
local function Button(parent, text, width, click)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(width, 22); b:SetText(text); b:SetScript("OnClick", click)
    return b
end
local function Input(parent, width)
    local e = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    e:SetSize(width, 22); e:SetAutoFocus(false); e:SetMaxLetters(255)
    e:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    RevathsEnchantedFrames_ApplyFont(e, ns.db.settings.font, ns.db.settings.fontSize)
    return e
end

function ns:ApplyAppearance()
    if not self.frame then return end
    local s, f = self.db.settings, self.frame
    s.skin = s.skin == "modern" and "modern" or "classic"
    local native = s.skin == "classic"
    if f.NineSlice then f.NineSlice:SetShown(native) end
    if f.Bg then f.Bg:SetShown(native) end
    if f.TitleBg then f.TitleBg:SetShown(native) end
    f.custom:SetShown(not native)
    f.custom:SetBackdropColor(.04, .06, .09, s.opacity)
    f.custom:SetBackdropBorderColor(.32, .39, .48, 1)
    if f.Bg then f.Bg:SetAlpha(s.opacity) end
    for _, object in ipairs(self.fontObjects) do
        RevathsEnchantedFrames_ApplyFont(object, s.font, object == self.transcript and s.fontSize or 12)
    end
    self.sidebar:SetBackdropColor(.035, .045, .065, s.opacity)
    self:Refresh(true)
end

function ns:Open(key)
    if not self.frame then return end
    self.frame:Show()
    if key then self:Select(key) else self:Refresh(true) end
end
function ns:Toggle()
    if self.frame:IsShown() then self.frame:Hide() else self:Open() end
end

function ns:Start(target)
    local chat = self:GetChat("wow", target, target)
    if chat then self:Open(chat.key); self.compose:SetFocus()
    else self.status:SetText("Enter a character name, optionally Name-Realm.") end
end

function ns:Refresh(full, changed)
    if not self.frame then return end
    local locked = self:Locked()
    self.send:SetEnabled(not locked)
    self.status:SetText(locked and "Restricted here; drafts saved. Use Blizzard chat." or "Enter to send • Drafts saved when switching chats")
    local unread = 0
    for _, c in pairs(self.store.chats) do unread = unread + (c.unread or 0) end
    self.minimap.badge:SetText(unread > 0 and tostring(unread) or "")
    if not self.frame:IsShown() then self.dirty = true; return end
    local chats = self:Conversations(self.search:GetText())
    local count = math.max(1, math.floor((self.sidebar:GetHeight() - 44) / 34))
    self.offset = math.max(0, math.min(self.offset or 0, math.max(0, #chats - count)))
    for i = 1, math.max(count, #self.rows) do
        local row = self.rows[i]
        if not row and i <= count then
            row = CreateFrame("Button", nil, self.sidebar, "BackdropTemplate")
            row:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"})
            row.name = Label(row, "", 12); row.name:SetPoint("TOPLEFT", 6, -5); row.name:SetPoint("RIGHT", -6, 0)
            row.detail = Label(row, "", 10); row.detail:SetPoint("BOTTOMLEFT", 6, 3)
            row:SetScript("OnClick", function(b) self:Select(b.key) end)
            row:SetScript("OnEnter", function(b)
                local c = self.store.chats[b.key]
                if c then GameTooltip:SetOwner(b,"ANCHOR_RIGHT"); GameTooltip:SetText(c.label); GameTooltip:AddLine(c.kind == "bn" and "Battle.net whisper" or "Character whisper", .6,.8,1); GameTooltip:Show() end
            end)
            row:SetScript("OnLeave", function() GameTooltip:Hide() end)
            self.rows[i] = row
            self.fontObjects[#self.fontObjects+1]=row.name
            self.fontObjects[#self.fontObjects+1]=row.detail
        end
        if row then
            local c = i <= count and chats[i+self.offset]
            row:SetShown(c ~= nil)
            if c then
                row.key = c.key; row:ClearAllPoints(); row:SetPoint("TOPLEFT", 3, -36-(i-1)*34); row:SetPoint("RIGHT", -3, 0); row:SetHeight(32)
                row.name:SetText(c.label)
                row.detail:SetText((c.unread or 0) > 0 and ("|cff65e0ff" .. c.unread .. " unread|r") or (c.draft ~= "" and "|cffffcc66Draft|r" or (c.kind == "bn" and "Battle.net" or "WoW")))
                row:SetBackdropColor(c.key == self.selected and .10 or .04, c.key == self.selected and .22 or .06, c.key == self.selected and .28 or .09, .9)
            end
        end
    end
    local chat = self.selected and self.store.chats[self.selected]
    if full or self.dirty or (chat and changed == chat.key) then
        local atBottom = self.transcript:AtBottom()
        local oldOffset = self.transcript:GetScrollOffset()
        self.transcript:Clear()
        self.chatTitle:SetText(chat and chat.label or "Choose a conversation")
        if chat then
            chat.unread = 0
            for _, m in ipairs(chat.messages) do
                self.transcript:AddMessage(date("%H:%M", m.at) .. "  " .. (m.outgoing and "You" or chat.label) .. ": " .. m.text,
                    m.outgoing and .5 or .95, m.outgoing and .85 or .55, 1)
            end
            if #chat.messages == 0 then self.transcript:AddMessage("Start a conversation. Your draft stays here when switching chats.", .6,.7,.8) end
        else self.transcript:AddMessage("New whisper: enter Name-Realm above.\nBattle.net: choose Friends.\nSelect chats in the compact list on the left.", .6,.7,.8) end
        if full or atBottom then self.transcript:ScrollToBottom() else self.transcript:SetScrollOffset(oldOffset) end
        self.loadingDraft = true; self.compose:SetText(chat and chat.draft or ""); self.loadingDraft = false
        if chat then self.compose:Enable() else self.compose:Disable() end
        self.delete:SetEnabled(chat ~= nil)
        self.dirty = false
    end
end

function ns:Build()
    local s = self.db.settings
    local f = CreateFrame("Frame", "RevathsEnchantedWhispersFrame", UIParent, "PortraitFrameTemplate")
    self.frame = f
    f:SetSize(math.max(440, math.min(900, tonumber(s.width) or 540)), math.max(280, math.min(700, tonumber(s.height) or 360)))
    f:SetPoint("CENTER", UIParent, "CENTER", tonumber(s.x) or 0, tonumber(s.y) or 0)
    f:SetClampedToScreen(true); f:SetMovable(true); f:SetResizable(true); f:SetResizeBounds(440, 280, 900, 700)
    f:SetFrameStrata("DIALOG"); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function() f:StartMoving() end)
    local function SavePosition()
        f:StopMovingOrSizing()
        local x,y=f:GetCenter(); local px,py=UIParent:GetCenter(); s.x,s.y=x-px,y-py
        s.width,s.height=f:GetSize()
    end
    f:SetScript("OnDragStop", SavePosition)
    if f.SetTitle then f:SetTitle("Revath's Enchanted Whispers") elseif f.TitleText then f.TitleText:SetText("Revath's Enchanted Whispers") end
    if f.PortraitContainer and f.PortraitContainer.portrait then f.PortraitContainer.portrait:SetTexture(self.icon)
    elseif f.portrait then f.portrait:SetTexture(self.icon) end
    f.custom = CreateFrame("Frame", nil, f, "BackdropTemplate")
    f.custom:SetAllPoints(); f.custom:SetFrameLevel(f:GetFrameLevel())
    f.custom:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12,insets={left=3,right=3,top=3,bottom=3}})
    local header = Label(f, "Revath's Enchanted Whispers"); header:SetPoint("TOPLEFT", 64, -8)
    if f.TitleText then header:Hide() end
    self.fontObjects={header}
    self.newTarget=Input(f,120); self.newTarget:SetPoint("TOPLEFT",24,-36)
    self.newTarget:SetScript("OnEnterPressed", function(e) self:Start(e:GetText()); e:ClearFocus() end)
    local new=Button(f,"New",48,function() self:Start(self.newTarget:GetText()) end); new:SetPoint("LEFT", self.newTarget,"RIGHT",6,0)
    local friends=Button(f,"Friends",64,function() self.friends:SetShown(not self.friends:IsShown()); self:RefreshFriends() end); friends:SetPoint("LEFT",new,"RIGHT",4,0)
    local settings=Button(f,"Settings",72,function() if RevathsEnchantedWhispers_Settings then RevathsEnchantedWhispers_Settings() end end); settings:SetPoint("TOPRIGHT",-24,-36)
    self.sidebar=CreateFrame("Frame",nil,f,"BackdropTemplate"); self.sidebar:SetPoint("TOPLEFT",16,-68); self.sidebar:SetPoint("BOTTOMLEFT",16,36); self.sidebar:SetWidth(138)
    self.sidebar:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"}); self.sidebar:EnableMouseWheel(true)
    self.sidebar:SetScript("OnMouseWheel",function(_,delta) self.offset=(self.offset or 0)-delta; self:Refresh(false) end)
    self.search=Input(self.sidebar,112); self.search:SetPoint("TOPLEFT",10,-8); self.search:SetMaxLetters(80)
    self.search:SetScript("OnTextChanged",function() self.offset=0; self:Refresh(false) end)
    self.rows={}
    self.chatTitle=Label(f, "Choose a conversation"); self.chatTitle:SetPoint("TOPLEFT",self.sidebar,"TOPRIGHT",10,-5); self.chatTitle:SetPoint("RIGHT",-83,0)
    self.delete=Button(f,"Clear",52,function()
        if self.selected then StaticPopup_Show("REVATHS_WHISPERS_CLEAR", nil,nil,self.selected) end
    end); self.delete:SetPoint("TOPRIGHT",-20,-70)
    self.transcript=CreateFrame("ScrollingMessageFrame",nil,f)
    self.transcript:SetPoint("TOPLEFT",self.sidebar,"TOPRIGHT",10,-28); self.transcript:SetPoint("BOTTOMRIGHT",-20,78)
    self.transcript:SetJustifyH("LEFT"); self.transcript:SetFading(false); self.transcript:SetMaxLines(110); self.transcript:SetSpacing(4)
    self.transcript:EnableMouseWheel(true); self.transcript:SetHyperlinksEnabled(true)
    self.transcript:SetScript("OnMouseWheel",function(t,delta) if delta>0 then t:ScrollUp() else t:ScrollDown() end end)
    self.transcript:SetScript("OnHyperlinkClick",function(_,link,text,button) SetItemRef(link,text,button) end)
    self.compose=Input(f,250); self.compose:SetPoint("BOTTOMLEFT",self.sidebar,"BOTTOMRIGHT",12,3); self.compose:SetPoint("RIGHT",f,"RIGHT",-82,0)
    self.compose:SetScript("OnTextChanged",function(e)
        local c=self.selected and self.store.chats[self.selected]
        if c and not self.loadingDraft then c.draft=e:GetText() end
    end)
    local function Send()
        local chat=self.selected and self.store.chats[self.selected]
        local ok,message=self:Send(chat,self.compose:GetText())
        if ok then self.compose:SetText("") else self.status:SetText(message) end
    end
    self.compose:SetScript("OnEnterPressed",Send)
    self.send=Button(f,"Send",56,Send); self.send:SetPoint("LEFT",self.compose,"RIGHT",8,0)
    self.status=Label(f, "",10); self.status:SetPoint("BOTTOMLEFT",20,12); self.status:SetPoint("RIGHT",-28,0)
    self.fontObjects[#self.fontObjects+1]=self.chatTitle; self.fontObjects[#self.fontObjects+1]=self.status
    self.fontObjects[#self.fontObjects+1]=self.search; self.fontObjects[#self.fontObjects+1]=self.newTarget
    self.fontObjects[#self.fontObjects+1]=self.compose; self.fontObjects[#self.fontObjects+1]=self.transcript
    local resize=CreateFrame("Button",nil,f); resize:SetSize(18,18); resize:SetPoint("BOTTOMRIGHT",-5,5)
    resize:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resize:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resize:SetScript("OnMouseDown",function(_,b) if b=="LeftButton" then f:StartSizing("BOTTOMRIGHT") end end)
    resize:SetScript("OnMouseUp",SavePosition)
    f:SetScript("OnSizeChanged",function() self:Refresh(true) end)
    f:SetScript("OnShow",function() self:Refresh(true) end)
    f:SetScript("OnHide",function() self.compose:ClearFocus(); self.newTarget:ClearFocus(); self.friends:Hide() end)
    self:BuildFriends()
    self:BuildMinimap()
    StaticPopupDialogs.REVATHS_WHISPERS_CLEAR={text="Clear this conversation and its saved messages?",button1=YES,button2=NO,timeout=0,whileDead=true,hideOnEscape=true,OnAccept=function(_,key) self:Delete(key) end}
    UISpecialFrames[#UISpecialFrames+1]="RevathsEnchantedWhispersFrame"
    f:Hide(); self:ApplyAppearance()
    SLASH_REVATHSWHISPERS1,SLASH_REVATHSWHISPERS2="/rwhisper","/rwhispers"
    SlashCmdList.REVATHSWHISPERS=function(target) if target and target~="" then self:Start(target) else self:Toggle() end end
    RevathsEnchantedWhispers_Open=function() self:Toggle() end
    RevathsEnchantedWhispers_ApplySettings=function() self:ApplyAppearance() end
    RevathsEnchantedWhispers_TestSound=function() self:Notify() end
end

function ns:BuildFriends()
    local f=CreateFrame("Frame",nil,self.frame,"BackdropTemplate"); self.friends=f
    f:SetSize(240,210); f:SetPoint("TOPLEFT",180,-62); f:SetFrameLevel(self.frame:GetFrameLevel()+20)
    f:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12}); f:SetBackdropColor(.04,.06,.09,1)
    f.offset=0; f.rows={}; f:EnableMouseWheel(true)
    f:SetScript("OnMouseWheel",function(_,d) f.offset=math.max(0,f.offset-d); self:RefreshFriends() end)
    for i=1,7 do
        local b=Button(f,"",220,function(row)
            local c=self:GetChat("bn",row.accountID,row.label)
            if c then self:Select(c.key); self.compose:SetFocus() end
            f:Hide()
        end)
        b:SetPoint("TOPLEFT",10,-10-(i-1)*27); f.rows[i]=b
    end
    f:Hide()
end
function ns:RefreshFriends()
    local contacts={}
    if BNGetNumFriends and C_BattleNet and C_BattleNet.GetFriendAccountInfo then
        for i=1,BNGetNumFriends() do
            local info=C_BattleNet.GetFriendAccountInfo(i)
            local game=info and info.gameAccountInfo
            if info and game and ns.Public(info.accountName) and ns.Public(info.bnetAccountID) and ns.Public(game.isOnline) and game.isOnline and type(info.accountName)=="string" and type(info.bnetAccountID)=="number" then
                contacts[#contacts+1]=info
            end
        end
    end
    self.friends.offset=math.min(self.friends.offset,math.max(0,#contacts-7))
    for i,b in ipairs(self.friends.rows) do
        local info=contacts[i+self.friends.offset]
        b:SetShown(info~=nil or i==1 and #contacts==0)
        b:SetEnabled(info~=nil)
        b:SetText(info and info.accountName or "No online Battle.net friends")
        if info then b.accountID,b.label=info.bnetAccountID,info.accountName end
    end
end
function ns:BuildMinimap()
    local b=CreateFrame("Button","RevathsWhispersMinimapButton",Minimap); self.minimap=b
    b:SetSize(32,32); b:SetFrameStrata("MEDIUM"); b:SetFrameLevel(8)
    local icon=b:CreateTexture(nil,"ARTWORK"); icon:SetAllPoints(); icon:SetTexture(self.icon)
    b.badge=Label(b,"",11); b.badge:SetPoint("BOTTOMRIGHT",2,-2); b.badge:SetTextColor(.3,1,1)
    local function Position()
        local a=math.rad(tonumber(self.db.settings.minimapAngle) or 220)
        b:ClearAllPoints(); b:SetPoint("CENTER",Minimap,"CENTER",math.cos(a)*80,math.sin(a)*80)
    end
    b:RegisterForClicks("LeftButtonUp","RightButtonUp"); b:RegisterForDrag("LeftButton")
    b:SetScript("OnClick",function(_,button) if button=="RightButton" then if RevathsEnchantedWhispers_Settings then RevathsEnchantedWhispers_Settings() end else self:Toggle() end end)
    b:SetScript("OnDragStart",function() b:SetScript("OnUpdate",function()
        local x,y=GetCursorPosition(); local mx,my=Minimap:GetCenter(); local scale=Minimap:GetEffectiveScale()
        self.db.settings.minimapAngle=math.deg(math.atan2(y/scale-my,x/scale-mx)); Position()
    end) end)
    b:SetScript("OnDragStop",function() b:SetScript("OnUpdate",nil) end)
    b:SetScript("OnEnter",function() GameTooltip:SetOwner(b,"ANCHOR_LEFT"); GameTooltip:SetText("Revath's Enchanted Whispers"); GameTooltip:AddLine("Click: chats • Right-click: settings",1,1,1); GameTooltip:AddLine("Drag to move. Cyan number: unread messages.",.6,.8,1); GameTooltip:Show() end)
    b:SetScript("OnLeave",function() GameTooltip:Hide() end)
    Position()
end
