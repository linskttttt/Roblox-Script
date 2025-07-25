local library = loadstring(game:HttpGet('https://raw.githubusercontent.com/linskttttt/Roblox-Script/refs/heads/main/UI/UILib.lua'))()

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Main Window
local ALSHUB = library:CreateWindow({
    Name = "All Services",
    Themeable = {
        Info = "discord.gg/allservice"
    }
})

local AutoTab = ALSHUB:CreateTab({ Name = "Auto" })

-- Core Match
local Place = AutoTab:CreateSection({ Name = "Auto Place", Side = "Left" })
Place:AddToggle{ Name="Enable Auto Place", Flag="Auto_Place", Callback=function(s) print("Place:",s) end }
Place:AddDropdown{ Name="Unit Slot", Flag="Auto_Place_Slot", List={"Slot 1","Slot 2","Slot 3","Slot 4","Slot 5","Slot 6"}, Callback=function(v) print("Slot:",v) end }
Place:AddSlider{ Name="Placement Delay", Flag="Auto_Place_Delay", Min=0, Max=10, Value=1, Callback=function(v) print("Place Delay:",v) end }

local Upgrade = AutoTab:CreateSection({ Name = "Auto Upgrade", Side = "Right" })
Upgrade:AddToggle{ Name="Enable Auto Upgrade", Flag="Auto_Upgrade", Callback=function(s) print("Upgrade:",s) end }
Upgrade:AddToggle{ Name="Max Level Only", Flag="Auto_Upgrade_Max", Callback=function(s) print("Max Only:",s) end }
Upgrade:AddToggle{ Name="Skip Support Units", Flag="Auto_Upgrade_NoSupport", Callback=function(s) print("Skip Support:",s) end }
Upgrade:AddSlider{ Name="Upgrade Delay", Flag="Auto_Upgrade_Delay", Min=0, Max=10, Value=2, Callback=function(v) print("Upgrade Delay:",v) end }

local Sell = AutoTab:CreateSection({ Name = "Auto Sell", Side = "Left" })
Sell:AddToggle{ Name="Enable Auto Sell", Flag="Auto_Sell", Callback=function(s) print("Sell:",s) end }
Sell:AddTextbox{ Name="Sell On Wave", Flag="Auto_Sell_Wave", Placeholder="e.g. 50", Callback=function(w) print("Sell Wave:",w) end }
Sell:AddToggle{ Name="Only Sell on Boss", Flag="Auto_Sell_Boss", Callback=function(s) print("Boss Sell:",s) end }

local Skip = AutoTab:CreateSection({ Name = "Auto Skip Waves", Side = "Left" })
Skip:AddToggle{ Name="Enable Auto Skip", Flag="Auto_Skip", Callback=function(s) print("Skip:",s) end }
Skip:AddSlider{ Name="Skip Delay", Flag="Auto_Skip_Delay", Min=0, Max=15, Value=2, Callback=function(v) print("Skip Delay:",v) end }

local Replay = AutoTab:CreateSection({ Name = "Auto Replay", Side = "Right" })
Replay:AddToggle{ Name="Enable Auto Replay", Flag="Auto_Replay", Callback=function(s) print("Replay:",s) end }
Replay:AddToggle{ Name="Retry if Defeated", Flag="Auto_Retry", Callback=function(s) print("Retry:",s) end }

local Smart = AutoTab:CreateSection({ Name = "Smart Logic", Side = "Left" })
Smart:AddToggle{ Name="Only Place DPS Units", Flag="Smart_DPSOnly", Callback=function(s) print("DPS Only:",s) end }
Smart:AddToggle{ Name="Set Unit Target Priority", Flag="Smart_Targeting", Callback=function(s) print("Target Priority:",s) end }

-- Ability Categories
local Ability = AutoTab:CreateSection({ Name = "Auto Ability Types", Side = "Right" })
Ability:AddToggle{ Name="Auto Buffer Units", Flag="Auto_Buffers", Callback=function(s) print("Buffers:",s) end }
Ability:AddToggle{ Name="Auto Stuns / Stop", Flag="Auto_Stuns", Callback=function(s) print("Stuns:",s) end }
Ability:AddToggle{ Name="Auto Debuff / DoT Units", Flag="Auto_DOTs", Callback=function(s) print("Debuffs:",s) end }
Ability:AddToggle{ Name="Auto Nuke / Ultimate Units", Flag="Auto_Nukes", Callback=function(s) print("Nukes:",s) end }
Ability:AddToggle{ Name="Auto Summoner Units", Flag="Auto_Summoners", Callback=function(s) print("Summoners:",s) end }
Ability:AddToggle{ Name="Auto Economy Units", Flag="Auto_Economy", Callback=function(s) print("Economy:",s) end }
Ability:AddSlider{ Name="Global Ability Delay (sec)", Flag="Auto_Ability_Delay", Min=1, Max=60, Value=8, Callback=function(v) print("Ability Delay:",v) end }


-- MAP Tab
local MapTab = ALSHUB:CreateTab({ Name = "Map" })

-- SECTION: Story Mode
local StorySec = MapTab:CreateSection({ Name = "Story Mode", Side = "Left" })
StorySec:AddDropdown({ Name = "Select Story Arc", Flag = "Map_Story_Arc", List = {"Arc 1","Arc 2","Arc 3","Arc 4","Arc 5"}, Callback = function(v) print("Arc:",v) end })
StorySec:AddDropdown({ Name = "Select Stage (1‑6)", Flag = "Map_Story_Stage", List = {"1","2","3","4","5","6"}, Callback = function(v) print("Stage:", v) end })
StorySec:AddToggle({ Name = "Auto Start Story", Flag = "Map_Story_AutoStart", Callback = function(s) print("Auto Story:", s) end })
StorySec:AddToggle({ Name = "Loop Story Arc", Flag = "Map_Story_Loop", Callback = function(s) print("Loop Arc:", s) end })

-- SECTION: Infinite Mode
local InfSec = MapTab:CreateSection({ Name = "Infinite Mode", Side = "Right" })
InfSec:AddToggle({ Name = "Auto Join Infinite", Flag = "Map_Infinite_Auto", Callback = function(s) print("Infinite Auto:", s) end })
InfSec:AddToggle({ Name = "Extreme Mode", Flag = "Map_Infinite_Extreme", Callback = function(s) print("Extreme Mode:", s) end })
InfSec:AddToggle({ Name = "Auto Skip Waves", Flag = "Map_Infinite_Skip", Callback = function(s) print("Inf Skip:", s) end })

-- SECTION: Trials & Challenges
local TrialsSec = MapTab:CreateSection({ Name = "Trials / Challenges", Side = "Left" })
TrialsSec:AddDropdown({ Name = "Select Trial", Flag = "Map_Trial_Number", List = {"Trial 1","Trial 2","Trial 3"}, Callback = function(v) print("Trial:", v) end })
TrialsSec:AddToggle({ Name = "Auto Join Trial", Flag = "Map_Trial_Auto", Callback = function(s) print("Auto Trial:", s) end })
TrialsSec:AddToggle({ Name = "Auto Retry Trial", Flag = "Map_Trial_Retry", Callback = function(s) print("Retry Trial:", s) end })
TrialsSec:AddToggle({ Name = "Auto Join Daily Challenge", Flag = "Map_Challenge_Auto", Callback = function(s) print("Challenge Auto:", s) end })
TrialsSec:AddToggle({ Name = "Expert Difficulty", Flag = "Map_Challenge_Expert", Callback = function(s) print("Expert Challenge:", s) end })

-- SECTION: Raids & Dungeon
local RaidSec = MapTab:CreateSection({ Name = "Raids & Dungeon", Side = "Right" })
RaidSec:AddDropdown({ Name = "Select Raid World", Flag = "Map_Raid_World", List = {"World 1 Raid","World 2 Raid","Android Raid","Candyland","String Raid","Bizarre Raid","Marine HQ","Kai Planet","Hell","Machi Planet"}, Callback = function(v) print("Raid:", v) end })
RaidSec:AddToggle({ Name = "Auto Join Raid", Flag = "Map_Raid_Auto", Callback = function(s) print("Auto Raid:", s) end })
RaidSec:AddToggle({ Name = "Auto Enter Dungeon", Flag = "Map_Dungeon_Auto", Callback = function(s) print("Auto Dungeon:", s) end })

-- SECTION: Endless & NPC Missions
local MiscSec = MapTab:CreateSection({ Name = "Endless / NPC Missions", Side = "Left" })
MiscSec:AddToggle({ Name = "Auto Endless Mode (Post‑Arc6)", Flag = "Map_Endless_Auto", Callback = function(s) print("Auto Endless:", s) end })
MiscSec:AddToggle({ Name = "Auto Enter NPC Missions", Flag = "Map_NPC_Auto", Callback = function(s) print("Auto NPC:", s) end })

    
-- Macros Tab
local MacrosTab = ALSHUB:CreateTab({ Name = "Macros" })

-- SECTION: Macro Control
local MacroSec = MacrosTab:CreateSection({ Name = "Macro Control", Side = "Left" })
MacroSec:AddButton({ Name = "Start Recording", Callback = function() print("Record started") end })
MacroSec:AddButton({ Name = "Stop Recording", Callback = function() print("Record stopped") end })
MacroSec:AddButton({ Name = "Play Macro", Callback = function() print("Macro playing") end })
MacroSec:AddToggle({ Name = "Loop Macro", Flag = "Macro_Loop", Callback = function(s) print("Macro Loop:", s) end })
MacroSec:AddToggle({ Name = "Retry on Fail", Flag = "Macro_RetryFail", Callback = function(s) print("Retry Fail:", s) end })

-- SECTION: Macro Settings
local MacroSettings = MacrosTab:CreateSection({ Name = "Macro Settings", Side = "Right" })
MacroSettings:AddDropdown({
  Name = "Macro Preset (by Map)",
  Flag = "Macro_Preset_Map",
  List = {"Story1-1", "Trial1", "Infinite", "Raid1", "Challenge"},
  Callback = function(v) print("Using Preset:", v) end
})
MacroSettings:AddSlider({
  Name = "Step Delay (ms)",
  Flag = "Macro_StepDelay",
  Min = 50,
  Max = 2000,
  Value = 500,
  Callback = function(v) print("Step delay:", v) end
})
MacroSettings:AddTextbox({
  Name = "Manual Delay (sec)",
  Flag = "Macro_ManualDelay",
  Placeholder = "e.g. 2",
  Callback = function(v) print("Manual Delay:", v) end
})

-- SECTION: Macro Management
local MacroMgmt = MacrosTab:CreateSection({ Name = "Macro Management", Side = "Left" })
MacroMgmt:AddButton({ Name = "Save Macro to File", Callback = function() print("Saved macro") end })
MacroMgmt:AddButton({ Name = "Load Macro from File", Callback = function() print("Loaded macro") end })
MacroMgmt:AddButton({ Name = "Import Macro from JSON", Callback = function() print("Imported macro") end })
MacroMgmt:AddButton({ Name = "Export Macro to JSON", Callback = function() print("Exported macro") end })




-- Webhooks Tab
local WebhooksTab = ALSHUB:CreateTab({ Name = "Webhooks" })

-- SECTION: Webhook Configuration
local ConfigSec = WebhooksTab:CreateSection({ Name = "Webhook Config", Side = "Left" })
ConfigSec:AddTextbox({
    Name = "Discord Webhook URL",
    Flag = "Webhook_URL",
    Placeholder = "https://discord.com/api/..",
    Callback = function(url) print("Webhook URL set to:", url) end
})
ConfigSec:AddToggle({
    Name = "Enable Webhook Logging",
    Flag = "Webhook_Enabled",
    Callback = function(s) print("Webhook Logging:", s) end
})

-- SECTION: Events to Log
local EventsSec = WebhooksTab:CreateSection({ Name = "Events to Log", Side = "Right" })
EventsSec:AddToggle({ Name = "Match End Result", Flag = "Webhook_MatchEnd", Callback = function(s) print("Log Match End:", s) end })
EventsSec:AddToggle({ Name = "Unit Summon / Pull", Flag = "Webhook_Summon", Callback = function(s) print("Log Summon:", s) end })
EventsSec:AddToggle({ Name = "Gems / Rewards Earned", Flag = "Webhook_Gems", Callback = function(s) print("Log Gems:", s) end })
EventsSec:AddToggle({ Name = "Auto Replay or Farm Failures", Flag = "Webhook_Failures", Callback = function(s) print("Log Failures:", s) end })

-- SECTION: Advanced Options
local AdvSec = WebhooksTab:CreateSection({ Name = "Advanced Webhook Options", Side = "Left" })
AdvSec:AddToggle({ Name = "Webhook on Macro Playback", Flag = "Webhook_Macro", Callback = function(s) print("Macro Events:", s) end })
AdvSec:AddToggle({ Name = "Webhook on Auto Sell Trigger", Flag = "Webhook_Sell", Callback = function(s) print("Sell Event:", s) end })
AdvSec:AddToggle({ Name = "Webhook on Ability Use", Flag = "Webhook_Ability", Callback = function(s) print("Ability Used:", s) end })
AdvSec:AddTextbox({ Name = "Player Discord Tag (optional)", Flag = "Webhook_Tag", Placeholder = "e.g. Username#1234", Callback = function(t) print("Player Tag:", t) end })



-- Misc Tab
local MiscTab = ALSHUB:CreateTab({
    Name = "Misc"
})
