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
local IS_TESTING = true

--[[Data]]
--
local ItemConfigData = require(RS.Data.ItemConfigs)
local StarterItems: { [string]: number } = {
	["Chestplate"] = 1,
	["Rock"] = 60,
	["Sword"] = 12,
	["Health Potion"] = 14,
	["Event Item"] = 4,
}

--[[For Testing]]
--
local testId = 0
local function getNewItemId()
	if IS_TESTING then
		testId += 1
		return testId
	else
		return HttpService:GenerateGUID()
	end
end
local counter = 0

---------------------------------------------------------------------------------
--TODO: Rework the code so that registering and unregistering items can take arrays, nah forget it.

local InventoryServer: InventoryServerType = {
	AllInventories = {},
	Janitors = {},
	GridPosition = InventoryUtil.GridPosition,
}

-- Player Added
function InventoryServer.OnPlayerAdded(plr: Player | string)
	print((plr :: Player).Name or plr :: string .. " joined!")

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

	print(inv)
	janitor:GiveChore(function()
		InventoryServer.AllInventories[plr] = nil
	end)

	--Add the starter items
	local playerItems = table.clone(StarterItems) -- a shallow copy should be sufficient

	for itemId, count in pairs(playerItems) do
		if ItemConfigData[itemId].ItemStats then -- if the item has stats then we need to use a unique ID for the Item
			--print("item is unique")
			for i = 1, count do
				local newItem: Types.UniqueItemData = {
					Id = itemId,
					UniqueId = getNewItemId(),
					ItemStats = TableUtil.Copy(ItemConfigData[itemId].ItemStats, true),
				}
				InventoryUtil.RegisterItem(inv, { Item = newItem })
			end
		else -- the item is a generic type, (aka not distinguishable from others of the same itemId)
			InventoryUtil.RegisterItem(inv, { Item = itemId, Count = count })
			-- InventoryUtil.UnregisterItem(InventoryServer.AllInventories[plr].InvData, itemId, count)
		end
	end

	print(inv)

	InventoryServer.AllInventories[plr] = {
		InvData = inv,
		PendingUpdates = {},
		RollbackInv = inv,
	}

	if typeof(plr) ~= "string" and not plr.Character then
		plr.CharacterAdded:Wait()
	end
	InventoryServer.LoadData(plr)
end

-- Player Removing
function InventoryServer.OnPlayerRemoving(plr: Player)
	print(plr.Name .. " left the game")

	-- Clearing extra data & saving
	InventoryServer.SaveData(plr)
	InventoryServer.Janitors[plr]:Clean()
end

-- Move Item Slots within the inventory grid
function InventoryServer.Move(plr: Player | string, payload: Types.InventoryMoveData): Types.InventoryMoveData?
	local invUtilCoro = coroutine.create(InventoryUtil.MoveSlot)

	local success, result = coroutine.resume(
		invUtilCoro,
		InventoryServer.AllInventories[plr].InvData,
		payload.startPos,
		payload.endPos,
		payload.moveCount
	)

	while success and result[1] == 0 and coroutine.status(invUtilCoro) ~= "dead" do
		print(result[2])
		success, result = coroutine.resume(invUtilCoro)
	end

	if success and result[1] == 1 then
		if result[2] == "InvData not given" then
			warn((plr :: Player).Name or plr :: string .. "'s inventory does not exist")
			return
		elseif result[2] == "Slot is empty" then
			warn("Slot" .. tostring(payload.startPos) .. " is empty")
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
	return { startPos = payload.startPos, endPos = payload.endPos, moveCount = result[3] }
end

-- Swap Item Slots within the inventory grid
function InventoryServer.Swap(plr: Player | string, payload: Types.InventorySwapData): Types.InventorySwapData?
	local invUtilCoro = coroutine.create(InventoryUtil.SwapSlot)

	local success, result =
		coroutine.resume(invUtilCoro, InventoryServer.AllInventories[plr].InvData, payload.APos, payload.BPos)

	while success and result[1] == 0 and coroutine.status(invUtilCoro) ~= "dead" do
		print(result[2])
		success, result = coroutine.resume(invUtilCoro)
	end

	if success and result[1] == 1 then
		if result[2] == "InvData not given" then
			warn((plr :: Player).Name or plr :: string .. "'s inventory does not exist")
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

	return { APos = payload.APos, BPos = payload.BPos }
end

-- Add item/s to the player's inventory
function InventoryServer.Add(
	plr: Player | string,
	payload: Types.InventoryAddData
): (Types.InventoryAddData?, Types.StackData?)
	local invUtilCoro = coroutine.create(InventoryUtil.AddItem)

	local success, result = coroutine.resume(
		invUtilCoro,
		InventoryServer.AllInventories[plr].InvData,
		payload.itemsToAdd,
		payload.targetGridPos
	)

	while success and result[1] == 0 and coroutine.status(invUtilCoro) ~= "dead" do
		-- print(result[2])
		success, result = coroutine.resume(invUtilCoro)
	end

	if success and result[1] == 1 then
		if result[2] == "InvData not given" then
			warn((plr :: Player).Name or plr :: string .. "'s inventory does not exist")
			return
		elseif result[2] == "No items to add" then
			warn("Items to add parameter was no present")
			return
		else
			error("ERROR: Invalid result message -- " .. result[2])
		end
	elseif not success then
		error(result)
	end

	-- print(result[2])

	return { itemsToAdd = result[4], targetGridPos = payload.targetGridPos }, result[3]
end

-- Remove item/s from the player's inventory
function InventoryServer.Remove(
	plr: Player | string,
	payload: Types.InventoryRemoveData
): (Types.InventoryRemoveData?, Types.StackData?)
	local invUtilCoro = coroutine.create(InventoryUtil.RemoveItem)

	local success, result = coroutine.resume(
		invUtilCoro,
		InventoryServer.AllInventories[plr].InvData,
		payload.itemsToRemove,
		payload.targetGridPos
	)

	while success and result[1] == 0 and coroutine.status(invUtilCoro) ~= "dead" do
		--print(result[2])
		success, result = coroutine.resume(invUtilCoro)
	end

	if success and result[1] == 1 then
		if result[2] == "InvData not given" then
			warn((plr :: Player).Name or plr :: string .. "'s inventory does not exist")
			return
		elseif result[2] == "No items to remove" then
			warn("Items to remove parameter was no present")
			return
		else
			error("ERROR: Invalid result message -- " .. result[2])
		end
	elseif not success then
		error(result)
	end

	-- print(result[2])

	---------------------------------

	return payload, result[3]
end

-- General Update function
function InventoryServer.UpdateInv(plr: Player | string, updateInfo: Types.InventoryUpdateInfo?)
	-- use the update info to do any relevant changes
	if updateInfo then
		-- the Type needs to match the function name exactly (Case Sensitive)
		local payload: Types.InventoryMoveData | Types.InventorySwapData | Types.InventoryAddData | Types.InventoryRemoveData, output: Types.StackData? =
			InventoryServer[updateInfo.Type](plr, updateInfo.Data)

		if typeof(plr) ~= "string" then
			Signal.FireClient(
				plr,
				"InventoryClient:Update",
				InventoryServer.GetInventoryData(plr),
				{ Type = updateInfo.Type, Data = payload, counter = counter }
			)
		end

		return output
	end

	warn("UpdateInfo is not present, no update occured")

	return
end

--Getting inventory data
function InventoryServer.GetInventoryData(plr: Player | string)
	-- Waiting for inventory
	while not InventoryServer.AllInventories[plr] do
		print("waiting for " .. (plr :: Player).Name or plr :: string .. "'s inventory.")
		task.wait()
	end
	return HttpService:JSONEncode(InventoryServer.AllInventories[plr].InvData)
end

--Handle inventory updates from players
function InventoryServer.HandleUpdate(plr: Player | string)
	-- TODO: add the code for it (lord help me)
end

--Saving data
function InventoryServer.SaveData(plr: Player | string)
	warn("Saving has not been set up yet.")
end

-- Loading data
function InventoryServer.LoadData(plr: Player | string)
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
	Signal.ListenRemote("InventoryServer:GetInventoryJSON", function(plr)
		Signal.FireClient(plr, "InventoryClient:InvData", InventoryServer.GetInventoryData(plr))
		print("sent invdata")
	end)
	Signal.ListenRemote("InventoryServer:InventoryUpdate", InventoryServer.HandleUpdate)

	-- Game shutdown
	game:BindToClose(function()
		print("game closing")
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

-- Testing Purposes
function InventoryServer.IsTesting()
	return IS_TESTING
end

-- a bit weird that I would have to export the type for this, but at this point idc
export type InventoryServerType = typeof(InventoryServer)

return InventoryServer
