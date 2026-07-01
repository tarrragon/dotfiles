-- User overrides for Caelestia's Hyprland config
-- Caelestia manages its own hyprland.lua; additions go here.

-- VM cursor fix (virtio-gpu has no hardware cursor)
hl.config({
    cursor = {
        no_hardware_cursors = true,
    },
})

-- Custom keybinds
hl.bind("SUPER", "Return", "exec", "foot")
hl.bind("SUPER SHIFT", "Return", "exec", "foot")
