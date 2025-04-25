-- Project Sentinel - Configuration File

Config = {}

-- General Settings
Config.EnableNotifications = true -- Enable/disable notification system
Config.ReportCooldown = 60 -- Cooldown between reports in seconds
Config.AdminKey = 168 -- F7 key to access admin panel (Default: F7)
Config.ReportKey = 170 -- F11 key to access report panel (Default: F11)

-- Discord Integration
Config.DiscordWebhook = "YOUR_DISCORD_WEBHOOK_URL_HERE" -- Discord webhook URL for notifications
Config.EnableDiscordDM = false -- Enable/disable Discord DM notifications (requires a bot)
Config.BotToken = "YOUR_BOT_TOKEN_HERE" -- Discord bot token (if Discord DM is enabled)

-- JSON Storage Settings
Config.DataFolders = {
    Reports = "reports",      -- File to store player reports
    AdminRanks = "admin_ranks", -- File to store admin ranks/permissions
    Logs = "activity_logs"    -- File to store admin activity logs
}

-- Report Categories (for the report UI)
Config.ReportCategories = {
    "Player Report",
    "Bug Report",
    "Question",
    "Other"
}

-- Default Admin Outfits (can be customized based on your server's clothing system)
Config.AdminOutfits = {
    -- Example outfits (you may need to adjust these based on your clothing system)
    supporter = {
        male = {
            tshirt_1 = 15,
            tshirt_2 = 0,
            torso_1 = 287,
            torso_2 = 2,
            pants_1 = 114,
            pants_2 = 2,
            shoes_1 = 78,
            shoes_2 = 2
        },
        female = {
            tshirt_1 = 14,
            tshirt_2 = 0,
            torso_1 = 300,
            torso_2 = 2,
            pants_1 = 121,
            pants_2 = 2,
            shoes_1 = 82,
            shoes_2 = 2
        }
    },
    -- Add more outfits for different ranks if needed
}