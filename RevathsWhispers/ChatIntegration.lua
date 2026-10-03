local _, ns = ...

function ns:HandOffWhisper(editBox)
    if not self.store or not self.compose or self:Locked() or not editBox:HasFocus() then return end
    local kind, target, text = editBox:GetChatType(), editBox:GetTellTarget(), editBox:GetText()
    if not self.Public(kind) or not self.Public(target) or not self.Public(text) then return end
    if kind ~= "WHISPER" and kind ~= "BN_WHISPER" then return end
    if type(text) ~= "string" or text:sub(1,1) == "/" then return end
    local label = target
    if kind == "BN_WHISPER" then
        if type(target) ~= "string" or not BNet_GetBNetIDAccount then return end
        target = BNet_GetBNetIDAccount(target)
    end
    local chat = self:GetChat(kind == "WHISPER" and "wow" or "bn", target, label)
    if not chat then return end
    -- Only hand off after Blizzard finishes parsing the command. Never send it.
    if text ~= "" then chat.draft = text end
    ChatFrameUtil.DeactivateChat(editBox)
    self:Open(chat.key)
    self.compose:SetFocus()
end

function ns:InstallChatIntegration()
    if self.chatIntegration or not hooksecurefunc or not ChatFrameUtil or not C_Timer then return end
    self.chatIntegration = true
    local attached, pending = {}, {}
    local function Schedule(editBox)
        if pending[editBox] then return end
        pending[editBox] = true
        C_Timer.After(0, function()
            pending[editBox] = nil
            ns:HandOffWhisper(editBox)
        end)
    end
    local function Attach(editBox)
        if not editBox or attached[editBox] or not editBox.GetChatType or not editBox.GetTellTarget then return end
        attached[editBox] = true
        hooksecurefunc(editBox, "UpdateHeader", Schedule)
        -- Handles /w and /whisper after the recipient and message are parsed.
        hooksecurefunc(editBox, "ParseText", Schedule)
    end
    for i = 1, NUM_CHAT_WINDOWS or 10 do
        local chatFrame = _G["ChatFrame"..i]
        Attach(chatFrame and chatFrame.editBox)
    end
    hooksecurefunc(ChatFrameUtil, "ActivateChat", function(editBox)
        Attach(editBox)
        Schedule(editBox)
    end)
end
