local BASE = "Interface\\AddOns\\AscensionES_Voces\\sounds\\quests\\"
local db

local function QuestID()
    local id = GetQuestID and tonumber(GetQuestID())
    if id and id ~= 0 then return id end
    local AES = AscensionES
    local t = GetTitleText and GetTitleText()
    if t and t ~= "" and AES then
        id = (AES.QuestTitleES2ID and AES.QuestTitleES2ID[t])
            or (AES.QuestTitleEN2ID and AES.QuestTitleEN2ID[t])
        if id then return id end

        if AES.ResolveQuestIDByPanels then
            return AES.ResolveQuestIDByPanels(t)
        end
    end
    return nil
end

local function ClipDur(id, k)
    local idx = AscensionES_VocesIndex and AscensionES_VocesIndex[id]
    if type(idx) ~= "table" then return nil end
    return idx[k]
end

local function dbg(msg)
    if db and db.debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffcc66[VocesAudio]|r " .. msg)
    end
end

local savedMusic
local chainNext
local endTimer = CreateFrame("Frame")
local endLeft = 0
endTimer:Hide()

local function RestoreMusic()
    if savedMusic then
        SetCVar("Sound_EnableMusic", savedMusic.enable)
        SetCVar("Sound_MusicVolume", savedMusic.vol)
        dbg("música restaurada (enable=" .. tostring(savedMusic.enable)
            .. " vol=" .. tostring(savedMusic.vol) .. ")")
        savedMusic = nil
    end
end

local function StopVoice()
    endTimer:Hide()
    chainNext = nil
    if savedMusic then
        pcall(StopMusic)
        dbg("STOP (StopMusic)")
        RestoreMusic()
    end
end

endTimer:SetScript("OnUpdate", function(self, dt)
    endLeft = endLeft - dt
    if endLeft > 0 then return end
    if chainNext then
        local nxt = chainNext
        chainNext = nil
        local ok = pcall(PlayMusic, nxt.path)
        dbg("PLAY(cadena) " .. tostring(nxt.path):match("[^\\]+$")
            .. " ok=" .. tostring(ok) .. " dur=" .. tostring(nxt.dur))
        endLeft = math.max(1, (tonumber(nxt.dur) or 30) - 0.3)
        return
    end
    self:Hide()
    dbg("fin natural del clip")
    pcall(StopMusic)
    RestoreMusic()
end)

local function PlayFile(path, dur, chain)
    StopVoice()
    chainNext = chain
    savedMusic = {
        enable = GetCVar("Sound_EnableMusic") or "1",
        vol = GetCVar("Sound_MusicVolume") or "1",
    }
    SetCVar("Sound_EnableMusic", 1)
    if tonumber(savedMusic.vol or 0) < 0.6 then
        SetCVar("Sound_MusicVolume", 0.75)
    end
    local ok = pcall(PlayMusic, path)
    dbg("PLAY(música) " .. tostring(path):match("[^\\]+$")
        .. " ok=" .. tostring(ok) .. " dur=" .. tostring(dur))

    endLeft = math.max(1, (tonumber(dur) or 60) - 0.3)
    endTimer:Show()
end

local playing
local function Play(kind, suffix)
    if not (db and db.on) then return end
    local id = QuestID()
    local dur = id and ClipDur(id, kind)
    if db.debug then
        DEFAULT_CHAT_FRAME:AddMessage(format(
            "|cff33ff99[VocesDebug]|r título=%s id=%s clip=%s",
            tostring(GetTitleText and GetTitleText()), tostring(id), tostring(dur)))
    end
    if not dur then return end
    local chain
    if kind == "a" and db.objetivos then
        local odur = ClipDur(id, "o")
        if odur then
            chain = { path = BASE .. id .. "-objectives.mp3", dur = odur }
        end
    end
    PlayFile(BASE .. id .. "-" .. suffix .. ".mp3", dur, chain)
    playing = id
end

local function StopIfPlaying()
    if playing then
        StopVoice()
        playing = nil
    end
end

local function StopOnClose()
    if db and db.continuar then return end
    StopIfPlaying()
end

local BuildOptions

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("QUEST_DETAIL")
f:RegisterEvent("QUEST_PROGRESS")
f:RegisterEvent("QUEST_COMPLETE")
f:RegisterEvent("QUEST_FINISHED")
f:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= "AscensionES_Voces" then return end
        AscensionESVocesDB = AscensionESVocesDB or { on = true }
        db = AscensionESVocesDB
        if db.objetivos == nil then db.objetivos = true end
        local okP, errP = pcall(BuildOptions)
        if not okP then
            DEFAULT_CHAT_FRAME:AddMessage(
                "|cffff3333Voces: error creando el panel de opciones:|r " .. tostring(errP))
        end

        if type(CloseQuest) == "function" then
            hooksecurefunc("CloseQuest", StopOnClose)
        end
        if type(DeclineQuest) == "function" then
            hooksecurefunc("DeclineQuest", StopOnClose)
        end
        if QuestFrame and QuestFrame.HookScript then
            QuestFrame:HookScript("OnHide", StopOnClose)
        end
        local n = 0
        for _ in pairs(AscensionES_VocesIndex or {}) do n = n + 1 end
        DEFAULT_CHAT_FRAME:AddMessage(
            "|cff33ff99AscensionES Voces|r: " .. n .. " misiones con narración. /asesvoz para opciones.")
    elseif event == "QUEST_DETAIL" then
        Play("a", "accept")
    elseif event == "QUEST_PROGRESS" then
        Play("p", "progress")
    elseif event == "QUEST_COMPLETE" then
        Play("c", "complete")
    elseif event == "QUEST_FINISHED" then
        StopOnClose()
    end
end)

function BuildOptions()
    if not InterfaceOptions_AddCategory then return end
    local panel = CreateFrame("Frame", "AscensionESVocesOptions", UIParent)
    panel.name = "Voces"
    panel.parent = "AscensionES"

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("AscensionES |cff33ff99Voces|r")

    local OPTS = {
        { key = "on", text = "Narración de misiones activada" },
        { key = "objetivos", text = "Narrar también los objetivos (tras la descripción)" },
        { key = "continuar", text = "Seguir narrando al cerrar la misión (p. ej. tras aceptarla)" },
    }
    local prev
    for i, opt in ipairs(OPTS) do
        local cb = CreateFrame("CheckButton", "AscensionESVocesOptCheck" .. i,
                               panel, "InterfaceOptionsCheckButtonTemplate")
        if prev then
            cb:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, -6)
        else
            cb:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -16)
        end
        _G[cb:GetName() .. "Text"]:SetText(opt.text)
        cb:SetChecked(db[opt.key])
        cb:SetScript("OnClick", function(self)
            db[opt.key] = self:GetChecked() and true or false
            if opt.key == "on" and not db.on then
                StopVoice()
                playing = nil
            end
        end)
        prev = cb
    end

    local note = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    note:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 4, -14)
    note:SetJustifyH("LEFT")
    note:SetText("Voces sintéticas generadas por IA. También disponible: /asesvoz")
    InterfaceOptions_AddCategory(panel)
    _G.AscensionESVocesPanel = panel
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Voces|r: panel de opciones registrado (Interfaz > AddOns > AscensionES > Voces)")
end

SLASH_ASESVOZ1 = "/asesvoz"
SlashCmdList["ASESVOZ"] = function(msg)
    msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if msg == "parar" or msg == "stop" then
        StopVoice()
        playing = nil
        return
    elseif msg == "test" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Voces|r test canal música (q119)")
        PlayFile(BASE .. "119-accept.mp3", ClipDur(119, "a") or 12)
        return
    elseif msg == "objetivos" then
        db.objetivos = not db.objetivos
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Voces|r narrar objetivos: "
            .. (db.objetivos and "|cff33ff99SÍ|r" or "|cffff3333NO|r"))
        return
    elseif msg == "continuar" or msg == "seguir" then
        db.continuar = not db.continuar
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Voces|r seguir narrando al cerrar la misión: "
            .. (db.continuar and "|cff33ff99SÍ|r" or "|cffff3333NO|r"))
        return
    elseif msg == "opciones" then
        if _G.AscensionESVocesPanel and InterfaceOptionsFrame_OpenToCategory then
            InterfaceOptionsFrame_OpenToCategory(_G.AscensionESVocesPanel)
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff3333Voces|r: el panel no está registrado")
        end
        return
    elseif msg == "testwav" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Voces|r test WAV (q119)")
        PlaySoundFile(BASE .. "119-accept.wav")
        return
    elseif msg == "debug" then
        db.debug = not db.debug
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Voces|r debug: " .. tostring(db.debug))
        return
    end
    db.on = not db.on
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99AscensionES Voces|r: "
        .. (db.on and "|cff33ff99ACTIVADO|r" or "|cffff3333DESACTIVADO|r"))
end

local PARTES_TOTAL = 4
local URL_VOCES = "https://github.com/HideXs/AscensionES/releases"

local function PartesQueFaltan()
    local faltan = {}
    AscensionES_VocesPartes = AscensionES_VocesPartes or {}
    for i = 1, PARTES_TOTAL do
        if not AscensionES_VocesPartes[i] then faltan[#faltan + 1] = i end
    end
    return faltan
end
AscensionES_VocesPartesQueFaltan = PartesQueFaltan

local avisoPopup
local function MostrarAvisoPartes(faltan)
    if not avisoPopup then
        local f = CreateFrame("Frame", "AscensionESVocesAviso", UIParent)
        f:SetFrameStrata("DIALOG")
        f:SetWidth(440)
        f:SetHeight(165)
        f:SetPoint("TOP", UIParent, "TOP", 0, -140)
        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 },
        })
        f:EnableMouse(true)
        local msg = f:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        msg:SetPoint("TOP", 0, -22)
        msg:SetWidth(400)
        msg:SetJustifyH("CENTER")
        f.msg = msg
        local eb = CreateFrame("EditBox", "AscensionESVocesAvisoEB", f, "InputBoxTemplate")
        eb:SetWidth(330)
        eb:SetHeight(20)
        eb:SetPoint("TOP", msg, "BOTTOM", 0, -12)
        eb:SetAutoFocus(false)
        eb:SetText(URL_VOCES)
        eb:SetScript("OnTextChanged", function(self)

            if self:GetText() ~= URL_VOCES then
                self:SetText(URL_VOCES)
                self:HighlightText()
            end
        end)
        eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        f.eb = eb
        local b1 = CreateFrame("Button", "AscensionESVocesAvisoB1", f, "UIPanelButtonTemplate")
        b1:SetWidth(160)
        b1:SetHeight(24)
        b1:SetPoint("BOTTOMRIGHT", f, "BOTTOM", -8, 18)
        b1:SetText("Descargar")
        b1:SetScript("OnClick", function()
            f.msg:SetText("Copia el enlace con |cffffffffCtrl+C|r y pégalo en tu navegador:")
            f.eb:SetFocus()
            f.eb:HighlightText()
        end)
        local b2 = CreateFrame("Button", "AscensionESVocesAvisoB2", f, "UIPanelButtonTemplate")
        b2:SetWidth(160)
        b2:SetHeight(24)
        b2:SetPoint("BOTTOMLEFT", f, "BOTTOM", 8, 18)
        b2:SetText("Ahora no")
        b2:SetScript("OnClick", function() f:Hide() end)
        avisoPopup = f
    end
    local lista = table.concat(faltan, ", ")
    local plural = #faltan > 1
    avisoPopup.msg:SetText("|cff33ff99AscensionES Voces|r: falta"
        .. (plural and "n las partes |cffffffff" or " la parte |cffffffff") .. lista
        .. "|r de " .. PARTES_TOTAL .. ".\n\nMuchas misiones no tendrán voz hasta que "
        .. (plural and "las instales" or "la instales") .. ".")
    avisoPopup.eb:SetText(URL_VOCES)
    avisoPopup:Show()
end
AscensionES_VocesMostrarAviso = MostrarAvisoPartes

local avisoFrame = CreateFrame("Frame")
avisoFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
avisoFrame:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")

    local t, esperado = CreateFrame("Frame"), 0
    t:SetScript("OnUpdate", function(s, dt)
        esperado = esperado + dt
        if esperado < 5 then return end
        s:SetScript("OnUpdate", nil)
        local faltan = PartesQueFaltan()
        if #faltan > 0 then
            pcall(MostrarAvisoPartes, faltan)
            DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99AscensionES Voces|r: faltan "
                .. #faltan .. " de " .. PARTES_TOTAL .. " partes ("
                .. table.concat(faltan, ", ") .. "). Descárgalas en "
                .. "|cff99ccffgithub.com/HideXs/AscensionES|r")
        end
    end)
end)
