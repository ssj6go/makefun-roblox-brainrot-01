-- Brainrot Bay: tuning constants shared by server and client.
-- One place for every number the game balances on, so a rebalance
-- never means hunting the same literal through a dozen scripts.

local Config = {}

-- Money
Config.StartingCash = 100
Config.SellRefundFraction = 0.5

-- Conveyor: brainrots walk the belt from west to east and leave
-- unclaimed at the far end.
Config.ConveyorStartX = -45
Config.ConveyorEndX = 45
Config.ConveyorZ = 0
Config.ConveyorSpeed = 4 -- studs per second
Config.SpawnIntervalSeconds = 6
Config.MaxConveyorBrainrots = 8

-- Bases: six plots in a ring around the plaza.
Config.BaseCount = 6
Config.BaseRadius = 65 -- distance from map centre to each base centre
Config.BaseSize = 26 -- platform is BaseSize x BaseSize studs
Config.SlotsPerBase = 6

-- Stealing
Config.StealHoldSeconds = 1.2
Config.StealCooldownSeconds = 60
Config.BaseShieldSeconds = 30 -- after a steal, the victim's base cannot be stolen from
Config.NewPlacementLockSeconds = 10 -- a just-placed brainrot cannot be stolen yet
Config.BaseLockSeconds = 30 -- owner-activated lock
Config.BaseLockCooldownSeconds = 120

-- Tsunami: the wave that sweeps the map and punishes stragglers.
Config.WaveIntervalSeconds = 120
Config.WaveWarningSeconds = 10
Config.WaveSweepSeconds = 8
Config.WaveStartX = -90
Config.WaveEndX = 90

-- Rebirth: reset cash and placed brainrots for a permanent multiplier.
Config.RebirthBaseCost = 5000
Config.RebirthCostGrowth = 2 -- cost = base * growth ^ rebirths
Config.RebirthMultiplierStep = 0.5 -- +50% income per rebirth

-- Earnings and HUD refresh
Config.EarningsTickSeconds = 1
Config.StateBroadcastSeconds = 1
Config.LeaderboardSize = 5

-- Persistence
Config.DataStoreName = "BrainrotBayDataV1"
Config.AutoSaveSeconds = 60

return Config
