local _, ns = ...

-- A game key binding (TOGGLETALENTS, TOGGLELEGACYSYSTEM ...) that opens a window of ours while its piece is on: an
-- override binding onto a secure button of ours, pressed through ns.KeyProxy so it acts on press as the game's own.

local KEY_EVENTS = { "UPDATE_BINDINGS", "PLAYER_REGEN_ENABLED", "PLAYER_ENTERING_WORLD" }

-- WindowKey(name, binding, press, escName) -> key: key:Set(on) binds or frees the binding's keys (out of combat; a fight
-- waits for its end). press() runs on the key's release; escName arms Escape for the window in a fight (UI/Escape.lua).
function ns.WindowKey(name, binding, press, escName)
    local key = { on = false }
    local button
    local function Bind()
        if not button or InCombatLockdown() then return end
        ClearOverrideBindings(button)
        if not key.on then return end
        for _, k in ipairs({ GetBindingKey(binding) }) do
            SetOverrideBindingClick(button, true, k, ns.KeyProxy(name), "LeftButton")
        end
    end
    function key:Set(on)
        self.on = on and true or false
        -- Secure, so its click can bind Escape in a fight; its events live on a side frame, as a frame with
        -- registrations can be refused by the secure environment.
        if self.on and not button and not InCombatLockdown() then
            button = CreateFrame("Button", name, UIParent, "SecureActionButtonTemplate")
            button:RegisterForClicks("AnyDown", "AnyUp")
            button:SetAttribute("useOnKeyDown", false)
            button:SetScript("PostClick", function(_, _, down)
                if not down then press() end
            end)
            if escName and ns.EscArmOnClick then ns.EscArmOnClick(button, escName) end
            ns.EventFrame(KEY_EVENTS, Bind)
        end
        Bind()
    end
    return key
end
