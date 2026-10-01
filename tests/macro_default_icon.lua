-- Exercise the actual editor/save functions without constructing the whole macro UI.
local sourceFile = assert(io.open("RevathsMacro/UI.lua", "r"))
local source = sourceFile:read("*a"); sourceFile:close()
local editor = assert(source:match("(local function SetEditor%(record%).-\nend)\n\nlocal ICON_COLUMNS"))
local saver = assert(source:match("(local function SaveMacro%(%).-\nend)\n\nlocal function DeleteSelectedMacro"))
local setup = [[
local selectedRecord, selectedIcon, activeSource = nil,nil,"account"
local function Widget()
    return {SetText=function(self,value) self.text=value end, GetText=function(self) return self.text or "" end,
        SetShown=function() end, SetTexture=function(self,value) self.texture=value end}
end
local macroName,macroBody,iconPreview = Widget(),Widget(),Widget()
local sourceBox,sourceLabel,noteText,deleteButton = Widget(),Widget(),Widget(),Widget()
local SetStatus = function() end
local SelectSource = function() end
local created,edited
CreateMacro=function(name,icon,body,isCharacter) created={name=name,icon=icon,body=body,isCharacter=isCharacter}; return 1 end
EditMacro=function(index,name,icon,body) edited={index=index,name=name,icon=icon,body=body}; return index end
GetFileIDFromPath=function() return 12345 end
]]
local checks = [[
SetEditor(nil)
assert(selectedIcon==134400 and iconPreview.texture==134400, "blank macro defaults to automatic question-mark icon")
macroName:SetText("Ice Lance"); macroBody:SetText("#showtooltip Ice Lance\n/cast Ice Lance")
SaveMacro()
assert(created and created.icon==134400 and created.body:find("#showtooltip Ice Lance",1,true), "automatic icon passed unchanged to CreateMacro")
SetEditor({index=1,kind="account",name="Custom",icon=999,body="#showtooltip Ice Lance\n/cast Ice Lance"})
SaveMacro(); assert(edited and edited.icon==999, "existing explicitly selected icon stays unchanged")
SetEditor(nil); selectedIcon="Interface\\Icons\\INV_Misc_Note_01"
macroName:SetText("Custom paper"); macroBody:SetText("/say Hello")
SaveMacro(); assert(created.icon==12345, "user can still select a fixed custom icon")
print("Macro icon tests passed: automatic new icon, #showtooltip body, existing icon preservation and custom selection.")
]]
assert(loadstring(setup .. editor .. "\n" .. saver .. "\n" .. checks))()
