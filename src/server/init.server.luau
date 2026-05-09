---[[Services]]--
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

--[[Folders]]
--
local RSModules = RS.Modules

--[[Modules]]
--

--[[Variables]]
--

-- Requiring Inventory Module
local TableUtil = require(ReplicatedStorage.Modules.TableUtil)
local InventoryServer = require(script.InventoryServer)

-- Starting Inventory Module
InventoryServer.Start()

--TODO: write some ACTUAL tests with automatic validation.

local function PlayerAdded(plr: Player)
	-- Character Added
	local function charAdded(char: Model)
		warn("Initiating income")

		local hum: Humanoid = char:WaitForChild("Humanoid") :: Humanoid
		local isAlive = true

		hum.Died:Once(function()
			isAlive = false
			warn("Halting income")
		end)

		while isAlive do
			InventoryServer.Add(plr, { Item = "Coin", Count = 1 })
			task.wait(2)
		end
	end

	-- Waiting for character to load in the first time
	if not plr.Character then
		plr.CharacterAdded:Wait()
	end

	-- Connecting character added
	task.spawn(charAdded, plr.Character :: Model)
	-- whenever a player leaves the game, the Player object isn't fully destroyed, thus connected events must be disconnected to avoid a memory leak
	InventoryServer.Janitors[plr]:GiveChore(plr.CharacterAdded:Connect(charAdded))
	-- TODO: add code to disconnect the this when the player leaves
end

-- Player Added
for i, plr in pairs(Players:GetPlayers()) do
	task.spawn(PlayerAdded, plr)
end

Players.PlayerAdded:Connect(PlayerAdded)

warn(typeof(InventoryServer.GridPosition.new(1, 0)) == typeof(InventoryServer))

-- TESTING SECTION
if InventoryServer.IsTesting() then
	InventoryServer.OnPlayerAdded("TEST_PLAYER")

	assert(
		TableUtil.DeepEqual(InventoryServer.AllInventories.TEST_PLAYER, {
			Armor = {},
			Grid = {
				{
					[1] = { Count = 10, Item = "Rock" },
					[2] = { Count = 10, Item = "Rock" },
					[3] = { Count = 10, Item = "Rock" },
					[4] = { Count = 10, Item = "Rock" },
					[5] = { Count = 10, Item = "Rock" },
					[6] = { Count = 10, Item = "Rock" },
					[7] = { Count = 1, Item = "Event Item" },
					[8] = { Count = 1, Item = "Event Item" },
					[9] = { Count = 1, Item = "Event Item" },
					[10] = { Count = 1, Item = "Event Item" },
				},
				{
					[1] = { Item = { Id = "Sword", ItemStats = { Durability = 300, Sharpness = 10 }, UniqueId = 1 } },
					[2] = { Item = { Id = "Sword", ItemStats = { Durability = 300, Sharpness = 10 }, UniqueId = 2 } },
					[3] = { Item = { Id = "Sword", ItemStats = { Durability = 300, Sharpness = 10 }, UniqueId = 3 } },
					[4] = { Item = { Id = "Sword", ItemStats = { Durability = 300, Sharpness = 10 }, UniqueId = 4 } },
					[5] = { Item = { Id = "Sword", ItemStats = { Durability = 300, Sharpness = 10 }, UniqueId = 5 } },
					[6] = { Item = { Id = "Sword", ItemStats = { Durability = 300, Sharpness = 10 }, UniqueId = 6 } },
					[7] = { Item = { Id = "Sword", ItemStats = { Durability = 300, Sharpness = 10 }, UniqueId = 7 } },
					[8] = { Item = { Id = "Sword", ItemStats = { Durability = 300, Sharpness = 10 }, UniqueId = 8 } },
					[9] = { Item = { Id = "Sword", ItemStats = { Durability = 300, Sharpness = 10 }, UniqueId = 9 } },
					[10] = { Item = { Id = "Sword", ItemStats = { Durability = 300, Sharpness = 10 }, UniqueId = 10 } },
				},
				{
					[1] = { Item = { Id = "Sword", ItemStats = { Durability = 300, Sharpness = 10 }, UniqueId = 11 } },
					[2] = { Item = { Id = "Sword", ItemStats = { Durability = 300, Sharpness = 10 }, UniqueId = 12 } },
					[3] = { Count = 1, Item = "Chestplate" },
					[4] = { Count = 5, Item = "Health Potion" },
					[5] = { Count = 5, Item = "Health Potion" },
					[6] = { Count = 4, Item = "Health Potion" },
				},
				{},
				{},
				{},
				{},
				{},
				{},
				{},
			},
		}),
		"TEST FAILED: Initial inventory didn't match"
	)

	for i = 1, 10 do
		InventoryServer.UpdateInv("TEST_PLAYER", {
			Type = "Move",
			Data = {
				startPos = InventoryServer.GridPosition.new(1, 1),
				endPos = InventoryServer.GridPosition.new(1, 4),
				moveCount = 1,
			},
		})

		assert(
			TableUtil.DeepEqual(InventoryServer.AllInventories.TEST_PLAYER, {
				Armor = {},
				Grid = {
					{
						[1] = i < 10 and { Count = 10 - i, Item = "Rock" } or nil,
						[2] = { Count = 10, Item = "Rock" },
						[3] = { Count = 10, Item = "Rock" },
						[4] = { Count = 10, Item = "Rock" },
						[5] = { Count = 10, Item = "Rock" },
						[6] = { Count = 10, Item = "Rock" },
						[7] = { Count = 1, Item = "Event Item" },
						[8] = { Count = 1, Item = "Event Item" },
						[9] = { Count = 1, Item = "Event Item" },
						[10] = { Count = 1, Item = "Event Item" },
					},
					{
						[1] = {
							Item = { Id = "Sword", ItemStats = { Durability = 300, Sharpness = 10 }, UniqueId = 1 },
						},
						[2] = {
							Item = { Id = "Sword", ItemStats = { Durability = 300, Sharpness = 10 }, UniqueId = 2 },
						},
						[3] = {
							Item = { Id = "Sword", ItemStats = { Durability = 300, Sharpness = 10 }, UniqueId = 3 },
						},
						[4] = {
							Item = { Id = "Sword", ItemStats = { Durability = 300, Sharpness = 10 }, UniqueId = 4 },
						},
						[5] = {
							Item = { Id = "Sword", ItemStats = { Durability = 300, Sharpness = 10 }, UniqueId = 5 },
						},
						[6] = {
							Item = { Id = "Sword", ItemStats = { Durability = 300, Sharpness = 10 }, UniqueId = 6 },
						},
						[7] = {
							Item = { Id = "Sword", ItemStats = { Durability = 300, Sharpness = 10 }, UniqueId = 7 },
						},
						[8] = {
							Item = { Id = "Sword", ItemStats = { Durability = 300, Sharpness = 10 }, UniqueId = 8 },
						},
						[9] = {
							Item = { Id = "Sword", ItemStats = { Durability = 300, Sharpness = 10 }, UniqueId = 9 },
						},
						[10] = {
							Item = { Id = "Sword", ItemStats = { Durability = 300, Sharpness = 10 }, UniqueId = 10 },
						},
					},
					{
						[1] = {
							Item = { Id = "Sword", ItemStats = { Durability = 300, Sharpness = 10 }, UniqueId = 11 },
						},
						[2] = {
							Item = { Id = "Sword", ItemStats = { Durability = 300, Sharpness = 10 }, UniqueId = 12 },
						},
						[3] = { Count = 1, Item = "Chestplate" },
						[4] = { Count = 5, Item = "Health Potion" },
						[5] = { Count = 5, Item = "Health Potion" },
						[6] = { Count = 4, Item = "Health Potion" },
					},
					{
						[1] = { Count = i, Item = "Rock" },
					},
					{},
					{},
					{},
					{},
					{},
					{},
				},
			}),
			string.format("TEST FAILED: Inventory didn't match after move %d", i)
		)
	end

	-- TODO: add more tests

	print("TESTS PASSED")
end
