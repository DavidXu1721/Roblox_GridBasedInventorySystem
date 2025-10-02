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
-- local PlayerInventoriesFolder = RS.PlayerInventories

--[[Modules]]
--
local Janitor = require(RSModules.Janitor)
local Signal = require(RSModules.Signal)
local TableUtil = require(RSModules.TableUtil)
local InventoryUtil = require(RSModules.InventoryUtil)

--[[Types]]
--
local Types = require(RSModules.Types)

--[[Settings]]
--
local AUTOSAVE_TIME = 60 * 3

--[[Data]]
--
local ItemConfigData = require(RS.Data.ItemConfigs)
local StarterItems: { string: number } = {
	["Chestplate"] = 1,
	["Rock"] = 60,
	["Sword"] = 12,
	["Health Potion"] = 14,
	["Event Item"] = 4,
}

---------------------------------------------------------------------------------
--TODO: Rework the code so that registering and unregistering items can take arrays, nah forget it.

local InventoryServer: {
	AllInventories: {
		[Player]: {
			NextVersionNumber: number,
			InventoryVersions: {
				VersionNumber: number,
				InventoryData: Types.Inventory,
				LastUpdate: Types.InventoryUpdateInfo,
			},
		},
	},
} =
	{}

InventoryServer.AllInventories = {}
InventoryServer.Janitors = {}

-- [[Functions]] --
function GetTargetSlotInfo(plr: Player, slotPos: Types.GridPosition | { x: number, y: number })
	-- I am thinking of doing a check to see if the slotPos is actually in bounds, but probably not necessary
	return InventoryServer.AllInventories[plr].Grid[slotPos.y][slotPos.x]
end

-- Player Added
function InventoryServer.OnPlayerAdded(plr: Player)
	print(plr.Name .. " joined!")

	-- Creating janitor object
	local janitor = Janitor.new()
	InventoryServer.Janitors[plr] = janitor
	janitor:GiveChore(function()
		InventoryServer.Janitors[plr] = nil
	end)

	--Creating Inventory
	local inv: Types.Inventory = { --NOTE: the first row is a hotbar, No need for a slot to hotbar function
		Grid = {},
		Armor = {},
	}

	for i = 1, InventoryUtil.GRID_DIMENSIONS.y do
		local invRow = {}
		inv.Grid[i] = invRow
		for j = 1, InventoryUtil.GRID_DIMENSIONS.x do
			invRow[j] = nil
		end
	end

	InventoryServer.AllInventories[plr] = inv
	print(inv)
	janitor:GiveChore(function()
		InventoryServer.AllInventories[plr] = nil
	end)

	local playerItems = table.clone(StarterItems) -- a shallow copy should be sufficient

	for itemId, count in pairs(playerItems) do
		if ItemConfigData[itemId].ItemStats then -- if the item has stats then we need to use a unique ID for the Item
			--print("item is unique")
			for i = 1, count do
				local newItem: Types.UniqueItemData = {
					Id = itemId,
					UniqueId = HttpService:GenerateGUID(),
					ItemStats = TableUtil.Copy(ItemConfigData[itemId].ItemStats, true),
				}
				InventoryServer.RegisterItem(plr, { Item = newItem })
			end
		else -- the item is a generic type, (aka not distinguishable from others of the same itemId)
			InventoryServer.RegisterItem(plr, { Item = itemId, Count = count })
			-- InventoryServer.UnregisterItem(plr, itemId, count)
		end
	end

	print(inv)

	-- Waiting for character to load in the first time
	if not plr.Character then
		plr.CharacterAdded:Wait()
	end
	InventoryServer.LoadData(plr)

	-- Character Added
	local function charAdded(char: Model)
		print(char.Name .. " has spawned")

		InventoryServer.Add(plr, { Item = "Coin", Count = 30 }, InventoryUtil.GridPosition.new(4, 6))
		InventoryServer.Add(plr, { Item = "Coin", Count = 30 }, InventoryUtil.GridPosition.new(4, 6))
		InventoryServer.Add(plr, { Item = "Coin", Count = 30 }, InventoryUtil.GridPosition.new(4, 6))
		InventoryServer.Add(plr, { Item = "Coin", Count = 30 }, InventoryUtil.GridPosition.new(4, 6))
		InventoryServer.Add(plr, { Item = "Coin", Count = 30 }, InventoryUtil.GridPosition.new(4, 6))

		--while true do
		--	InventoryServer.Swap(plr, InventoryUtil.GridPosition.new(4,6), InventoryUtil.GridPosition.new(5,7))
		--	task.wait(1)
		--end

		--task.wait(4)

		--while true do
		--	if InventoryServer.Add(plr, {Item= 'Coin', Count=30}) then
		--		break
		--	end
		--	task.wait(1)
		--end

		--task.wait(4)

		--while true do
		--	InventoryServer.Remove(plr, {Item= 'Coin', Count=10})

		--	task.wait(0.5)
		--end
	end

	-- Connecting character added
	task.spawn(charAdded, plr.Character)
	-- whenever a player leaves the game, the Player object isn't fully destroyed, thus connected events must be
	-- disconnected to avoid a memory leak
	janitor:GiveChore(plr.CharacterAdded:Connect(charAdded))
	-- TODO: add code to disconnect the this when the player leaves
end

-- Player Removing
function InventoryServer.OnPlayerRemoving(plr: Player)
	print(plr.Name .. " left the game")

	-- Clearing extra data & saving
	InventoryServer.SaveData(plr)
	InventoryServer.Janitors[plr]:Clean()
end

--Registering new items
function InventoryServer.RegisterItem(
	plr: Player,
	itemToRegister: Types.StackData?,
	targetGridPos: Types.GridPosition?
): { Item: string, Count: number } | { Item: Types.UniqueItemData } | nil
	return InventoryUtil.RegisterItem(InventoryServer.AllInventories[plr], itemToRegister, targetGridPos)
end

--Unregistering items
function InventoryServer.UnregisterItem(
	plr: Player,
	itemToUnregister: Types.StackData | { Item: string }?,
	targetGridPos: Types.GridPosition?
): { Item: string, Count: number } | { Item: Types.UniqueItemData } | nil
	return InventoryUtil.UnregisterItem(InventoryServer.AllInventories[plr], itemToUnregister, targetGridPos)
end

-- Move Item Slots within the inventory grid
function InventoryServer.Move(plr: Player, startPos: Types.GridPosition, endPos: Types.GridPosition, moveCount: number?)
	if not InventoryServer.AllInventories[plr] then
		warn(plr.Name .. "'s inventory does not exist")
		return
	end

	local stackData = GetTargetSlotInfo(plr, startPos)
	if not stackData then
		warn("Slot" .. tostring(startPos) .. " is empty")
		return
	end
	-- print(stackData)

	local stackCount = if typeof(stackData.Item) == "string" then stackData.Count else 1

	moveCount = moveCount or (stackCount or 1)

	-- if the movecount is 0 then we must stop because it will try to to move unique items, as they don't look at count
	if moveCount <= 0 then
		return
	end

	if moveCount > stackCount then
		warn("there are not enough items for there to move, moving what is there")
		moveCount = stackCount
	end

	-- process the register/unregistering
	local itemsToMove = InventoryServer.UnregisterItem(
		plr,
		{ Count = if typeof(stackData.Item) == "string" then moveCount else nil, Item = stackData.Item },
		startPos
	)

	local overflowItems = InventoryServer.RegisterItem(
		plr, -- we unregister the items from the start slot, try to register them into the end slot
		itemsToMove,
		endPos
	)

	InventoryServer.RegisterItem(plr, overflowItems, startPos)
	-- do some checks to detect if either not all the items could be moved, or if nothing was moved at all
	if overflowItems then
		if TableUtil.DeepEqual(overflowItems, itemsToMove) then
			warn("none of the items can be moved, so nothing actually changed")
			return
		else
			warn("only some of the items could be moved, adjusting moveCount")
			moveCount -= overflowItems.Count or 1 -- adjust the moveCount so it reflects the number of items that actually got moved
		end
	end

	Signal.FireClient(
		plr,
		"InventoryClient:Update",
		InventoryServer.GetInventoryData(plr),
		{ Type = "Move", startPos = startPos, endPos = endPos, moveCount = moveCount }
	)
end

-- Swap Item Slots within the inventory grid
function InventoryServer.Swap(plr: Player, APos: Types.GridPosition, BPos: Types.GridPosition)
	if not InventoryServer.AllInventories[plr] then
		warn(plr.Name .. "'s inventory does not exist")
		return
	end

	local ASlot = InventoryServer.UnregisterItem(plr, GetTargetSlotInfo(plr, APos), APos)
	local BSlot = InventoryServer.UnregisterItem(plr, GetTargetSlotInfo(plr, BPos), BPos)
	InventoryServer.RegisterItem(plr, ASlot, BPos)
	InventoryServer.RegisterItem(plr, BSlot, APos)

	if ASlot == nil and BSlot == nil then
		warn("both slots are empty, no nothing happened")
		return
	end

	Signal.FireClient(
		plr,
		"InventoryClient:Update",
		InventoryServer.GetInventoryData(plr),
		{ Type = "Swap", APos = APos, BPos = BPos }
	)
end

-- Add item/s to the player's inventory
function InventoryServer.Add(plr: Player, itemsToAdd: Types.StackData?, targetGridPos: Types.GridPosition?)
	if not InventoryServer.AllInventories[plr] then
		warn(plr.Name .. "'s inventory does not exist")
		return
	end

	if not itemsToAdd then
		return
	end

	local overflowItems = InventoryServer.RegisterItem(plr, itemsToAdd, targetGridPos)

	if overflowItems then
		if TableUtil.DeepEqual(overflowItems, itemsToAdd) then
			warn("couldn't add any of the items so nothing happened")
			return overflowItems
		else
			if typeof(overflowItems.Item) == "table" then
				error("if there are overflowItems that don't match the itemsToAdd then they can't be a unique item")
			end
			-- we are confident that we are dealing with a generic item
			itemsToAdd.Count -= overflowItems.Count
		end
	end

	Signal.FireClient(
		plr,
		"InventoryClient:Update",
		InventoryServer.GetInventoryData(plr),
		{ Type = "Add", itemsToAdd = itemsToAdd, targetGridPos = targetGridPos }
	)

	return overflowItems
end

-- Remove item/s from the player's inventory
function InventoryServer.Remove(plr: Player, itemsToRemove: Types.StackData?, targetGridPos: Types.GridPosition?)
	if not InventoryServer.AllInventories[plr] then
		warn(plr.Name .. "'s inventory does not exist")
		return
	end

	if not itemsToRemove then
		return
	end

	-- NOTE: here we actually need to make sure that the inventory that we are removing from actually has the the items. This will ERROR if there are not enough items present
	local removedItems = InventoryServer.UnregisterItem(plr, itemsToRemove, targetGridPos)

	Signal.FireClient(
		plr,
		"InventoryClient:Update",
		InventoryServer.GetInventoryData(plr),
		{ Type = "Remove", itemsToRemove = itemsToRemove, targetGridPos = targetGridPos }
	)

	return removedItems
end

--Getting inventory data
function InventoryServer.GetInventoryData(plr: Player)
	-- Waiting for inventory
	while not InventoryServer.AllInventories[plr] do
		print("waiting for " .. plr.Name .. "'s inventory.")
		task.wait()
	end
	return HttpService:JSONEncode(InventoryServer.AllInventories[plr])
end

--Handle inventory updates from players
function InventoryServer.HandleUpdate(plr: Player)
	-- TODO: add the code for it (lord help me)
end

--Saving data
function InventoryServer.SaveData(plr: Player)
	warn("Saving has not been set up yet.")
end

-- Loading data
function InventoryServer.LoadData(plr: Player)
	warn("Loading has not been set up yet.")
end

-- Initializing
function InventoryServer.Start()
	-- Player Added
	for i, plr in pairs(Players:GetPlayers()) do
		task.spawn(InventoryServer.OnPlayerAdded, plr)
	end
	Players.PlayerAdded:Connect(InventoryServer.OnPlayerAdded)

	-- Player Removing
	Players.PlayerRemoving:Connect(InventoryServer.OnPlayerRemoving)

	-- Signal Events
	Signal.ListenRemote("InventoryServer:GetInventoryJSON", InventoryServer.GetInventoryData)
	Signal.ListenRemote("InventoryServer:InventoryUpdate", InventoryServer.HandleUpdate)

	-- Game shutdown
	game:BindToClose(function()
		for i, plr: Player in pairs(Players:GetPlayers()) do
			InventoryServer.SaveData(plr)
		end
	end)

	-- Auto-saving
	task.spawn(function()
		while true do
			for i, player: Player in pairs(Players:GetPlayers()) do
				task.wait(AUTOSAVE_TIME / #Players:GetPlayers())
				InventoryServer.SaveData(player)
			end
			task.wait()
		end
	end)
end

return InventoryServer
