-- HunterEngage_Options.lua

local addonName = ...
local HunterEngage = LibStub("AceAddon-3.0"):GetAddon(addonName)
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceDBOptions = LibStub("AceDBOptions-3.0")

function HunterEngage:SetupDatabase()
    if not self.db then
        self.db = LibStub("AceDB-3.0"):New("HunterEngageDB", {
            profile = {
                debug = false,
                key = nil,
                viewResetDelay = 0.15,
            },
        }, true)
    end
end

function HunterEngage:SetupOptions()
    local capturingKey = false

    local function getFormattedKey()
        return self.db.profile.key or "<not set>"
    end

    local options = {
        name = "Hunter Engage",
        type = "group",
        args = {
            info = {
                order = 0,
                type = "description",
                name = "\nMake Disengage launch forward by temporarily rotating the camera.\n",
                fontSize = "medium",
                width = "full",
            },
            keybindGroup = {
                type = "group",
                inline = true,
                name = "",
                order = 1,
                args = {
                    keybindDisplay = {
                        type = "description",
                        name = function()
                            return "Current Keybind: |cff99ff99" .. getFormattedKey() .. "|r"
                        end,
                        width = 1.2,
                        order = 1,
                    },
                    keybind = {
                        type = "execute",
                        name = "Set Keybind",
                        desc = "Click to capture a new keybind (supports modifiers)",
                        func = function()
                            capturingKey = true
                            self:Print("Press a key to bind... (with any modifiers)")
                        end,
                        width = 0.8,
                        order = 2,
                    },
                },
            },
            delay = {
                order = 2,
                type = "range",
                name = "Camera Reset Delay",
                desc = "Delay before camera resets to View 1 after Disengage",
                min = 0.01,
                max = 1.0,
                step = 0.01,
                get = function() return self.db.profile.viewResetDelay end,
                set = function(_, val)
                    if self.db.profile.viewResetDelay ~= val then
                        self.db.profile.viewResetDelay = val
                        self:SetupSecureButton()
                    end
                end,
                width = 1.2,
            },
			cameraTools = {
				type = "group",
				inline = true,
				name = "View 2 Setup",
				order = 3,
				args = {
					description = {
						order = 0,
						type = "description",
						fontSize = "medium",
						name = "Hunter Engage uses WoW's built-in camera views to rotate the camera during Disengage.\n" ..
							   "View 2 is used as the forward-facing camera angle for the jump.\n" ..
							   "You can manually set or auto-generate View 2 using the buttons below.",
						width = "full",
					},
					saveView2 = {
						type = "execute",
						name = "Save Current View as View 2",
						desc = "Saves your current camera position as View 2",
						func = function()
							SaveView(2)
							print("|cff00ff00Hunter Engage: Saved current view as View 2.|r")
						end,
						order = 1,
						width = 1.4,
					},
					autoRotate = {
						type = "execute",
						name = "Auto-Rotate 180° and Save as View 2",
						desc = "Rotates camera 180° and saves it as View 2",
						func = function()
							MoveViewLeftStart()
							C_Timer.After(1.0, function()
								MoveViewLeftStop()
								SaveView(2)
								print("|cff00ff00Hunter Engage: Rotated and saved View 2.|r")
							end)
						end,
						order = 2,
						width = 1.6,
					},
				},
			},
			limitationNote = {
				order = 3.5,
				type = "description",
				fontSize = "medium",
				name = "|cffffcc00Note|r: Due to restrictions in WoW's secure environment, the addon cannot restore left/right mouse button movement after rotating the camera. If you are holding both mouse buttons to move your character while pressing the Engage key, the camera may reset incorrectly. This is a technical limitation and cannot be bypassed.",
				width = "full",
			},
            debug = {
                order = 4,
                type = "toggle",
                name = "Enable debug output",
                desc = "Print internal debug messages to chat",
                get = function() return self.db.profile.debug end,
                set = function(_, val) self.db.profile.debug = val end,
                width = "full",
            },
        },
    }

    AceConfig:RegisterOptionsTable(addonName, options)
    self.optionsFrame = AceConfigDialog:AddToBlizOptions(addonName, "Hunter Engage")

    AceConfig:RegisterOptionsTable("HunterEngage_Profiles", AceDBOptions:GetOptionsTable(self.db))
    AceConfigDialog:AddToBlizOptions("HunterEngage_Profiles", "Profiles", "Hunter Engage")

    -- Key capture frame
    local keyFrame = CreateFrame("Frame", nil, UIParent)
    keyFrame:SetPropagateKeyboardInput(true)
    keyFrame:EnableKeyboard(true)
    keyFrame:SetPoint("CENTER")
    keyFrame:SetSize(1, 1)
    keyFrame:Show()

    keyFrame:SetScript("OnKeyDown", function(_, key)
        if not capturingKey or not key or key == "" or #key > 10 then return end
        if key:match("SHIFT") or key:match("CTRL") or key:match("ALT") or key:match("META") then return end

        capturingKey = false

        local bind = ""
        if IsAltKeyDown() then bind = bind .. "ALT-" end
        if IsControlKeyDown() then bind = bind .. "CTRL-" end
        if IsShiftKeyDown() then bind = bind .. "SHIFT-" end
        bind = bind .. key:upper()

        self.db.profile.key = bind
        self:Print("|cff99ff99New keybind set to [" .. bind .. "]|r")

        self:SetupSecureButton()
        AceConfigDialog:SelectGroup("Hunter Engage")
    end)
end
