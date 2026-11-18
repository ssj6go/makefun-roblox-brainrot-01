-- Brainrot Bay: the cast. Fourteen original absurd meme characters on a
-- ladder of seven rarities, plus the mutations that multiply their income.
-- Nothing here copies any existing game: every name, colour and blurb is
-- invented for this game.

local BrainrotCatalog = {}

-- Rarity ladder, cheapest first. Colour is the label colour the HUD and
-- the in-world name tags use for the tier.
BrainrotCatalog.Rarities = {
	{ Name = "Common", Color = Color3.fromRGB(150, 200, 120), Weight = 40 },
	{ Name = "Rare", Color = Color3.fromRGB(90, 160, 255), Weight = 25 },
	{ Name = "Epic", Color = Color3.fromRGB(180, 110, 255), Weight = 15 },
	{ Name = "Legendary", Color = Color3.fromRGB(255, 200, 40), Weight = 10 },
	{ Name = "Mythic", Color = Color3.fromRGB(255, 90, 140), Weight = 6 },
	{ Name = "Divine", Color = Color3.fromRGB(60, 240, 230), Weight = 3 },
	{ Name = "Secret", Color = Color3.fromRGB(255, 255, 255), Weight = 1 },
}

-- Mutations roll on spawn. The cost stays the same: a mutation is luck.
BrainrotCatalog.Mutations = {
	{ Name = "Normal", Multiplier = 1, Chance = 0.86, Color = nil },
	{ Name = "Golden", Multiplier = 2, Chance = 0.10, Color = Color3.fromRGB(255, 215, 0) },
	{ Name = "Diamond", Multiplier = 5, Chance = 0.03, Color = Color3.fromRGB(170, 235, 255) },
	{ Name = "Rainbow", Multiplier = 10, Chance = 0.01, Color = Color3.fromRGB(255, 120, 200) },
}

-- Accessory names are the little props WorldBuilder bolts onto each model.
BrainrotCatalog.Entries = {
	{
		Id = "toaster-toad",
		Name = "Toaster Toad",
		Rarity = "Common",
		Cost = 50,
		Rate = 5,
		BodyColor = Color3.fromRGB(90, 180, 90),
		AccentColor = Color3.fromRGB(200, 200, 200),
		Accessory = "toaster",
		Blurb = "Ribbit. Your bread is ready.",
	},
	{
		Id = "sock-sloth",
		Name = "Sock Sloth",
		Rarity = "Common",
		Cost = 75,
		Rate = 7,
		BodyColor = Color3.fromRGB(150, 110, 80),
		AccentColor = Color3.fromRGB(255, 150, 200),
		Accessory = "sock",
		Blurb = "Loses one sock per nap. Still rich.",
	},
	{
		Id = "pillow-penguin",
		Name = "Pillow Penguin",
		Rarity = "Rare",
		Cost = 200,
		Rate = 15,
		BodyColor = Color3.fromRGB(60, 80, 140),
		AccentColor = Color3.fromRGB(255, 255, 255),
		Accessory = "pillow",
		Blurb = "Sleeps 23 hours a day. Earns anyway.",
	},
	{
		Id = "noodle-newt",
		Name = "Noodle Newt",
		Rarity = "Rare",
		Cost = 300,
		Rate = 22,
		BodyColor = Color3.fromRGB(255, 220, 120),
		AccentColor = Color3.fromRGB(220, 80, 60),
		Accessory = "noodles",
		Blurb = "Slippery. Seasoned. Suspiciously wealthy.",
	},
	{
		Id = "spaghetti-squid",
		Name = "Spaghetti Squid",
		Rarity = "Epic",
		Cost = 600,
		Rate = 40,
		BodyColor = Color3.fromRGB(240, 200, 140),
		AccentColor = Color3.fromRGB(180, 60, 60),
		Accessory = "meatball",
		Blurb = "Eight arms, all of them al dente.",
	},
	{
		Id = "banana-badger",
		Name = "Banana Badger",
		Rarity = "Epic",
		Cost = 800,
		Rate = 55,
		BodyColor = Color3.fromRGB(255, 225, 60),
		AccentColor = Color3.fromRGB(90, 70, 50),
		Accessory = "peel",
		Blurb = "Peels out. Literally. Every morning.",
	},
	{
		Id = "disco-duck",
		Name = "Disco Duck",
		Rarity = "Legendary",
		Cost = 1500,
		Rate = 100,
		BodyColor = Color3.fromRGB(255, 215, 60),
		AccentColor = Color3.fromRGB(255, 80, 200),
		Accessory = "discoBall",
		Blurb = "Quacks in 4/4 time. Never stops grooving.",
	},
	{
		Id = "turbo-turnip",
		Name = "Turbo Turnip",
		Rarity = "Legendary",
		Cost = 2000,
		Rate = 140,
		BodyColor = Color3.fromRGB(200, 120, 220),
		AccentColor = Color3.fromRGB(120, 255, 120),
		Accessory = "spoiler",
		Blurb = "0 to 60 in a salad. Vroom.",
	},
	{
		Id = "quantum-quokka",
		Name = "Quantum Quokka",
		Rarity = "Mythic",
		Cost = 4000,
		Rate = 250,
		BodyColor = Color3.fromRGB(140, 220, 255),
		AccentColor = Color3.fromRGB(255, 255, 255),
		Accessory = "atom",
		Blurb = "Smiles in two places at once.",
	},
	{
		Id = "laser-llama",
		Name = "Laser Llama",
		Rarity = "Mythic",
		Cost = 5500,
		Rate = 350,
		BodyColor = Color3.fromRGB(255, 150, 180),
		AccentColor = Color3.fromRGB(255, 60, 60),
		Accessory = "laserEyes",
		Blurb = "Do not make eye contact. It charges rent.",
	},
	{
		Id = "galactic-gnome",
		Name = "Galactic Gnome",
		Rarity = "Divine",
		Cost = 10000,
		Rate = 600,
		BodyColor = Color3.fromRGB(80, 100, 255),
		AccentColor = Color3.fromRGB(255, 220, 120),
		Accessory = "planet",
		Blurb = "Guards gardens across twelve galaxies.",
	},
	{
		Id = "cosmic-cactus",
		Name = "Cosmic Cactus",
		Rarity = "Divine",
		Cost = 14000,
		Rate = 850,
		BodyColor = Color3.fromRGB(60, 200, 120),
		AccentColor = Color3.fromRGB(255, 120, 220),
		Accessory = "star",
		Blurb = "Blooms once per supernova. Worth it.",
	},
	{
		Id = "invisible-igloo",
		Name = "Invisible Igloo",
		Rarity = "Secret",
		Cost = 25000,
		Rate = 1500,
		BodyColor = Color3.fromRGB(200, 240, 255),
		AccentColor = Color3.fromRGB(255, 255, 255),
		Accessory = "snowflake",
		Blurb = "You cannot see it. It can see your wallet.",
	},
	{
		Id = "ceo-of-frogs",
		Name = "CEO of Frogs",
		Rarity = "Secret",
		Cost = 40000,
		Rate = 2500,
		BodyColor = Color3.fromRGB(40, 160, 80),
		AccentColor = Color3.fromRGB(30, 30, 30),
		Accessory = "briefcase",
		Blurb = "Runs a Fortune 500 pond. Ribbit, shareholders.",
	},
}

local byId = {}
for _, entry in ipairs(BrainrotCatalog.Entries) do
	byId[entry.Id] = entry
end

local rarityByName = {}
for _, rarity in ipairs(BrainrotCatalog.Rarities) do
	rarityByName[rarity.Name] = rarity
end

local mutationByName = {}
for _, mutation in ipairs(BrainrotCatalog.Mutations) do
	mutationByName[mutation.Name] = mutation
end

function BrainrotCatalog.GetEntry(id)
	return byId[id]
end

function BrainrotCatalog.GetRarity(name)
	return rarityByName[name]
end

function BrainrotCatalog.GetMutation(name)
	return mutationByName[name]
end

-- Weighted pick: rarer tiers roll less often, and within a tier each
-- character is equally likely.
function BrainrotCatalog.PickRandomEntry(rng)
	local totalWeight = 0
	for _, rarity in ipairs(BrainrotCatalog.Rarities) do
		totalWeight += rarity.Weight
	end
	local roll = rng:NextNumber() * totalWeight
	local pickedRarity = BrainrotCatalog.Rarities[1]
	for _, rarity in ipairs(BrainrotCatalog.Rarities) do
		roll -= rarity.Weight
		if roll <= 0 then
			pickedRarity = rarity
			break
		end
	end
	local candidates = {}
	for _, entry in ipairs(BrainrotCatalog.Entries) do
		if entry.Rarity == pickedRarity.Name then
			table.insert(candidates, entry)
		end
	end
	return candidates[rng:NextInteger(1, #candidates)]
end

function BrainrotCatalog.RollMutation(rng)
	local roll = rng:NextNumber()
	local cumulative = 0
	for _, mutation in ipairs(BrainrotCatalog.Mutations) do
		cumulative += mutation.Chance
		if roll <= cumulative then
			return mutation
		end
	end
	return BrainrotCatalog.Mutations[1]
end

-- The display name the HUD and name tags show: mutation first when it matters.
function BrainrotCatalog.DisplayName(entry, mutationName)
	if mutationName == nil or mutationName == "Normal" then
		return entry.Name
	end
	return mutationName .. " " .. entry.Name
end

-- Effective dollars per second for one placed brainrot.
function BrainrotCatalog.EffectiveRate(entry, mutationName, rebirthMultiplier)
	local mutation = BrainrotCatalog.GetMutation(mutationName) or BrainrotCatalog.Mutations[1]
	return entry.Rate * mutation.Multiplier * rebirthMultiplier
end

return BrainrotCatalog
