local AES = AscensionES
AES.ErrExact = AES.ErrExact or {}
AES.ErrPatterns = AES.ErrPatterns or {}

local function Translate(msg)
    local es = AES.ErrExact[msg]
    if es then return es end
    for _, p in ipairs(AES.ErrPatterns) do
        if msg:match(p[1]) then
            local out = msg:gsub(p[1], p[2])
            return out
        end
    end
    return msg
end

local active = false

local function Enable()
    if active or not UIErrorsFrame then return end
    UIErrorsFrame:UnregisterEvent("UI_ERROR_MESSAGE")
    UIErrorsFrame:UnregisterEvent("UI_INFO_MESSAGE")
    active = true
end

local function Disable()
    if not active or not UIErrorsFrame then return end
    UIErrorsFrame:RegisterEvent("UI_ERROR_MESSAGE")
    UIErrorsFrame:RegisterEvent("UI_INFO_MESSAGE")
    active = false
end

function AES.SetErrorsEnabled(on)
    if AscensionESDB then AscensionESDB.errores = on end
    if on then Enable() else Disable() end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("UI_ERROR_MESSAGE")
f:RegisterEvent("UI_INFO_MESSAGE")
f:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "AscensionES" then
        if AscensionESDB and AscensionESDB.errores == nil then
            AscensionESDB.errores = true
        end
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" then
        if AscensionESDB and AscensionESDB.errores then Enable() end
    elseif event == "UI_ERROR_MESSAGE" then
        if not active then return end
        if arg1 and UIErrorsFrame then
            UIErrorsFrame:AddMessage(Translate(arg1), 1.0, 0.1, 0.1, 1.0)
        end
    elseif event == "UI_INFO_MESSAGE" then
        if not active then return end
        if arg1 and UIErrorsFrame then
            UIErrorsFrame:AddMessage(Translate(arg1), 1.0, 1.0, 0.0, 1.0)
        end
    end
end)
