local file=assert(io.open("RevathsWeeklyPlanner/UI.lua","r"))
local source=file:read("*a"); file:close()
local body=assert(source:match("local function Style%(surface%)(.-)\nend\n\nlocal function Button"))
ns={db={skin="classic",opacity=.6}}
local role
RevathsEnchantedFrames_StyleClassicSurface=function(_,value) role=value end
local style=assert(loadstring("return function(surface) "..body.." end"))()
style({kindButton=true,classicRow=true,role="button"})
assert(role=="panel","goal and character rows cannot receive red native button art")
style({kindButton=true,role="button"})
assert(role=="button","navigation and action controls keep native button styling")
print("Classic row tests passed: inset list rows and native action buttons stay distinct.")
