local AES = AscensionES
AES.VoiceFiles = AES.VoiceFiles or {}

local ADDON_PATH = "Interface\\AddOns\\AscensionES\\"
local playerKey
local msgMap = {}
local fmtMatchers = {}
local lastPlay = 0

local KEY2ERR = {
    ERR_OUT_OF_MANA = "err_nomana",
    ERR_OUT_OF_RAGE = "err_norage",
    ERR_OUT_OF_ENERGY = "err_noenergy",
    ERR_SPELL_COOLDOWN = "err_spellcooldown",
    ERR_ABILITY_COOLDOWN = "err_abilitycooldown",
    ERR_ITEM_COOLDOWN = "err_itemcooldown",
    ERR_POTION_COOLDOWN = "err_potioncooldown",
    ERR_SPELL_OUT_OF_RANGE = "err_outofrange",
    ERR_OUT_OF_RANGE = "err_outofrange",
    ERR_GENERIC_NO_TARGET = "err_genericnotarget",
    ERR_NO_ATTACK_TARGET = "err_genericnotarget",
    ERR_INVALID_ATTACK_TARGET = "err_invalidattacktarget",
    ERR_LOOT_TOO_FAR = "err_loottoofar",
    ERR_NOT_ENOUGH_MONEY = "err_notenoughmoney",
    ERR_BAG_FULL = "err_bagfull",
    ERR_INV_FULL = "err_inventoryfull",
    ERR_2HANDED_EQUIPPED = "err_2h_equipped",
    ERR_PROFICIENCY_NEEDED = "err_proficiencyneeded",
    ERR_CANT_EQUIP_EVER = "err_cantequipever",
    ERR_CANT_EQUIP_SKILL = "err_cantequipskill",
    ERR_AMMO_ONLY = "err_ammoonly",
    ERR_NO_AMMO = "err_noammo",
    ERR_NOT_EQUIPPABLE = "err_notequippable",
    ERR_ITEM_LOCKED = "err_itemlocked",
    ERR_CHEST_IN_USE = "err_chestinuse",
    ERR_ITEM_MAX_COUNT = "err_itemmaxcount",
    ERR_GROUP_FULL = "err_partyfull",
    ERR_DROP_BOUND_ITEM = "err_cantdropsoulbounditem",
    ERR_TRADE_BOUND_ITEM = "err_canttradesoulbounditem",
    ERR_LOOT_DIDNT_KILL = "err_lootdidntkill",
    ERR_NOT_A_BAG = "err_notabag",
    ERR_MUST_EQUIP_ITEM = "err_mustequipitem",
    ERR_CANT_USE_ITEM = "err_cantuseitem",
    ERR_LOOT_LOCKED = "err_cantloot",
}

local KEY2ERR_FMT = {
    ERR_CANT_EQUIP_LEVEL_I = "err_cantequiplevel",
}

local function BuildMaps()
    local _, raceFile = UnitRace("player")
    local sex = UnitSex("player")
    if raceFile then
        playerKey = raceFile .. (sex == 3 and "Female" or "Male")
    end
    wipe(msgMap)
    for key, err in pairs(KEY2ERR) do
        local s = _G[key]
        if type(s) == "string" then
            msgMap[s] = err
        end
    end
    wipe(fmtMatchers)
    for key, err in pairs(KEY2ERR_FMT) do
        local s = _G[key]
        if type(s) == "string" then
            local pat = "^" .. s:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
                :gsub("%%%%d", "%%d+"):gsub("%%%%s", ".+") .. "$"
            fmtMatchers[#fmtMatchers + 1] = { pat, err }
        end
    end
end

local function VoiceEnabled()
    return AscensionESDB and AscensionESDB.voice
end

function AES.SetVoiceEnabled(on)
    if AscensionESDB then AscensionESDB.voice = on end
    if SetCVar then
        SetCVar("Sound_EnableErrorSpeech", on and 0 or 1)
    end
end

local function PlayError(errType)
    local set = playerKey and AES.VoiceFiles[playerKey]
    local files = set and set[errType]
    if not files or #files == 0 then return end
    local now = GetTime and GetTime() or 0
    if now - lastPlay < 3 then return end
    lastPlay = now
    PlaySoundFile(ADDON_PATH .. files[math.random(#files)])
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("UI_ERROR_MESSAGE")
f:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "AscensionES" then
        if AscensionESDB and AscensionESDB.voice == nil then
            AscensionESDB.voice = true
        end
        BuildMaps()
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" then
        BuildMaps()
        if VoiceEnabled() and SetCVar then
            SetCVar("Sound_EnableErrorSpeech", 0)
        end
    elseif event == "UI_ERROR_MESSAGE" then
        if not VoiceEnabled() or not arg1 then return end
        local err = msgMap[arg1]
        if not err then
            for _, m in ipairs(fmtMatchers) do
                if arg1:match(m[1]) then
                    err = m[2]
                    break
                end
            end
        end
        if err then PlayError(err) end
    end
end)
