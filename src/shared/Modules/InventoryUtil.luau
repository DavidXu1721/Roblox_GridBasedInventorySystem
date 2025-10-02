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

--[[Folders]]--
local RSModules = RS.Modules

--[[Modules]]--
local TableUtil = require(RSModules.TableUtil)

--[[Types]]--
local Types = require(RSModules.Types)

--[[Data]]--
local ItemConfigData = require(RS.Data.ItemConfigs)

------------------------------------------------------

local InventoryUtil = {}

--// GridPosition object
local GridPosition = {}
GridPosition.__index = GridPosition

function GridPosition.new(x: number, y: number): Types.GridPosition
	assert(x and y)
	
	return setmetatable({
		x = x,
		y = y,
	}, GridPosition)
end

function GridPosition.__eq(a, b)
	
	if getmetatable(a) ~= GridPosition or getmetatable(b) ~= GridPosition then
		error("ERROR: can only compare GridPositions")
	end
	
	-- I don't actually think the code above is necessary given the documentation
	return a.x == b.x and a.y == b.y
end

function GridPosition.__tostring(self)
	return `{self.y}_{self.x}`
end

-- Export GridPosition constructor through InventoryUtil
InventoryUtil.GridPosition = GridPosition

InventoryUtil.MaxStackData = { -- This lists the maximum number of each kind of item that can be present in one stack
	Weapon = 1;
	Armor = 1;
	Consumable = 5;
	Resource = 10;
	Currency = 200;
	Special = 1;
}
InventoryUtil.GRID_DIMENSIONS = GridPosition.new(10, 10)

-- Registers the given item to the invData table, if a targetGridPos was specified, then it will only try to register items to that slot, returns any items it was unable to register
function InventoryUtil.RegisterItem( 
	invData : Types.Inventory,
	itemToRegister: Types.StackData?,
	targetGridPos: Types.GridPosition?
) : {Item: string, Count: number} | {Item: Types.UniqueItemData}| nil
	-- IMPORTANT: In order for some of the code in inventory server to work, itemToRegister can't be mutated
	if not invData then error("ERROR: invData not present!") end
	
	if not itemToRegister then -- if itemToRegister is nil, for example when moving a slot that is empty
		return
	end
	-- print("register item print")
	-- print(itemToRegister)
	local _incomingItem = itemToRegister.Item
	local registerCount = itemToRegister.Count or 1;
	
	-- if we somehow ended up trying to register 0 of something then we can immediately abort this and not cause stuff where we end up with a stack with a count of 0
	if registerCount <= 0 then warn("the starting registerCount shouldn't be 0, stopping register") end

	-- Checks
	if typeof(_incomingItem) == string and not ItemConfigData[_incomingItem] then
		error("Invalid itemId")
	elseif typeof(_incomingItem) == string and ItemConfigData[_incomingItem].ItemStats then
		error("Items with an itemId of " .. _incomingItem .. " have itemStats and must be specified as a uniqueItem with a unique Id")
	elseif _incomingItem.UniqueId and not ItemConfigData[_incomingItem.Id].ItemStats then
		error("Generic Items (those without a stats) can't be a unique item.")
	elseif typeof(_incomingItem) == "table" and (not _incomingItem.UniqueId or not _incomingItem.ItemStats) then
		print(_incomingItem)
		error("_incomingItem must either be a string or be a unique item table")
	end


	local isItemGeneric
	local maxStackLimit

	if typeof(_incomingItem) == "string" then
		isItemGeneric = true
		maxStackLimit = InventoryUtil.MaxStackData[ItemConfigData[_incomingItem].ItemType]
	elseif registerCount == 1 then
		isItemGeneric = false
	else -- this means that we are trying to register multiples of the same unique item, that can't happen
		error("Cannot register multiples of a unique item")
	end

	-- we iterate over every grid slot to look for a space to put the item into 
	for i, gridRow in ipairs(invData.Grid) do

		for j = 1, InventoryUtil.GRID_DIMENSIONS.x do
			
			local currentGridPos = GridPosition.new(j, i)

			-- if we specified a targetGridPos we must check if the grid space is the targetPosition, I know this is kinda inefficient, but this should be find for now and I don't want to fiddle with making this code an internal function
			if targetGridPos and targetGridPos ~= currentGridPos then
				continue
			end

			local numberRegistered

			if gridRow[j] == nil then -- if the slot is empty, then we can slot the items in

				if isItemGeneric then -- generic item case
					numberRegistered = math.min(maxStackLimit, registerCount)
					gridRow[j] = {Item = _incomingItem, Count = numberRegistered}
				else -- Unique item case
					numberRegistered = 1
					gridRow[j] = {Item = _incomingItem}
				end

				registerCount -= numberRegistered

			elseif typeof(gridRow[j].Item) == "string" and isItemGeneric then  -- Items whose Id are a string are stackable, so they need to be considered

				if gridRow[j].Item == _incomingItem and 
					gridRow[j].Count < maxStackLimit then
					-- the stack contains the same item and there is still space for more items
					numberRegistered = math.min(maxStackLimit - gridRow[j].Count, registerCount)
					gridRow[j].Count += numberRegistered
					registerCount -= numberRegistered
				end

			elseif gridRow[j].Item.UniqueId == _incomingItem.UniqueId then
				error("Duplicate Item ID somehow")	
			end

			assert(registerCount >= 0, "registerCount somehow became negative")
			if registerCount == 0 then
				-- print("DONE")
				return
			end

			if targetGridPos and targetGridPos == currentGridPos then
				--TODO: Add more code to handle this case and fix the repitition
				if isItemGeneric then -- for now, return the item/s that could not be registered
					return {Item= _incomingItem, Count= registerCount}
				else
					return {Item= _incomingItem}
				end
			end
		end
	end

	if isItemGeneric then -- for now, return the item/s that could not be registered
		return {Item= _incomingItem, Count= registerCount}
	else
		return {Item= _incomingItem}
	end	
end

-- Unregisters the given item from the invData table, if a targetGridPos was specified, then it will only try to unregister items from that slot, returns any items it unregistered
function InventoryUtil.UnregisterItem(
	invData: Types.Inventory,
	itemToUnregister: Types.StackData | {Item: string}?,
	targetGridPos: Types.GridPosition?
) : {Item: string, Count: number} | {Item: Types.UniqueItemData}| nil
	
	-- IMPORTANT: In order for some of the code in inventory server to work, itemToUnregister can't be mutated
	if not invData then error("ERROR: invData not present!") end
	
	if not itemToUnregister then -- if itemToRegister is nil, for example when moving a slot that is empty
		return
	end
	-- here the itemToUnregister can be the a generic ItemId,
	-- print(itemToUnregister)
	local _targetItem = itemToUnregister.Item
	local unregisterCount = itemToUnregister.Count or 1
	
	-- if we somehow ended up trying to register 0 of something then we can immediately abort this and not cause stuff where we end up with a stack with a count of 0
	if unregisterCount <= 0 then warn("the starting unregisterCount shouldn't be 0, stopping unregister") end

	-- Checks
	if typeof(_targetItem) == string and ItemConfigData[_targetItem] and ItemConfigData[_targetItem].ItemStats then
		error("Items with an itemId of " .. _targetItem .. " have itemStats and must be specified as a unique Item table or with a uniqueId")
	elseif _targetItem.UniqueId and not ItemConfigData[_targetItem.Id].ItemStats then
		error("Generic Items (those without a stats) can't be a unique item.")
	end

	-- Now we have ensured that the _targetItem is either an itemIdstring for a generic item, a uniqueItemTable (it will be a memory address and so can work as an identifier) or a uniqueId string

	local isItemGeneric
	local outputItems = nil -- this is variable to output any items we unregister

	if typeof(_targetItem) == "string" and ItemConfigData[_targetItem] then -- the item is a generic type
		isItemGeneric = true
	elseif unregisterCount == 1 then
		isItemGeneric = false -- I think we've done enough checks to to ensure that this is either a uniqueId string or an unique item table 
	else -- this means that we are trying to unregister multiples of the same unique item, that can't happen
		error("Cannot unregister multiples of a unique item")
	end

	-- we iterate over every grid slot in REVERSE to look for the first space that matches the item or itemId/UniqueId
	for i, gridRow in ipairs(TableUtil.Reverse(invData.Grid)) do

		for j = InventoryUtil.GRID_DIMENSIONS.x, 1, -1 do
			
			local currentGridPos = GridPosition.new(j, InventoryUtil.GRID_DIMENSIONS.y + 1 - i)

			-- as above if we specified a targetGridPos we must check if the grid space is the targetPosition
			if targetGridPos and targetGridPos ~= currentGridPos then
				continue
			end

			if targetGridPos then
				-- warn("PASS (unregister)")
			end

			if gridRow[j] == nil then
				continue
			elseif isItemGeneric and typeof(gridRow[j].Item) == 'string' and gridRow[j].Item == _targetItem then
				-- add code to unregister generic items
				local numberUnregistered

				numberUnregistered = math.min(gridRow[j].Count, unregisterCount)
				gridRow[j] = {Item = _targetItem, Count = gridRow[j].Count - numberUnregistered}
				unregisterCount -= numberUnregistered

				-- add this to the output items
				if outputItems == nil then
					outputItems = {Item = _targetItem, Count = 0}
				end

				outputItems.Count += numberUnregistered

				-- check if the stack is empty, and if so remove it
				assert(gridRow[j].Count >= 0, "itemCount at".. InventoryUtil.GRID_DIMENSIONS.y - i + 1, j.. "somehow became negative")
				if gridRow[j].Count == 0 then
					gridRow[j] = nil
				end

			elseif not isItemGeneric and typeof(_targetItem) == 'string' and gridRow[j].Item.UniqueId == _targetItem then
				-- add code to unregister unique item based on the Unique Id
				outputItems = {Item= gridRow[j].Item}
				gridRow[j] = nil
				unregisterCount -= 1

			elseif not isItemGeneric and typeof(_targetItem) == 'table' and gridRow[j].Item == _targetItem then
				-- add code to unregister unique item based on the memory address
				-- NOTE: this code is actually the same as the stuff above, but I figured that I might as well do this just to make things clear
				outputItems = {Item= gridRow[j].Item}
				gridRow[j] = nil
				unregisterCount -= 1

			end

			assert(unregisterCount >= 0, "unregisterCount somehow became negative")
			if unregisterCount == 0 then
				-- print("DONE")
				return outputItems
			end

			if targetGridPos and targetGridPos == currentGridPos then
				--TODO: Add more code to handle this case and fix the repetition
				warn("Can't find all items to unregister!")
				warn(_targetItem)
				error("Code for this not implemented yet.") -- TODO: Add code to handle this
			end

		end
	end

	warn("Can't find all items to unregister!")
	warn(_targetItem)
	error("Code for this not implemented yet.") -- TODO: Add code to handle this
end


return InventoryUtil
