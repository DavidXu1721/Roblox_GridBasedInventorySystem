---[[Services]]--
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
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
local InventoryServer = require(script.InventoryServer)

-- Starting Inventory Module
InventoryServer.Start()

--TODO: write some ACTUAL tests with automatic validation.

function PlayerAdded(plr: Player)
	-- Character Added
	local function charAdded(char: Model)
		warn(char.Name .. " has spawned")
		--[[
		-- the following is just a bunch of test code

		-- testing moveing items back and forth, in particular triggering overflow
		task.spawn(function()
			InventoryServer.Add(plr, { Item = "Coin", Count = 30 }, InventoryServer.GridPosition.new(4, 6))
			InventoryServer.Add(plr, { Item = "Coin", Count = 30 }, InventoryServer.GridPosition.new(4, 6))
			InventoryServer.Add(plr, { Item = "Coin", Count = 30 }, InventoryServer.GridPosition.new(4, 6))
			InventoryServer.Add(plr, { Item = "Coin", Count = 30 }, InventoryServer.GridPosition.new(4, 6))
			InventoryServer.Add(plr, { Item = "Coin", Count = 30 }, InventoryServer.GridPosition.new(4, 6))

			InventoryServer.Add(plr, { Item = "Coin", Count = 30 }, InventoryServer.GridPosition.new(5, 7))
			InventoryServer.Add(plr, { Item = "Coin", Count = 30 }, InventoryServer.GridPosition.new(5, 7))
			InventoryServer.Add(plr, { Item = "Coin", Count = 30 }, InventoryServer.GridPosition.new(5, 7))
			InventoryServer.Add(plr, { Item = "Coin", Count = 30 }, InventoryServer.GridPosition.new(5, 7))

			while true do
				InventoryServer.Move(
					plr,
					InventoryServer.GridPosition.new(4, 6),
					InventoryServer.GridPosition.new(5, 7),
					200
				)
				task.wait(1)
				InventoryServer.Move(
					plr,
					InventoryServer.GridPosition.new(5, 7),
					InventoryServer.GridPosition.new(4, 6),
					40
				)
				task.wait(0.5)
				InventoryServer.Move(
					plr,
					InventoryServer.GridPosition.new(5, 7),
					InventoryServer.GridPosition.new(4, 6),
					40
				)
				task.wait(0.5)
				InventoryServer.Move(
					plr,
					InventoryServer.GridPosition.new(5, 7),
					InventoryServer.GridPosition.new(4, 6),
					40
				)
				task.wait(0.5)
				InventoryServer.Move(
					plr,
					InventoryServer.GridPosition.new(5, 7),
					InventoryServer.GridPosition.new(4, 6),
					40
				)
				task.wait(0.5)
				InventoryServer.Move(
					plr,
					InventoryServer.GridPosition.new(5, 7),
					InventoryServer.GridPosition.new(4, 6),
					40
				)
				task.wait(0.5)
				InventoryServer.Move(
					plr,
					InventoryServer.GridPosition.new(5, 7),
					InventoryServer.GridPosition.new(4, 6),
					40
				)
				task.wait(0.5)
				InventoryServer.Move(
					plr,
					InventoryServer.GridPosition.new(5, 7),
					InventoryServer.GridPosition.new(4, 6),
					40
				)
				task.wait(0.5)
				InventoryServer.Move(
					plr,
					InventoryServer.GridPosition.new(5, 7),
					InventoryServer.GridPosition.new(4, 6),
					40
				)
				task.wait(0.5)
			end
		end)
        ]]
		task.wait(1)

		-- testing moveing items back and forth, in particular triggering overflow
		task.spawn(function()
			InventoryServer.Add(plr, { Item = "Coin", Count = 30 }, InventoryServer.GridPosition.new(4, 6))
			InventoryServer.Add(plr, { Item = "Coin", Count = 30 }, InventoryServer.GridPosition.new(4, 6))
			InventoryServer.Add(plr, { Item = "Coin", Count = 30 }, InventoryServer.GridPosition.new(4, 6))
			InventoryServer.Add(plr, { Item = "Coin", Count = 30 }, InventoryServer.GridPosition.new(4, 6))
			InventoryServer.Add(plr, { Item = "Coin", Count = 30 }, InventoryServer.GridPosition.new(4, 6))

			InventoryServer.Add(plr, { Item = "Coin", Count = 30 }, InventoryServer.GridPosition.new(5, 7))
			InventoryServer.Add(plr, { Item = "Coin", Count = 30 }, InventoryServer.GridPosition.new(5, 7))
			InventoryServer.Add(plr, { Item = "Coin", Count = 30 }, InventoryServer.GridPosition.new(5, 7))
			InventoryServer.Add(plr, { Item = "Coin", Count = 30 }, InventoryServer.GridPosition.new(5, 7))

			while true do
				InventoryServer.Move(
					plr,
					InventoryServer.GridPosition.new(4, 6),
					InventoryServer.GridPosition.new(5, 7),
					200
				)
				task.wait(1)
				InventoryServer.Move(
					plr,
					InventoryServer.GridPosition.new(5, 7),
					InventoryServer.GridPosition.new(4, 6),
					40
				)
				task.wait(0.5)
				InventoryServer.Move(
					plr,
					InventoryServer.GridPosition.new(5, 7),
					InventoryServer.GridPosition.new(4, 6),
					40
				)
				task.wait(0.5)
				InventoryServer.Move(
					plr,
					InventoryServer.GridPosition.new(5, 7),
					InventoryServer.GridPosition.new(4, 6),
					40
				)
				task.wait(0.5)
				InventoryServer.Move(
					plr,
					InventoryServer.GridPosition.new(5, 7),
					InventoryServer.GridPosition.new(4, 6),
					40
				)
				task.wait(0.5)
				InventoryServer.Move(
					plr,
					InventoryServer.GridPosition.new(5, 7),
					InventoryServer.GridPosition.new(4, 6),
					40
				)
				task.wait(0.5)
				InventoryServer.Move(
					plr,
					InventoryServer.GridPosition.new(5, 7),
					InventoryServer.GridPosition.new(4, 6),
					40
				)
				task.wait(0.5)
				InventoryServer.Move(
					plr,
					InventoryServer.GridPosition.new(5, 7),
					InventoryServer.GridPosition.new(4, 6),
					40
				)
				task.wait(0.5)
				InventoryServer.Move(
					plr,
					InventoryServer.GridPosition.new(5, 7),
					InventoryServer.GridPosition.new(4, 6),
					40
				)
				task.wait(0.5)
			end
		end)

		-- testing moveing items back and forth, in particular triggering overflow
		task.spawn(function()
			InventoryServer.Add(plr, { Item = "Rock", Count = 6 }, InventoryServer.GridPosition.new(9, 6))
			InventoryServer.Add(plr, { Item = "Health Potion", Count = 5 }, InventoryServer.GridPosition.new(9, 7))

			while true do
				InventoryServer.Swap(
					plr,
					InventoryServer.GridPosition.new(9, 6),
					InventoryServer.GridPosition.new(10, 6)
				)
				task.wait(0.3)
				InventoryServer.Swap(
					plr,
					InventoryServer.GridPosition.new(10, 6),
					InventoryServer.GridPosition.new(9, 7)
				)
				task.wait(0.3)
				InventoryServer.Swap(
					plr,
					InventoryServer.GridPosition.new(9, 6),
					InventoryServer.GridPosition.new(9, 7)
				)
				task.wait(0.3)
				InventoryServer.Swap(
					plr,
					InventoryServer.GridPosition.new(9, 7),
					InventoryServer.GridPosition.new(10, 6)
				)
				task.wait(0.3)
				InventoryServer.Swap(
					plr,
					InventoryServer.GridPosition.new(9, 6),
					InventoryServer.GridPosition.new(10, 6)
				)
				task.wait(0.3)
				InventoryServer.Swap(
					plr,
					InventoryServer.GridPosition.new(10, 6),
					InventoryServer.GridPosition.new(9, 7)
				)

				task.wait(5)
			end
		end)

		-- task.wait(4)

		-- while true do
		-- 	if InventoryServer.Add(plr, { Item = "Coin", Count = 30 }) then
		-- 		break
		-- 	end
		-- 	task.wait(1)
		-- end

		-- task.wait(4)

		-- while true do
		-- 	InventoryServer.Remove(plr, { Item = "Coin", Count = 10 })

		-- 	task.wait(0.5)
		-- end
	end

	-- Waiting for character to load in the first time
	if not plr.Character then
		plr.CharacterAdded:Wait()
	end

	warn("Commencing tests")

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
