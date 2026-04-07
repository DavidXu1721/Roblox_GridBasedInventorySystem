--!nocheck

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
	Janitors: {
		[Player]: Janitor,
	},
	[string]: (...any) -> ...any,
} =
	{}

InventoryServer.AllInventories = {}
InventoryServer.Janitors = {}

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
				InventoryUtil.RegisterItem(InventoryServer.AllInventories[plr], { Item = newItem })
			end
		else -- the item is a generic type, (aka not distinguishable from others of the same itemId)
			InventoryUtil.RegisterItem(InventoryServer.AllInventories[plr], { Item = itemId, Count = count })
			-- InventoryUtil.UnregisterItem(InventoryServer.AllInventories[plr], itemId, count)
		end
	end

	print(inv)
end

-- Player Removing
function InventoryServer.OnPlayerRemoving(plr: Player)
	print(plr.Name .. " left the game")

	-- Clearing extra data & saving
	InventoryServer.SaveData(plr)
	InventoryServer.Janitors[plr]:Clean()
end

-- Move Item Slots within the inventory grid
function InventoryServer.Move(plr: Player, startPos: Types.GridPosition, endPos: Types.GridPosition, moveCount: number?)
	local invUtilCoro = coroutine.create(InventoryUtil.MoveSlot)

	local success, result =
		coroutine.resume(invUtilCoro, InventoryServer.AllInventories[plr], startPos, endPos, moveCount)

	while success and result[1] == 0 and coroutine.status(invUtilCoro) ~= "dead" do
		print(result[2])
		success, result = coroutine.resume(invUtilCoro)
	end

	if success and result[1] == 1 then
		if result[2] == "InvData not given" then
			warn(plr.Name .. "'s inventory does not exist")
			return
		elseif result[2] == "Slot is empty" then
			warn("Slot" .. tostring(startPos) .. " is empty")
			return
		elseif result[2] == "No items were moved" then
			warn("None of the items can be moved, so nothing actually changed")
			return
		else
			error("ERROR: Invalid result message -- " .. result[2])
		end
	elseif not success then
		error(result)
	end

	print(result[2])
	-- here result[3] holds the fixed movecount, because I can't really fine any better way to pass that information through

	Signal.FireClient(
		plr,
		"InventoryClient:Update",
		InventoryServer.GetInventoryData(plr),
		{ Type = "Move", Data = { startPos = startPos, endPos = endPos, moveCount = result[3] } }
	)
end

-- Swap Item Slots within the inventory grid
function InventoryServer.Swap(plr: Player, APos: Types.GridPosition, BPos: Types.GridPosition)
	local invUtilCoro = coroutine.create(InventoryUtil.SwapSlot)

	local success, result = coroutine.resume(invUtilCoro, InventoryServer.AllInventories[plr], APos, BPos)

	while success and result[1] == 0 and coroutine.status(invUtilCoro) ~= "dead" do
		print(result[2])
		success, result = coroutine.resume(invUtilCoro)
	end

	if success and result[1] == 1 then
		if result[2] == "InvData not given" then
			warn(plr.Name .. "'s inventory does not exist")
			return
		elseif result[2] == "Nothing happened" then
			warn("both slots are empty, no nothing happened")
			return
		else
			error("ERROR: Invalid result message -- " .. result[2])
		end
	elseif not success then
		error(result)
	end

	print(result[2])

	Signal.FireClient(
		plr,
		"InventoryClient:Update",
		InventoryServer.GetInventoryData(plr),
		{ Type = "Swap", Data = { APos = APos, BPos = BPos } }
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

	local overflowItems = InventoryUtil.RegisterItem(InventoryServer.AllInventories[plr], itemsToAdd, targetGridPos)

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
		{ Type = "Add", Data = { itemsToAdd = itemsToAdd, targetGridPos = targetGridPos } }
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
	local removedItems = InventoryUtil.UnregisterItem(InventoryServer.AllInventories[plr], itemsToRemove, targetGridPos)

	Signal.FireClient(
		plr,
		"InventoryClient:Update",
		InventoryServer.GetInventoryData(plr),
		{ Type = "Remove", Data = { itemsToRemove = itemsToRemove, targetGridPos = targetGridPos } }
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
