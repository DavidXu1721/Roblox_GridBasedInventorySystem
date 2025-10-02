---[[Services]]--
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

--[[Folders]]--
local RSModules = RS.Modules

--[[Modules]]--

--[[Variables]]--

-- Requiring Inventory Module
local InventoryServer = require(script.InventoryServer)

-- Staring Inventory Module
InventoryServer.Start()