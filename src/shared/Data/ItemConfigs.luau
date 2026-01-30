---[[Services]]---
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local UIS = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
-- local StarterPack = game:GetService("StarterPack")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

--[[Folders]]
--
local RSModules = RS.Modules

--[[Types]]
--
local Types = require(RSModules.Types)

local ItemConfigs: { [string]: Types.ItemConfig } =
	{ --TODO: add hotbar blacklists, basically, some items, like armour and weapons shouldn't be equipable to the hotbar and instead should be equipped via slotting it to the relavent armour slot
		["Chestplate"] = {
			Name = "Chestplate",
			IconId = "rbxassetid://155410456",
			Description = "This is some hard clothing",
			ItemType = "Armor",
			IsDroppable = true,
		},
		["Event Item"] = {
			Name = "Event Item",
			IconId = "rbxassetid://103082690044411",
			Description = "This is a special item",
			ItemType = "Special",
			IsDroppable = false,
		},
		["Health Potion"] = {
			Name = "Health Potion",
			IconId = "rbxassetid://16306040804",
			Description = "This is a great drink",
			ItemType = "Consumable",
			IsDroppable = true,
		},
		["Helmet"] = {
			Name = "Helmet",
			IconId = "rbxassetid://143865877",
			Description = "This is a nice helmet",
			ItemType = "Armour",
			IsDroppable = true,
		},
		["Leggings"] = {
			Name = "Leggings",
			IconId = "rbxassetid://950826829",
			Description = "These are some great pants",
			ItemType = "Armour",
			IsDroppable = true,
		},
		["Rock"] = {
			Name = "Rock",
			IconId = "rbxassetid://8425069718",
			Description = "This is a rock",
			ItemType = "Resource",
			IsDroppable = true,
		},
		["Coin"] = {
			Name = "Coin",
			IconId = "rbxassetid://6811754064",
			Description = "A shiny gold coin",
			ItemType = "Currency",
			IsDroppable = true,
		},
		["Sword"] = {
			Name = "Sword",
			IconId = "rbxassetid://534533607",
			Description = "A great sharp sword for stabbing",
			ItemType = "Weapon",
			IsDroppable = true,
			ItemStats = {
				Durability = 300,
				Sharpness = 10,
			},
		},
	}

for id, itemData in pairs(ItemConfigs) do -- this just gives us a way to get the itemId from inside of the ItemConfig table
	itemData.Id = id
end

print(ItemConfigs)

return ItemConfigs
