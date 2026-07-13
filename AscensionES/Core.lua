local AES = AscensionES or {}
AscensionES = AES

AES.SpellNameEN2ES = AES.SpellNameEN2ES or {}
AES.NameToIDs      = AES.NameToIDs or {}
AES.DescPairs      = AES.DescPairs or {}
AES.DescByID       = AES.DescByID or {}
AES.TipPairs       = AES.TipPairs or {}
AES.TipByID        = AES.TipByID or {}
AES.RankEN2ES      = AES.RankEN2ES or {}
AES.ItemName       = AES.ItemName or {}
AES.ItemNameEN     = AES.ItemNameEN or {}
AES.ItemDesc       = AES.ItemDesc or {}
AES.UnitName       = AES.UnitName or {}
AES.UnitNameEN     = AES.UnitNameEN or {}
AES.UnitSub        = AES.UnitSub or {}
AES.UnitSubEN      = AES.UnitSubEN or {}
AES.LinePatterns   = AES.LinePatterns or {}
AES.ValueWords     = AES.ValueWords or {}
AES.UIStrings      = AES.UIStrings or {}
AES.AchName        = AES.AchName or {}
AES.AchNameEN      = AES.AchNameEN or {}
AES.AchDesc        = AES.AchDesc or {}
AES.AchDescEN      = AES.AchDescEN or {}
AES.AchReward      = AES.AchReward or {}
AES.AchRewardEN    = AES.AchRewardEN or {}

local db

local defaults = { spells = true, items = true, units = false, patterns = true, flavor = true,
                   ui = true, achievements = true }

local function TranslateValue(v)
    local w = AES.ValueWords
    if w[v] then return w[v] end
    if AES.SpellNameEN2ES[v] then return AES.SpellNameEN2ES[v] end
    local num, word = v:match("^([%d%.,]+) (.+)$")
    if num and w[word] then return num .. " " .. w[word] end
    return v
end

local function ApplyTemplate(output, caps)
    return (output:gsub("{{(%d+)}}", function(n)
        local c = caps[tonumber(n)]
        if c == nil then return "" end
        return TranslateValue(c)
    end))
end

local subPatternCache = {}

local function SegmentPattern(anchored)
    local sub = subPatternCache[anchored]
    if sub == nil then
        sub = anchored
        if sub:sub(1, 1) == "^" then sub = sub:sub(2) end
        if sub:sub(-4) == "%s*$" then sub = sub:sub(1, -5) end
        subPatternCache[anchored] = sub
    end
    return sub
end

local function MatchPair(text, pair)
    local work = text
    local caps = { work:match(pair[1]) }
    if caps[1] == nil and (work:find("\r", 1, true) or work:find("|R", 1, true)) then
        work = work:gsub("\r", ""):gsub("|R", "|r")
        caps = { work:match(pair[1]) }
    end
    if caps[1] ~= nil then
        return ApplyTemplate(pair[2], caps)
    end

    local sub = SegmentPattern(pair[1])
    if #sub < 20 then return nil end
    local found = { work:find(sub) }
    local s, e = found[1], found[2]
    if not s or (e - s) < 15 then return nil end
    local segCaps = {}
    for i = 3, #found do segCaps[#segCaps + 1] = found[i] end
    if #segCaps == 0 then segCaps[1] = work:sub(s, e) end
    local translated = ApplyTemplate(pair[2], segCaps)
    return work:sub(1, s - 1) .. translated .. work:sub(e + 1)
end

local function TryPair(fs, text, pair)
    local nt = MatchPair(text, pair)
    if nt then
        pcall(fs.SetText, fs, nt)
        return true
    end
    return false
end

local function MatchPairSet(text, pairIndexes, pairsTable)
    if type(pairIndexes) == "number" then
        local pair = pairsTable[pairIndexes]
        return pair and MatchPair(text, pair) or nil
    end
    for _, idx in ipairs(pairIndexes) do
        local pair = pairsTable[idx]
        if pair then
            local nt = MatchPair(text, pair)
            if nt then return nt end
        end
    end
    return nil
end

local function NpcIdFromGUID(guid)
    if not guid then return nil end
    if guid:find("-", 1, true) then
        local unitType, rest = strsplit("-", guid, 2)
        if unitType == "Creature" or unitType == "Vehicle" or unitType == "Pet" then
            return tonumber((select(5, strsplit("-", rest))))
        end
    elseif guid:sub(1, 2) == "0x" then
        local hex = guid:sub(3)
        if #hex == 16 and hex:match("^F1[345]") then
            return tonumber(hex:sub(5, 10), 16)
        end
    end
    return nil
end

local function TooltipLines(tip)
    local name, lines = tip:GetName(), {}
    for i = 1, tip:NumLines() do
        local L = _G[name .. "TextLeft" .. i]
        local R = _G[name .. "TextRight" .. i]
        if L and L:GetText() then lines[#lines + 1] = L end
        if R and R:GetText() then lines[#lines + 1] = R end
    end
    return lines
end

local function TryPairSet(fs, text, pairIndexes, pairsTable)
    if type(pairIndexes) == "number" then
        local pair = pairsTable[pairIndexes]
        return pair and TryPair(fs, text, pair) or false
    end
    for _, idx in ipairs(pairIndexes) do
        local pair = pairsTable[idx]
        if pair and TryPair(fs, text, pair) then return true end
    end
    return false
end

local function TranslateBodyByPairs(tip, pairIndexes, pairsTable)
    if not pairIndexes then return end
    local name = tip:GetName()
    for i = 2, tip:NumLines() do
        local fs = _G[name .. "TextLeft" .. i]
        local text = fs and fs:GetText()
        if text and #text > 3 then
            if TryPairSet(fs, text, pairIndexes, pairsTable) then return true end
        end
    end
    return false
end

local function TranslateSpellWord(w)
    local map = AES.SpellNameEN2ES
    return map[w] or map[w .. "s"] or (w:sub(-1) == "s" and map[w:sub(1, -2)]) or nil
end

local function TranslateMultilineText(text)
    local contexts = {}
    local lines = {}
    local touched = false
    for line in (text .. "\n"):gmatch("(.-)\n") do
        local l = line:gsub("\r", "")
        local icon, rest = l:match("^(%s*|T[^|]*|t%s*)(.+)$")
        local body = rest or l
        local pre, nm, post = body:match("^(%s*)(.-)(%s*)$")

        local c1, inner, c2 = "", nm or "", ""
        local wc1, winner, wc2 = (nm or ""):match("^(|c%x%x%x%x%x%x%x%x)(.-)(|r)$")
        if winner then
            c1, inner, c2 = wc1, winner, wc2
        end
        local key = (inner ~= "" and AES.SpellNameEN2ES[inner]) and inner
            or (nm and AES.SpellNameEN2ES[nm]) and nm or nil
        if key then
            local es = AES.SpellNameEN2ES[key]
            if key == inner then
                l = (icon or "") .. (pre or "") .. c1 .. es .. c2 .. (post or "")
            else
                l = (icon or "") .. (pre or "") .. es .. (post or "")
            end
            touched = true
        end
        local ctxKey = (inner ~= "" and AES.NameToIDs[inner] and inner)
            or (nm and AES.NameToIDs[nm] and nm) or nil
        if ctxKey then
            contexts[#contexts + 1] = AES.NameToIDs[ctxKey]
        end
        lines[#lines + 1] = l
    end
    local joined = table.concat(lines, "\n")
    for _, ctx in ipairs(contexts) do
        for _, id in ipairs(ctx) do
            for _, pt in ipairs({ { AES.TipByID[id], AES.TipPairs }, { AES.DescByID[id], AES.DescPairs } }) do
                if pt[1] then
                    local nt = MatchPairSet(joined, pt[1], pt[2])
                    if nt then
                        joined = nt
                        touched = true
                    end
                end
            end
        end
    end
    if touched and joined ~= text then
        return joined
    end
    return nil
end

local hookedEmbedFS = setmetatable({}, { __mode = "k" })
local inEmbedHook = false
local function HookEmbedFS(fs)
    if hookedEmbedFS[fs] or not fs.SetText then return end
    hookedEmbedFS[fs] = true
    hooksecurefunc(fs, "SetText", function(self, txt)
        if inEmbedHook or not db or not db.spells then return end
        if type(txt) ~= "string" or not txt:find("\n") then return end
        local nt = TranslateMultilineText(txt)
        if nt then
            inEmbedHook = true
            pcall(self.SetText, self, nt)
            inEmbedHook = false
        end
    end)
end

local function CollectTooltipFontStrings(tip)
    local tipName = tip:GetName()
    local list, seen = {}, {}
    for i = 2, tip:NumLines() do
        local fs = _G[tipName .. "TextLeft" .. i]
        if fs then
            list[#list + 1] = fs
            seen[fs] = true
        end
    end
    local function addRegions(frame)
        if not frame or not frame.GetRegions then return end
        local ok, regions = pcall(function() return { frame:GetRegions() } end)
        if not ok then return end
        for _, r in ipairs(regions) do
            if r and not seen[r] and r.IsObjectType and r:IsObjectType("FontString") then
                local nm = r.GetName and r:GetName()
                if nm ~= tipName .. "TextLeft1" then
                    list[#list + 1] = r
                    seen[r] = true
                end
            end
        end
    end
    addRegions(tip)
    if tip.GetChildren then
        local ok, children = pcall(function() return { tip:GetChildren() } end)
        if ok then
            for _, child in ipairs(children) do
                addRegions(child)
            end
        end
    end
    return list
end

local function TranslateTooltipLines(tip)
    if not db then return end
    local tipName = tip:GetName()
    local contexts = {}
    local contextIds = nil
    for _, fs in ipairs(CollectTooltipFontStrings(tip)) do
        local text = fs and fs:GetText()
        if text and text ~= "" then
            local changed = false

            if db.spells and text:find("\n") then
                local nt = TranslateMultilineText(text)
                if nt then
                    pcall(fs.SetText, fs, nt)
                    text = nt
                    changed = false
                end
                HookEmbedFS(fs)
            end
            if db.spells then

                local icon, rest = text:match("^(|T.-|t%s*)(.+)$")
                local body = rest or text
                local pre, plainName, post = body:match("^(%s*)(.-)(%s*)$")
                local esName = plainName and AES.SpellNameEN2ES[plainName]
                if esName then
                    pcall(fs.SetText, fs, (icon or "") .. (pre or "") .. esName .. (post or ""))
                    contextIds = AES.NameToIDs[plainName]
                    if contextIds then contexts[#contexts + 1] = contextIds end
                    changed = true
                elseif plainName and AES.NameToIDs[plainName] then
                    contextIds = AES.NameToIDs[plainName]
                    contexts[#contexts + 1] = contextIds
                end

                if not changed and db.ui then
                    local esUI = (AES.CustomUI and AES.CustomUI[text])
                        or (AES.UIStringsByEN and AES.UIStringsByEN[text])
                    if esUI then
                        fs:SetText(esUI)
                        changed = true
                    end
                end

                if not changed and #contexts > 0 then
                    for _, ctx in ipairs(contexts) do
                        for _, id in ipairs(ctx) do
                            if (AES.TipByID[id] and TryPairSet(fs, text, AES.TipByID[id], AES.TipPairs))
                                or (AES.DescByID[id] and TryPairSet(fs, text, AES.DescByID[id], AES.DescPairs)) then
                                changed = true
                                break
                            end
                        end
                        if changed then break end
                    end
                end
            end
            if not changed and db.patterns then
                text = fs:GetText()

                local new = text
                for _, p in ipairs(AES.AnywherePlain or {}) do
                    local s = new:find(p[1], 1, true)
                    if s then
                        new = new:sub(1, s - 1) .. p[2] .. new:sub(s + #p[1])
                    end
                end
                new = new:gsub("Drains (%d+)%% Maximum Mana", "Drena un %1%% del man\195\161 m\195\161ximo")
                new = new:gsub("Applies (%d+) ([%a][%a%s':]*[%a])", function(n, aura)
                    return "Aplica " .. n .. " " .. (TranslateSpellWord(aura) or aura)
                end)
                new = new:gsub("Generates (%d+) ([%a][%a%s':]*[%a])", function(n, res)
                    return "Genera " .. n .. " " .. (TranslateSpellWord(res) or res)
                end)

                new = new:gsub("Rank (%d+)/(%d+)", "Rango %1/%2")
                new = new:gsub("Level: (%d+)", "Nivel: %1")
                new = new:gsub("Lasts (%d+) sec?,? ?stacking (%d+) times", "Dura %1 s, acumul\195\161ndose %2 veces")

                new = new:gsub("(|T[^|]*|t ?)([%a][%w' %-]+)", function(icon, nm)
                    local es = AES.SpellNameEN2ES[nm] or TranslateSpellWord(nm)
                    return icon .. (es or nm)
                end)

                new = new:gsub("Usable while in (|c%x%x%x%x%x%x%x%x)(%a[%a%s']*%a)(|r)", function(c, w, r)
                    return "Utilizable durante " .. c .. (TranslateSpellWord(w) or w) .. r
                end)
                new = new:gsub("Usable while in (%a[%a%s']*%a)", function(w)
                    return "Utilizable durante " .. (TranslateSpellWord(w) or w)
                end)

                new = new:gsub("^Requires (.+)$", function(list)
                    local parts = {}
                    for raw in list:gmatch("[^,]+") do
                        local w = raw:match("^%s*(.-)%s*$")
                        local lvl = w:match("^[Ll]evel (%d+)$")
                        parts[#parts + 1] = (lvl and ("nivel " .. lvl))
                            or (AES.WeaponWords and AES.WeaponWords[w])
                            or TranslateSpellWord(w) or w
                    end
                    return "Requiere " .. table.concat(parts, ", ")
                end)

                do
                    local pre, rest = new:match("^(Equip: |Use: |Chance on hit: )(.+)$")
                    if pre and AES.TranslateSystemText then
                        local tr = AES.TranslateSystemText(rest)
                        if tr ~= rest then
                            local preES = (pre == "Equip: " and "Equipar: ")
                                or (pre == "Use: " and "Uso: ")
                                or "Probabilidad de golpear: "
                            new = preES .. tr
                        end
                    end
                end
                if new ~= text then
                    fs:SetText(new)
                    text = new
                end

                for _, p in ipairs(AES.LinePatterns) do
                    if p[2] then
                        local rep, n = text:gsub(p[1], p[2])
                        if n > 0 and rep ~= text then
                            fs:SetText(rep)
                            break
                        end
                    end
                end
            end
        end
    end

    if db.patterns then
        for i = 1, tip:NumLines() do
            local fs = _G[tipName .. "TextRight" .. i]
            local text = fs and fs:GetText()
            if text and text ~= "" then
                for _, p in ipairs(AES.LinePatterns) do
                    if p[2] then
                        local rep, n = text:gsub(p[1], p[2])
                        if n > 0 and rep ~= text then
                            fs:SetText(rep)
                            break
                        end
                    end
                end
            end
        end
    end
end

local ApplyLinePatterns = TranslateTooltipLines

local latePassTip, latePassElapsed, latePassShots
local latePassDriver = CreateFrame("Frame")
latePassDriver:SetScript("OnUpdate", function(self, dt)
    if not latePassTip then return end
    if not latePassTip:IsVisible() then
        latePassTip = nil
        return
    end
    latePassElapsed = latePassElapsed + (dt or 0.02)

    if (latePassShots == 0 and latePassElapsed >= 0.25)
        or (latePassShots == 1 and latePassElapsed >= 1.0) then
        latePassShots = latePassShots + 1
        pcall(TranslateTooltipLines, latePassTip)
        if latePassShots >= 2 then
            latePassTip = nil
        end
    end
end)

local function ScheduleLatePass(tip)
    if tip.IsVisible then
        latePassTip = tip
        latePassElapsed = 0
        latePassShots = 0
    end
end

local function OnSpellTooltip(tip)
    if not db or not db.spells then return end
    local _, _, spellID = tip:GetSpell()
    local name = tip:GetName()
    local L1 = _G[name .. "TextLeft1"]
    local enName = L1 and L1:GetText()

    local esName = enName and AES.SpellNameEN2ES[enName]
    if esName then L1:SetText(esName) end

    local L2 = _G[name .. "TextLeft2"]
    local rankText = L2 and L2:GetText()
    if rankText and AES.RankEN2ES[rankText] then
        L2:SetText(AES.RankEN2ES[rankText])
    end

    if spellID and AES.DescByID[spellID] then
        TranslateBodyByPairs(tip, AES.DescByID[spellID], AES.DescPairs)
    end
    if enName and AES.NameToIDs[enName] then
        for _, id in ipairs(AES.NameToIDs[enName]) do
            if AES.DescByID[id] then
                TranslateBodyByPairs(tip, AES.DescByID[id], AES.DescPairs)
            end
            if AES.TipByID[id] then
                TranslateBodyByPairs(tip, AES.TipByID[id], AES.TipPairs)
            end
        end
    end

    ApplyLinePatterns(tip)
    ScheduleLatePass(tip)
    tip:Show()
end

local function OnAuraTooltip(tip, unit, index, filter)
    if not db or not db.spells then return end
    local spellID = select(11, UnitAura(unit, index, filter))
    local name = tip:GetName()
    local L1 = _G[name .. "TextLeft1"]
    local enName = L1 and L1:GetText()
    local esName = enName and AES.SpellNameEN2ES[enName]
    if esName then L1:SetText(esName) end

    local translated = false
    if spellID and AES.TipByID[spellID] then
        translated = TranslateBodyByPairs(tip, AES.TipByID[spellID], AES.TipPairs)
    end
    if not translated and enName and AES.NameToIDs[enName] then
        for _, id in ipairs(AES.NameToIDs[enName]) do
            if AES.TipByID[id] and TranslateBodyByPairs(tip, AES.TipByID[id], AES.TipPairs) then
                break
            end
        end
    end

    ApplyLinePatterns(tip)
    tip:Show()
end

local function OnItemTooltip(tip)
    if not db or not db.items then return end
    local _, link = tip:GetItem()
    local itemID = link and tonumber(link:match("item:(%d+)"))
    local name = tip:GetName()

    if itemID and AES.ItemName[itemID] then
        local L1 = _G[name .. "TextLeft1"]
        local text = L1 and L1:GetText()
        local guard = AES.ItemNameEN[itemID]
        if text and text ~= "" and (not guard or guard == text) then
            L1:SetText(AES.ItemName[itemID])
        end
    end

    if itemID and GetItemSpell then
        local spellName = GetItemSpell(itemID)
        local sIds = spellName and AES.NameToIDs[spellName]
        if sIds then
            for i = 2, tip:NumLines() do
                local fs = _G[name .. "TextLeft" .. i]
                local t = fs and fs:GetText()
                if t and (t:find("^Use: ") or t:find("^Uso: ") or t:find("^Equip: ") or t:find("^Equipar: ")) then
                    for _, sid in ipairs(sIds) do
                        if (AES.TipByID[sid] and TryPairSet(fs, t, AES.TipByID[sid], AES.TipPairs))
                            or (AES.DescByID[sid] and TryPairSet(fs, t, AES.DescByID[sid], AES.DescPairs)) then
                            break
                        end
                    end
                    break
                end
            end
        end
    end

    if db.flavor and itemID and AES.ItemDesc[itemID] then
        for i = 2, tip:NumLines() do
            local fs = _G[name .. "TextLeft" .. i]
            local text = fs and fs:GetText()
            if text and text:sub(1, 1) == '"' then
                fs:SetText('"' .. AES.ItemDesc[itemID] .. '"')
                break
            end
        end
    end

    ApplyLinePatterns(tip)
    ScheduleLatePass(tip)
    tip:Show()
end

local function OnUnitTooltip(tip)
    if not db then return end
    local _, unit = tip:GetUnit()
    local guid = unit and UnitGUID(unit)
    local npcID = db.units and NpcIdFromGUID(guid)
    if npcID then
        local name = tip:GetName()
        local L1 = _G[name .. "TextLeft1"]
        local text = L1 and L1:GetText()
        local guard = AES.UnitNameEN[npcID]
        if text and AES.UnitName[npcID] and (not guard or guard == text) then
            L1:SetText(AES.UnitName[npcID])
        end

        local L2 = _G[name .. "TextLeft2"]
        local t2 = L2 and L2:GetText()
        if t2 and AES.UnitSub[npcID] and not t2:match("^Level") and not t2:match("^Nivel") then
            local subGuard = AES.UnitSubEN[npcID]
            if not subGuard or subGuard == t2 then
                L2:SetText(AES.UnitSub[npcID])
            end
        end
    end

    ApplyLinePatterns(tip)
    tip:Show()
end

local function TranslateShortText(text)

    if AES.RankEN2ES[text] then return AES.RankEN2ES[text] end
    for _, p in ipairs(AES.LinePatterns) do
        if p[2] then
            local new, n = text:gsub(p[1], p[2])
            if n > 0 and new ~= text then return new end
        end
    end
    return nil
end

local function TranslateAscensionSpellButtons()
    local frame = AscensionSpellbookFrame
    local spells = frame and frame.Content and frame.Content.Spells
    if not spells then return end
    for i = 1, 12 do
        local b = spells["SpellButton" .. i]
        if b then
            local fs = b.SpellName
            local t = fs and fs:GetText()
            local es = t and AES.SpellNameEN2ES[t]
            if es then fs:SetText(es) end
            local sub = b.SubSpellName
            local st = sub and sub:GetText()
            if st and st ~= "" then
                local esSub = TranslateShortText(st)
                if esSub then sub:SetText(esSub) end
            end
        end
    end
end

local function HookSpellbook()

    if type(SpellButton_UpdateButton) == "function" then
        hooksecurefunc("SpellButton_UpdateButton", function(self)
            if not db or not db.spells then return end
            local nameFS = _G[self:GetName() .. "SpellName"]
            local text = nameFS and nameFS:GetText()
            local es = text and AES.SpellNameEN2ES[text]
            if es then nameFS:SetText(es) end
            local subFS = _G[self:GetName() .. "SubSpellName"]
            local sub = subFS and subFS:GetText()
            if sub and sub ~= "" then
                local esSub = TranslateShortText(sub)
                if esSub then subFS:SetText(esSub) end
            end
        end)
    end

    if AscensionSpellbookFrame and type(AscensionSpellbookFrame.UpdateSpells) == "function" then
        hooksecurefunc(AscensionSpellbookFrame, "UpdateSpells", function()
            if db and db.spells then TranslateAscensionSpellButtons() end
        end)
    end
    if AscensionSpellbookFrame and type(AscensionSpellbookFrame.UpdatePet) == "function" then
        hooksecurefunc(AscensionSpellbookFrame, "UpdatePet", function()
            if db and db.spells then TranslateAscensionSpellButtons() end
        end)
    end
end

local function ApplyUIStrings()
    return 0
end

local function TranslateStaticText(t)
    return (AES.CustomUI and AES.CustomUI[t]) or (AES.UIStringsByEN and AES.UIStringsByEN[t]) or nil
end

local function RetranslateStaticUI()
    if not db or not db.ui then return end
    local frame = EnumerateFrames()
    while frame do

        local protected = frame.IsProtected and select(1, frame:IsProtected())
        local forbidden = frame.IsForbidden and frame:IsForbidden()
        if not protected and not forbidden then
            local ok, regions = pcall(function() return { frame:GetRegions() } end)
            if ok and regions then
                for _, r in ipairs(regions) do
                    if r and r.IsObjectType and r:IsObjectType("FontString") then
                        local t = r:GetText()
                        if t and t ~= "" then
                            local es = TranslateStaticText(t)
                            if es then
                                pcall(r.SetText, r, es)
                            end
                        end
                    end
                end
            end
        end
        frame = EnumerateFrames(frame)
    end
end

local function HookStaticPanels()
    for _, name in ipairs({ "GameMenuFrame", "VideoOptionsFrame", "InterfaceOptionsFrame", "AchievementFrame", "SpellBookFrame" }) do
        local f = _G[name]
        if f and f.HookScript and f:HasScript("OnShow") then
            f:HookScript("OnShow", RetranslateStaticUI)
        end
    end
end

local function TranslateAchievementFS(fs, id, esTable, enTable)
    if not fs or not id then return end
    local es = esTable[id]
    if not es then return end
    local text = fs:GetText()
    local guard = enTable[id]
    if text and (not guard or guard == text) then
        fs:SetText(es)
    end
end

local function TranslateAchButton(button)
    if not button or not button.id then return end
    TranslateAchievementFS(button.label, button.id, AES.AchName, AES.AchNameEN)
    TranslateAchievementFS(button.description, button.id, AES.AchDesc, AES.AchDescEN)
    TranslateAchievementFS(button.reward, button.id, AES.AchReward, AES.AchRewardEN)
end

local function AchTooltipPass(tip, achID)
    if not db or not db.achievements then return end
    local name = tip:GetName()
    for i = 1, tip:NumLines() do
        local fs = _G[name .. "TextLeft" .. i]
        local text = fs and fs:GetText()
        if text and text ~= "" then
            local es = (AES.AchNameEN2ES and AES.AchNameEN2ES[text])
                or (AES.AchCritEN2ES and AES.AchCritEN2ES[text])
            if not es and achID and AES.AchDescEN[achID] == text then
                es = AES.AchDesc[achID]
            end
            if es then fs:SetText(es) end
        end
        local fsr = _G[name .. "TextRight" .. i]
        local textr = fsr and fsr:GetText()
        if textr and AES.AchCritEN2ES and AES.AchCritEN2ES[textr] then
            fsr:SetText(AES.AchCritEN2ES[textr])
        end
    end
    tip:Show()
end

local function HookAchievementUI()
    if type(AchievementButton_DisplayAchievement) == "function" then
        hooksecurefunc("AchievementButton_DisplayAchievement", function(button)
            if not db or not db.achievements then return end
            TranslateAchButton(button)
        end)
    end

    if type(AchievementFrameSummary_UpdateAchievements) == "function" then
        hooksecurefunc("AchievementFrameSummary_UpdateAchievements", function()
            if not db or not db.achievements then return end
            for i = 1, 20 do
                local b = _G["AchievementFrameSummaryAchievement" .. i]
                if not b then break end
                TranslateAchButton(b)
                if b.HookScript and not b.__aesHooked then
                    b.__aesHooked = true
                    b:HookScript("OnEnter", function(btn) AchTooltipPass(GameTooltip, btn.id) end)
                end
            end
        end)
    end

    if type(AchievementFrameCategories_DisplayButton) == "function" then
        hooksecurefunc("AchievementFrameCategories_DisplayButton", function(button)
            if not db or not db.achievements then return end
            local fs = button and button.label
            local t = fs and fs:GetText()
            if not t then return end
            local es = (AES.AchCatEN2ES and AES.AchCatEN2ES[t]) or (AES.CustomUI and AES.CustomUI[t])
            if es then fs:SetText(es) end
        end)
    end

    if type(AchievementFrameCategories_UpdateTooltip) == "function" then
        hooksecurefunc("AchievementFrameCategories_UpdateTooltip", function()
            AchTooltipPass(GameTooltip)
        end)
    end
    if type(AchievementMeta_OnEnter) == "function" then
        hooksecurefunc("AchievementMeta_OnEnter", function()
            AchTooltipPass(GameTooltip)
        end)
    end
end

local function HookAchievementAlerts()
    if type(AchievementAlertFrame_ShowAlert) ~= "function" then return end
    hooksecurefunc("AchievementAlertFrame_ShowAlert", function()
        if not db or not db.achievements then return end
        for i = 1, 2 do
            local frame = _G["AchievementAlertFrame" .. i]
            if frame and frame:IsShown() and frame.id then
                TranslateAchievementFS(_G["AchievementAlertFrame" .. i .. "Name"],
                    frame.id, AES.AchName, AES.AchNameEN)
            end
        end
    end)
end

local function HookAchievementLinks()
    hooksecurefunc(ItemRefTooltip, "SetHyperlink", function(tip, link)
        if not db or not db.achievements then return end
        local id = link and tonumber(link:match("achievement:(%d+)"))
        if not id then return end
        local name = tip:GetName()
        TranslateAchievementFS(_G[name .. "TextLeft1"], id, AES.AchName, AES.AchNameEN)
        for i = 2, tip:NumLines() do
            local fs = _G[name .. "TextLeft" .. i]
            local text = fs and fs:GetText()
            if text and text == AES.AchDescEN[id] and AES.AchDesc[id] then
                fs:SetText(AES.AchDesc[id])
                break
            end
        end
        tip:Show()
    end)
end

local function TranslateTrainerList()
    local n = CLASS_TRAINER_SKILLS_DISPLAYED or 11
    for i = 1, n do
        local btn = _G["ClassTrainerSkill" .. i]
        if btn and btn.GetText then
            local t = btn:GetText()
            if t and t ~= "" then
                local prefix, name = t:match("^(%s*)(.+)$")
                local es = name and AES.SpellNameEN2ES[name]
                if es then btn:SetText((prefix or "") .. es) end
            end
        end
        local sub = _G["ClassTrainerSkill" .. i .. "SubText"]
        local st = sub and sub:GetText()
        if st and st ~= "" then
            local new = st:gsub("%(Rank (%d+)%)", "(Rango %1)")
            new = AES.SpellNameEN2ES[new] or new
            if new ~= st then sub:SetText(new) end
        end
    end
end

local function TranslateTrainerDetail()
    local nameFS = ClassTrainerSkillName
    local enName = nameFS and nameFS:GetText()
    if enName then
        local es = AES.SpellNameEN2ES[enName]
        if es then nameFS:SetText(es) end
    end
    local subFS = ClassTrainerSubSkillName
    local st = subFS and subFS:GetText()
    if st and st ~= "" then
        local new = st:gsub("%(Rank (%d+)%)", "(Rango %1)")
        if new ~= st then subFS:SetText(new) end
    end

    local reqFS = ClassTrainerSkillRequirements
    local rt = reqFS and reqFS:GetText()
    if rt and rt ~= "" then
        local new = rt:gsub("Requires: ", "Requiere: ")
        new = new:gsub("Level (%d+)", "nivel %1")
        new = new:gsub("%(Rank (%d+)%)", "(Rango %1)")
        new = new:gsub("[%a][%a' %-]*%a", function(w)
            return TranslateSpellWord(w) or w
        end)
        if new ~= rt then reqFS:SetText(new) end
    end

    local descFS = ClassTrainerSkillDescription
    local dt = descFS and descFS:GetText()
    if dt and #dt > 3 and enName and AES.NameToIDs[enName] then
        for _, id in ipairs(AES.NameToIDs[enName]) do
            if AES.DescByID[id] and TryPairSet(descFS, dt, AES.DescByID[id], AES.DescPairs) then
                break
            end
        end
    end
end

local function HookTrainerUI()
    if type(ClassTrainerFrame_Update) ~= "function" then return end
    hooksecurefunc("ClassTrainerFrame_Update", function()
        if db and db.spells then
            TranslateTrainerList()
            TranslateTrainerDetail()
        end
    end)
    if type(ClassTrainer_SetSelection) == "function" then
        hooksecurefunc("ClassTrainer_SetSelection", function()
            if db and db.spells then TranslateTrainerDetail() end
        end)
    end
    if ClassTrainerFrame and ClassTrainerFrame.HookScript and ClassTrainerFrame:HasScript("OnShow") then
        ClassTrainerFrame:HookScript("OnShow", RetranslateStaticUI)
    end
end

local function HookTooltip(tip)
    if not tip then return end
    if tip:HasScript("OnTooltipSetSpell") then
        tip:HookScript("OnTooltipSetSpell", OnSpellTooltip)
    end
    if tip:HasScript("OnTooltipSetItem") then
        tip:HookScript("OnTooltipSetItem", OnItemTooltip)
    end
    if tip:HasScript("OnTooltipSetUnit") then
        tip:HookScript("OnTooltipSetUnit", OnUnitTooltip)
    end
end

local function HookAuras()
    if GameTooltip.SetUnitAura then
        hooksecurefunc(GameTooltip, "SetUnitAura", OnAuraTooltip)
    end
    if GameTooltip.SetUnitBuff then
        hooksecurefunc(GameTooltip, "SetUnitBuff", function(tip, unit, index)
            OnAuraTooltip(tip, unit, index, "HELPFUL")
        end)
    end
    if GameTooltip.SetUnitDebuff then
        hooksecurefunc(GameTooltip, "SetUnitDebuff", function(tip, unit, index)
            OnAuraTooltip(tip, unit, index, "HARMFUL")
        end)
    end
end

local OPTIONS_LIST = {
    { key = "spells", text = "Hechizos, talentos y auras" },
    { key = "items", text = "Objetos (nombres)" },
    { key = "flavor", text = "Texto ambiental de objetos (la cita amarilla)" },
    { key = "units", text = "Nombres de NPC (mejor apagado: las misiones los citan en inglés)" },
    { key = "achievements", text = "Logros" },
    { key = "patterns", text = "Líneas genéricas de tooltip (coste, alcance, rangos...)" },
    { key = "ui", text = "Interfaz y menús (los cambios requieren /reload)" },
    { key = "errores", text = "Mensajes de error en pantalla", setter = "SetErrorsEnabled" },
    { key = "chat", text = "Mensajes del chat (botín, experiencia, sistema...)", setter = "SetChatEnabled" },
    { key = "voice", text = "Voces de error en español (\"no tengo maná\"...)", setter = "SetVoiceEnabled" },
}

local function BuildOptionsPanel()
    if not InterfaceOptions_AddCategory then return end
    local panel = CreateFrame("Frame", "AscensionESOptionsPanel", UIParent)
    panel.name = "AscensionES"

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("AscensionES |cff33ff99\226\128\148 Traducci\195\179n al espa\195\177ol|r")

    local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    sub:SetJustifyH("LEFT")
    sub:SetText("Los cambios se aplican al instante salvo indicaci\195\179n. Tambi\195\169n disponible: /ases")

    local prev
    for i, opt in ipairs(OPTIONS_LIST) do
        local cb = CreateFrame("CheckButton", "AscensionESOptCheck" .. i, panel, "InterfaceOptionsCheckButtonTemplate")
        if prev then
            cb:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -4)
        else
            cb:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", -2, -14)
        end
        local label = _G[cb:GetName() .. "Text"]
        if label then
            label:SetText(opt.text)
        end
        cb.optKey = opt.key
        cb:SetScript("OnClick", function(self)
            local on = self:GetChecked() and true or false
            if opt.setter and AES[opt.setter] then
                AES[opt.setter](on)
            elseif db then
                db[opt.key] = on
            end
            if opt.key == "ui" then
                DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99AscensionES|r interfaz: haz /reload para aplicar el cambio")
            end
        end)
        prev = cb
    end

    panel:SetScript("OnShow", function()
        for i = 1, #OPTIONS_LIST do
            local cb = _G["AscensionESOptCheck" .. i]
            if cb and db then
                cb:SetChecked(db[cb.optKey] and true or false)
            end
        end
    end)

    InterfaceOptions_AddCategory(panel)
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_ENTERING_WORLD" then
        RetranslateStaticUI()
        HookStaticPanels()
        return
    end
    if arg1 ~= "AscensionES" then return end
    self:UnregisterEvent("ADDON_LOADED")

    AscensionESDB = AscensionESDB or {}
    db = AscensionESDB
    for k, v in pairs(defaults) do
        if db[k] == nil then db[k] = v end
    end
    if not db._v or db._v < 2 then
        db.units = false
        db._v = 2
    end

    HookTooltip(GameTooltip)
    HookTooltip(ItemRefTooltip)
    HookAuras()
    HookSpellbook()
    HookAchievementAlerts()
    HookAchievementLinks()
    ApplyUIStrings()
    BuildOptionsPanel()

    if IsAddOnLoaded and IsAddOnLoaded("Blizzard_AchievementUI") then
        HookAchievementUI()
    end
    if IsAddOnLoaded and IsAddOnLoaded("Blizzard_TrainerUI") then
        HookTrainerUI()
    end
    local waiter = CreateFrame("Frame")
    waiter:RegisterEvent("ADDON_LOADED")
    waiter:SetScript("OnEvent", function(w, _, name)
        if name == "Blizzard_AchievementUI" then
            HookAchievementUI()
        elseif name == "Blizzard_TrainerUI" then
            HookTrainerUI()
        end
    end)

    local n = 0
    for _ in pairs(AES.SpellNameEN2ES) do n = n + 1 end
    DEFAULT_CHAT_FRAME:AddMessage(format(
        "|cff33ff99AscensionES|r cargado: %d nombres de hechizo, %d descripciones, %d objetos, %d NPCs. /ases para opciones.",
        n, #AES.DescPairs, (function() local c = 0 for _ in pairs(AES.ItemName) do c = c + 1 end return c end)(),
        (function() local c = 0 for _ in pairs(AES.UnitName) do c = c + 1 end return c end)()))
end)

SLASH_ASCENSIONES1 = "/ases"
SLASH_ASCENSIONES2 = "/ascensiones"
SlashCmdList["ASCENSIONES"] = function(msg)
    msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    local function status(v) return v and "|cff33ff99SÍ|r" or "|cffff3333NO|r" end
    if msg == "hechizos" or msg == "spells" then
        db.spells = not db.spells
    elseif msg == "objetos" or msg == "items" then
        db.items = not db.items
    elseif msg == "npcs" or msg == "units" then
        db.units = not db.units
    elseif msg == "lineas" or msg == "patterns" then
        db.patterns = not db.patterns
    elseif msg == "ambiental" or msg == "flavor" then
        db.flavor = not db.flavor
    elseif msg == "logros" or msg == "achievements" then
        db.achievements = not db.achievements
    elseif msg == "interfaz" or msg == "ui" then
        db.ui = not db.ui
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99AscensionES|r interfaz cambiada: haz /reload para aplicar")
    elseif msg == "chat" then
        local newState = not (db.chat ~= false)
        if AES.SetChatEnabled then AES.SetChatEnabled(newState) else db.chat = newState end
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99AscensionES|r mensajes de chat en español: " .. status(db.chat))
        return
    elseif msg == "errores" or msg == "errors" then
        local newState = not (db.errores ~= false)
        if AES.SetErrorsEnabled then AES.SetErrorsEnabled(newState) else db.errores = newState end
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99AscensionES|r mensajes de error en español: " .. status(db.errores))
        return
    elseif msg == "voz" or msg == "voice" then
        local newState = not (db.voice ~= false)
        if AES.SetVoiceEnabled then AES.SetVoiceEnabled(newState) else db.voice = newState end
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99AscensionES|r voces de error en español: " .. status(db.voice))
        return
    elseif msg == "refrescar" or msg == "refresh" then
        RetranslateStaticUI()
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99AscensionES|r interfaz estática retraducida")
        return
    elseif msg == "traduce" then

        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99AscensionES|r sonda-traduce armada: abre el tooltip y mantenlo 4 s...")
        local probe = CreateFrame("Frame")
        local elapsed = 0
        probe:SetScript("OnUpdate", function(self, dt)
            elapsed = elapsed + dt
            if elapsed < 4 then return end
            self:SetScript("OnUpdate", nil)
            if not GameTooltip:IsVisible() then
                DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99AES|r el tooltip no estaba visible")
                return
            end
            local list = CollectTooltipFontStrings(GameTooltip)
            DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99AES|r FontStrings recogidos: " .. #list)
            for i, fs in ipairs(list) do
                if i <= 8 then
                    local t = fs:GetText() or ""
                    t = t:gsub("|", "||"):sub(1, 55)
                    DEFAULT_CHAT_FRAME:AddMessage("  " .. i .. ": " .. t)
                end
            end
            local ok, err = pcall(TranslateTooltipLines, GameTooltip)
            DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99AES|r pasada manual: " .. (ok and "ejecutada" or ("ERROR: " .. tostring(err))))
        end)
        return
    elseif msg:match("^volcar") then

        local needle = msg:match("^volcar%s+(.+)$") or "Deals"
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99AscensionES|r sonda armada: pasa el ratón por el tooltip — volcado en 4 s...")
        local probe = CreateFrame("Frame")
        local elapsed = 0
        probe:SetScript("OnUpdate", function(self, dt)
            elapsed = elapsed + dt
            if elapsed < 4 then return end
            self:SetScript("OnUpdate", nil)
            local found = 0
            local frame = EnumerateFrames()
            while frame do
                local ok, regions = pcall(function() return { frame:GetRegions() } end)
                if ok and regions then
                    for _, r in ipairs(regions) do
                        if r and r.IsObjectType and r:IsObjectType("FontString")
                            and r.IsVisible and r:IsVisible() then
                            local t = r:GetText()
                            if t and t:lower():find(needle, 1, true) then
                                found = found + 1
                                local f, chain = frame, {}
                                while f and #chain < 6 do
                                    chain[#chain + 1] = (f.GetName and f:GetName()) or "(anónimo)"
                                    f = f.GetParent and f:GetParent()
                                end
                                DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99AES sonda|r " .. found .. ": " .. table.concat(chain, " < "))
                            end
                        end
                    end
                end
                frame = EnumerateFrames(frame)
            end
            DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99AES sonda|r fin: " .. found .. " coincidencias de '" .. needle .. "'")
        end)
        return
    elseif msg ~= "" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99AscensionES|r comandos: /ases hechizos | objetos | npcs | lineas | ambiental | logros | interfaz | refrescar")
        return
    end
    DEFAULT_CHAT_FRAME:AddMessage(format(
        "|cff33ff99AscensionES|r hechizos:%s objetos:%s npcs:%s líneas:%s ambiental:%s logros:%s interfaz:%s",
        status(db.spells), status(db.items), status(db.units), status(db.patterns), status(db.flavor),
        status(db.achievements), status(db.ui)))
end

AscensionES.__firma = "AES/2026-07-14/d2560dd51678eb30/HideXs"
