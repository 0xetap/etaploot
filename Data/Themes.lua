local _, EL = ...

EL.themes = {
    parchment = {
        label = "Parchment",
        background = { 0.18, 0.13, 0.07, 0.96 },
        border = { 0.72, 0.53, 0.25, 1 },
        header = { 0.30, 0.20, 0.09, 1 },
        text = { 1, 0.88, 0.62, 1 },
        accent = { 1, 0.72, 0.20, 1 },
    },
    midnight = {
        label = "Midnight",
        background = { 0.015, 0.025, 0.08, 0.96 },
        border = { 0.24, 0.36, 0.78, 1 },
        header = { 0.035, 0.07, 0.18, 1 },
        text = { 0.78, 0.84, 1, 1 },
        accent = { 0.48, 0.60, 1, 1 },
    },
    battlenet = {
        label = "Battle.net",
        background = { 0.045, 0.050, 0.065, 0.98 },
        border = { 0.19, 0.20, 0.24, 1 },
        header = { 0.085, 0.090, 0.110, 1 },
        text = { 0.88, 0.89, 0.92, 1 },
        accent = { 0.055, 0.52, 0.96, 1 },
        button = { 0.145, 0.150, 0.175, 0.96 },
        buttonBorder = { 0.22, 0.23, 0.27, 1 },
        buttonHover = { 0.18, 0.19, 0.22, 1 },
        buttonHoverBorder = { 0.055, 0.52, 0.96, 0.90 },
        gradient = {
            from = { 0.075, 0.095, 0.135, 0.18 },
            to = { 0.025, 0.030, 0.045, 0.06 },
        },
        headerGradient = {
            from = { 0.115, 0.120, 0.145, 0.76 },
            to = { 0.060, 0.065, 0.085, 0.54 },
        },
    },
    web3 = {
        label = "Aurora",
        background = { 0.025, 0.03, 0.065, 0.97 },
        border = { 0.30, 0.38, 0.58, 1 },
        header = { 0.055, 0.06, 0.12, 1 },
        text = { 0.88, 0.90, 0.96, 1 },
        accent = { 0.58, 0.76, 0.86, 1 },
        gradient = {
            from = { 0.30, 0.24, 0.52, 0.20 },
            to = { 0.12, 0.38, 0.43, 0.14 },
        },
        headerGradient = {
            from = { 0.27, 0.22, 0.45, 0.62 },
            to = { 0.10, 0.34, 0.39, 0.54 },
        },
    },
    glass = {
        label = "Frosted Glass",
        background = { 0.035, 0.060, 0.080, 0.76 },
        border = { 0.46, 0.64, 0.72, 0.62 },
        header = { 0.075, 0.115, 0.145, 0.78 },
        text = { 0.91, 0.96, 0.98, 1 },
        accent = { 0.58, 0.82, 0.90, 1 },
        gradient = {
            from = { 0.30, 0.48, 0.58, 0.18 },
            to = { 0.18, 0.15, 0.34, 0.12 },
        },
        headerGradient = {
            from = { 0.34, 0.52, 0.62, 0.42 },
            to = { 0.20, 0.22, 0.42, 0.32 },
        },
    },
}

function EL:UpdateClassTheme()
    local classFile = select(2, UnitClass("player"))
    local color = classFile and RAID_CLASS_COLORS[classFile] or RAID_CLASS_COLORS.WARRIOR
    local r, g, b = color.r, color.g, color.b
    self.themes.class = {
        label = "Class",
        background = { 0.012 + (r * 0.10), 0.014 + (g * 0.10), 0.018 + (b * 0.10), 1 },
        border = { 0.20 + (r * 0.65), 0.20 + (g * 0.65), 0.20 + (b * 0.65), 1 },
        header = { 0.035 + (r * 0.24), 0.038 + (g * 0.24), 0.045 + (b * 0.24), 1 },
        text = { 0.94, 0.95, 0.98, 1 },
        accent = { r, g, b, 1 },
        gradient = {
            from = { r, g, b, 0.22 },
            to = { r * 0.30, g * 0.30, b * 0.30, 0.08 },
        },
        headerGradient = {
            from = { r, g, b, 0.34 },
            to = { r * 0.42, g * 0.42, b * 0.42, 0.18 },
        },
    }
end

