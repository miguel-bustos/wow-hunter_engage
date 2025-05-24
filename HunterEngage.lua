-- HunterEngage.lua

local addonName = ...
local HunterEngage = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0")

-- Class-specific config
local CLASS_SPELLS = {
    HUNTER = { id = 781, name = "Disengage" },
    DEMONHUNTER = { id = 198793, name = "Vengeful Retreat" },
}

function HunterEngage:OnInitialize()
    self:SetupDatabase()
    self:SetupOptions()
    self:RegisterChatCommand("hunterengage", "OpenConfig")

    -- Ensure smooth camera view transitions
    SetCVar("cameraViewBlendStyle", "2")

    local loginFrame = CreateFrame("Frame")
    loginFrame:RegisterEvent("PLAYER_LOGIN")
    loginFrame:SetScript("OnEvent", function()
        self:SetupSecureButton()
    end)
end

function HunterEngage:SetupSecureButton()
    local class = UnitClassBase("player")
    local spellData = CLASS_SPELLS[class]
    if not spellData then return end
    if not IsPlayerSpell(spellData.id) then return end

    local spellName = spellData.name
    local profile = self.db and self.db.profile
    if not profile then return end

    local key = profile.key
    local delay = tonumber(profile.viewResetDelay) or 0.15

    if not key or key == "" then
        if profile.debug then
            self:Print(string.format("[%s] No keybind set. Please configure one in the addon options.", addonName))
        end
        return
    end

    -- Remove existing secure button
    if self.secureButton then
        ClearOverrideBindings(self.secureButton)
        self.secureButton:Hide()
        self.secureButton:SetParent(nil)
        self.secureButton = nil
    end

    -- Macro logic
    local macroDown = table.concat({
        "/console ActionButtonUseKeyDown 0",
        "/run _G.HunterEngageWasMouselooking = IsMouselooking()",
        "/run MouselookStop()",
        "/run SaveView(1)",
        "/run SetView(2)",
        "/run MouselookStart()",
        "/run MouselookStop()",
    }, "\n")

    local macroUp = table.concat({
        "/cast " .. spellName,
        "/run MouselookStart()",
        "/run MouselookStop()",
        "/run if _G.HunterEngageWasMouselooking then MouselookStart() end",
        "/run _G.HunterEngageWasMouselooking = nil",
        string.format("/run C_Timer.After(%.2f, function() SetView(1) end)", delay),
        "/console ActionButtonUseKeyDown 1",
    }, "\n")

    -- Create secure button
    local btn = CreateFrame("Button", "HunterEngageSecureButton", UIParent, "SecureActionButtonTemplate")
    self.secureButton = btn
    btn:RegisterForClicks("AnyDown", "AnyUp")
    btn:SetAttribute("type", "macro")
    btn:SetAttribute("macrotext", macroDown)
    btn:SetAttribute("macrotextDown", macroDown)
    btn:SetAttribute("macrotextUp", macroUp)
    btn:SetAttribute("pressAndHoldAction", true)
    btn:SetAttribute("typerelease", "macro")
    btn:SetPoint("CENTER")
    btn:SetSize(1, 1)
    btn:Show()

    SecureHandlerWrapScript(btn, "OnClick", btn, [[
        if down then
            self:SetAttribute("macrotext", self:GetAttribute("macrotextDown"))
        else
            self:SetAttribute("macrotext", self:GetAttribute("macrotextUp"))
        end
    ]])

    ClearOverrideBindings(btn)
    SetOverrideBindingClick(btn, true, key, "HunterEngageSecureButton")

    if profile.debug then
        self:Print(string.format("%s ready on [%s] with delay %.2fs", spellName, key, delay))
    end
end

function HunterEngage:OpenConfig()
    InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
    InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
end
