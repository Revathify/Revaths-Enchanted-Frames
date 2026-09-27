local _, ns = ...

local function ItemCount(itemID)
    if not C_Item or not C_Item.GetItemCount then return 0 end
    local ok, count = pcall(C_Item.GetItemCount, itemID, true)
    if not ok or (issecretvalue and issecretvalue(count)) or type(count) ~= "number" then return 0 end
    return count
end

local function ItemName(itemID)
    if C_Item and C_Item.GetItemNameByID then
        local ok, name = pcall(C_Item.GetItemNameByID, itemID)
        if ok and name then return name end
    end
    return "Item #" .. tostring(itemID)
end

function ns:GetTrackedMaterials()
    if not C_TradeSkillUI or not C_TradeSkillUI.GetRecipesTracked or not C_TradeSkillUI.GetRecipeSchematic then
        return {}, 0
    end
    local trackedOK, recipes = pcall(C_TradeSkillUI.GetRecipesTracked, false)
    if not trackedOK or type(recipes) ~= "table" then return {}, 0 end
    local materials = {}
    for _, recipeID in ipairs(recipes) do
        local schematicOK, schematic = pcall(C_TradeSkillUI.GetRecipeSchematic, recipeID, false)
        if schematicOK and schematic and schematic.reagentSlotSchematics then
            for slotIndex, slot in ipairs(schematic.reagentSlotSchematics) do
                local basic = not Enum.CraftingReagentType or slot.reagentType == Enum.CraftingReagentType.Basic
                if basic and slot.required ~= false and type(slot.reagents) == "table" then
                    local variants = {}
                    for _, reagent in ipairs(slot.reagents) do
                        if type(reagent.itemID) == "number" then variants[#variants + 1] = reagent.itemID end
                    end
                    if #variants > 0 then
                        local choiceKey = tostring(recipeID) .. ":" .. tostring(slotIndex)
                        local selected = self.db.reagentChoices and self.db.reagentChoices[choiceKey]
                        local itemID = variants[1]
                        for _, variant in ipairs(variants) do if variant == selected then itemID = variant; break end end
                        local required = slot.quantityRequired or 1
                        local held = ItemCount(itemID)
                        materials[#materials + 1] = {
                            recipeID = recipeID, recipeName = schematic.name or ("Recipe #" .. recipeID),
                            slotKey = choiceKey, variants = variants, itemID = itemID, name = ItemName(itemID),
                            required = required, held = held, missing = math.max(0, required - held),
                        }
                    end
                end
            end
        end
    end
    table.sort(materials, function(a, b)
        if a.recipeName == b.recipeName then return a.name < b.name end
        return a.recipeName < b.recipeName
    end)
    return materials, #recipes
end

function ns:CycleReagentVariant(material)
    if not material or not material.variants or #material.variants <= 1 then return end
    local index = 1
    for i, itemID in ipairs(material.variants) do if itemID == material.itemID then index = i; break end end
    self.db.reagentChoices = self.db.reagentChoices or {}
    self.db.reagentChoices[material.slotKey] = material.variants[index % #material.variants + 1]
end
