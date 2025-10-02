---[[Services]]--
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

--[[Folders]]--
local Modules = RS.Modules

--[[Modules]]--

--[[Variables]]--
local plr = Players.LocalPlayer
local plrGui = plr.PlayerGui

-- wait for the GUI to load
for i, guiObj in pairs(StarterGui:GetDescendants()) do
	while not plrGui:FindFirstChild(guiObj.Name, true) do
		task.wait()
	end
end

-- Requiring Inventory Module
local InventoryClient = require(script.InventoryClient)

-- Staring Inventory Module
InventoryClient.Start()