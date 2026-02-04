---[[Services]]--
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local CAS = game:GetService("ContextActionService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

--[[Folders]]
--
local Modules = RS.Modules

--[[Modules]]
--
local Janitor = require(Modules.Janitor)
local Signal = require(Modules.Signal)
local TableUtil = require(Modules.TableUtil)
local EasingUtil = require(Modules.EasingUtil)
local InventoryUtil = require(Modules.InventoryUtil)

--[[Types]]
--
local Types = require(Modules.Types)

--[[Data]]
--
local ItemConfigData = require(RS.Data.ItemConfigs)

--[[Variables]]
--
local InventoryClient = {}

-- Player variables
local plr = Players.LocalPlayer
local plrGui = plr.PlayerGui

-- Gui variables
local GUI = plrGui:WaitForChild("InventoryAndHotbar")
GUI.Enabled = true
local DraggingOverlay = GUI:WaitForChild("DraggingOverlay")
local HotbarFrame = GUI:WaitForChild("Hotbar")
local InventoryFrame = GUI:WaitForChild("Inventory")
InventoryFrame.Visible = false
InventoryFrame.Active = true
local InstructionTxtBox = InventoryFrame:WaitForChild("Instructions")
InstructionTxtBox.Visible = false
local InventoryButton = GUI:WaitForChild("InvButton")
local ErrorText = GUI:WaitForChild("Error")
ErrorText.Visible = false

local ItemInfoFrame = InventoryFrame:WaitForChild("ItemInfo")
ItemInfoFrame.Visible = false
ItemInfoFrame.Active = true
local ItemTitleTxtBox = ItemInfoFrame:WaitForChild("ItemName")
local ItemDescScrollingFrame = ItemInfoFrame:WaitForChild("ItemDescScrollingFrame")
local ItemDescTxtBox = ItemDescScrollingFrame:WaitForChild("ItemDesc")
local SlotButton = ItemInfoFrame:WaitForChild("Slot")
local DropButton = ItemInfoFrame:WaitForChild("Drop")

local GridScrollingFrame = InventoryFrame:WaitForChild("GridScrollingFrame")
local InventoryGrid = GridScrollingFrame:WaitForChild("Grid"):WaitForChild("GridContents")
local ItemSample: TextButton = InventoryGrid:WaitForChild("Sample")
ItemSample.Visible = false -- this is a template so that we can easily make new inventory icons

local ArmorFrame = InventoryFrame:WaitForChild("Armor")
ArmorFrame.Active = true
local ArmorInnerFrame = ArmorFrame:WaitForChild("Inner")

--[[Functions]]
--

local function ProcessInventoryData(invData) -- the fact that i even have to do this is absolutely retarded, why is does k turned into a goddamn string?!!
	for i, gridRow in ipairs(invData.Grid) do
		for key, stackData in pairs(gridRow) do
			if typeof(key) == "number" then
				continue
			end

			gridRow[tonumber(key)] = stackData
			gridRow[key] = nil
		end
	end
end

local function GetSlotFrame(slotPos: Types.GridPosition): TextButton?
	if not getmetatable(slotPos) then
		error("slotPos needs to be a gridPosition")
	end

	return InventoryGrid:FindFirstChild("Slot" .. tostring(slotPos))
end

local function UpdateItemImage(targetImage: ImageLabel, item: string | Types.UniqueItemData?, count: number?)
	if not item then
		targetImage.Visible = false
		return
	end

	targetImage.Visible = true

	local countLabel = targetImage:WaitForChild("Count") :: TextLabel

	-- check if the item is a generic or a unique item
	if typeof(item) == "string" then
		targetImage.Image = ItemConfigData[item].IconId or "" -- TODO: add placeholder item image for then there is no icon
		countLabel.Text = `x{count or 0}`
		countLabel.Visible = true
	elseif typeof(item) == "table" then
		targetImage.Image = ItemConfigData[item.Id].IconId or ""
		countLabel.Visible = false
	end
end

local function UpdateSlotUI(gridPos: Types.GridPosition, slotInfo: Types.StackData?): TextButton
	local slotName = "Slot" .. tostring(gridPos)

	local itemSlot = InventoryGrid:FindFirstChild(slotName)

	if not itemSlot then
		itemSlot = ItemSample:Clone()
		itemSlot.Name = slotName
		itemSlot.Visible = true
		itemSlot.Parent = InventoryGrid
		-- print("created ".. slotName)
	end

	itemSlot = itemSlot :: TextButton

	local slotImage: ImageLabel = itemSlot.Image

	local hotbarSlot: TextButton = nil

	if gridPos.y == 1 then -- this is the first row, so get the corresponding hotbar slot
		hotbarSlot = HotbarFrame:WaitForChild("Slot" .. tostring(gridPos.x))
	end

	if slotInfo == nil then
		UpdateItemImage(slotImage, nil)

		if hotbarSlot then
			local hotbarSlotImage = hotbarSlot:WaitForChild("Image") :: ImageLabel

			UpdateItemImage(hotbarSlotImage, nil)
		end

		if InventoryClient.DraggingSlot == gridPos then -- we are currently dragging this slot, you shouldn't be able to
			warn("You shouldn't be dragging an empty slot")
			UpdateItemImage(DraggingOverlay.DragImage, nil)
			slotImage.Visible = false
		end
	else
		-- this is a check to make sure that we never have a situation where we have a slotInfo that is not nil with a count of 0
		if slotInfo.Count == 0 then
			print(slotName)
			print(slotInfo)
			error("ERROR: slotInfo can't have a count of 0")
		end

		local stackCount = slotInfo.Count or 1

		if InventoryClient.DraggingSlot == gridPos then -- we are currently dragging this slot, so the image is in the draggingOverlay
			-- this is a check to make sure that the DraggingCount is never 0
			if InventoryClient.DraggingCount == 0 then
				print(slotName)
				print(slotInfo)
				error("ERROR: DraggingCount can't be 0 when DraggingSlot is not nil")
			elseif InventoryClient.DraggingCount > stackCount then
				print(slotName)
				print(slotInfo)
				error("ERROR: DraggingCount can't greater than the stack count")
			end

			UpdateItemImage(DraggingOverlay.DragImage, slotInfo.Item, InventoryClient.DraggingCount)
			UpdateItemImage(slotImage, slotInfo.Item, stackCount - InventoryClient.DraggingCount)

			if InventoryClient.DraggingCount == stackCount then
				slotImage.Visible = false
			end
		else
			UpdateItemImage(slotImage, slotInfo.Item, stackCount)
		end

		if hotbarSlot then
			UpdateItemImage(hotbarSlot:WaitForChild("Image") :: ImageLabel, slotInfo.Item, stackCount)
		end
	end

	return itemSlot
end

---------------------------------------------------------------------------------

InventoryClient.OpenPosition =
	{ Inventory = InventoryFrame.Position, Hotbar = HotbarFrame.Position + UDim2.fromScale(0, 0.2) }
InventoryClient.ClosePosition =
	{ Inventory = InventoryFrame.Position + UDim2.fromScale(0, 1), Hotbar = HotbarFrame.Position }
InventoryClient.IsOpen = false
InventoryClient.OpenCloseTimePeriod = 0.2
InventoryClient.OpenCloseTimePosition = 0

InventoryClient.YScaleEasingArray = TableUtil.Map({ Inventory = {}, Hotbar = {} }, function(_, key)
	return EasingUtil.quadInOut(
		InventoryClient.ClosePosition[key].Y.Scale,
		InventoryClient.OpenPosition[key].Y.Scale,
		100
	)
end)

InventoryClient.UpdatingDebounce = false

InventoryClient.InvData = nil
InventoryClient.SelectedSlot = nil
InventoryClient.SelectJanitor = Janitor.new()
InventoryClient.DraggingSlot = nil -- this is meant to indicate which slot is currently having the item dragged by the cursor
InventoryClient.DraggingCount = 0
InventoryClient.DraggingJanitor = Janitor.new()
InventoryClient.MousePosition = Vector2.zero

InventoryClient.GridJanitor = Janitor.new()

-- Input began
function InventoryClient.OnInputBegan(input: InputObject, gameProcessedEvent: boolean)
	if gameProcessedEvent then
		return
	end

	-- open / close
	if input.KeyCode == Enum.KeyCode.I then
		InventoryClient.ToggleInventory(not InventoryClient.IsOpen)
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then -- this is when you click while in the inventory and it didn't click on an item
		if not InventoryClient.IsOpen then
			return
		end

		if InventoryClient.DraggingSlot then
			InventoryClient.StopDraggingSlot()
		end
		InventoryClient.SelectGridSlot(nil)
	end
end

-- Input ended
function InventoryClient.OnInputEnded(input: InputObject, gameProcessedEvent: boolean)
	if gameProcessedEvent then
		return
	end

	-- open / close
	if input.UserInputType == Enum.UserInputType.MouseButton1 then -- this is when you let go of the mouse button when the mouse is not over an inventory slot
		-- we must stop dragging any item images if we were dragging them before
		if InventoryClient.DraggingSlot then
			InventoryClient.StopDraggingSlot()
		end
	end
end

-- Input changed
function InventoryClient.OnInputChanged(input: InputObject, gameProcessedEvent: boolean)
	if gameProcessedEvent then
		return
	end
end

-- GUI Inputs

function InventoryClient.GUIOnMouseButton1Down(button: GuiButton) -- This is just a convienient master function for button presses
end

-- Opening and closing
function InventoryClient.ToggleInventory(toSet: boolean)
	if InventoryClient.DraggingSlot and not toSet then
		InventoryClient.StopDraggingSlot()
	end
	InventoryClient.IsOpen = toSet
end

-- Selecting items
function InventoryClient.SelectGridSlot(gridPos: Types.GridPosition?)
	--Setting selected item
	InventoryClient.SelectedSlot = gridPos -- gridPos can be nil, so to deselect, just call SelectgridSlot() with no parameters

	--Clearing the bound actions
	InventoryClient.SelectJanitor:Clean()

	--Finding the selected slot button
	local selectedGridSlot: TextButton? = if gridPos then GetSlotFrame(gridPos) else nil

	--Setting frame colors
	for i, otherGridSlot: TextButton in InventoryGrid:GetChildren() do
		if otherGridSlot.ClassName == "TextButton" and otherGridSlot ~= ItemSample then
			if otherGridSlot == selectedGridSlot then
				otherGridSlot.BackgroundColor3 = otherGridSlot:GetAttribute("SelectedColor") :: Color3
			else
				otherGridSlot.BackgroundColor3 = otherGridSlot:GetAttribute("NormalColor") :: Color3
			end
		end
	end

	--Updating information
	if selectedGridSlot ~= nil then
		local slotInfo: Types.StackData? = InventoryUtil.GetSlotInfo(InventoryClient.InvData, gridPos)

		if not slotInfo then
			error("ERROR: Slot " .. tostring(gridPos) .. " doesn't have an item in it") -- as far as i can see, this should never happen
		end

		--Bind the Drop button to a key
		CAS:BindAction("DropItem", function(actionName, inputState, inputObject)
			if inputState == Enum.UserInputState.Begin then -- drop the item
				local selectedSlotInfo = InventoryUtil.GetSlotInfo(InventoryClient.InvData, gridPos) -- due to the fact that we are not "refeshing" the select every time we call an updateDisplay, it may be that the slotInfo becomes outdated, if we drop part of a stack via dropping dragged items. in that case the slotInfo is still from the previous InvData state

				if InventoryClient.DraggingSlot then -- here we must only drop the item/s we are currently dragging
					if InventoryClient.DraggingSlot ~= InventoryClient.SelectedSlot then
						error("Dragging slot should never be different from selected slot")
					end

					print(
						"Dropped  "
							.. InventoryClient.DraggingCount
							.. " of "
							.. (selectedSlotInfo.Item.Id or selectedSlotInfo.Item)
							.. " from Slot "
							.. tostring(InventoryClient.DraggingSlot)
					)

					InventoryClient.Remove(
						{ Item = selectedSlotInfo.Item, Count = InventoryClient.DraggingCount },
						InventoryClient.DraggingSlot
					)

					if InventoryClient.DraggingSlot then
						InventoryClient.StopDraggingSlot()
					end

					InventoryClient.UpdateDisplay()
				else -- here we can just drop the entire stack
					print(
						"Dropped all of "
							.. (selectedSlotInfo.Item.Id or selectedSlotInfo.Item)
							.. " from Slot "
							.. tostring(InventoryClient.SelectedSlot)
					)
					InventoryClient.Remove(selectedSlotInfo, InventoryClient.SelectedSlot)

					if InventoryClient.DraggingSlot then
						InventoryClient.StopDraggingSlot()
					end

					InventoryClient.UpdateDisplay()
				end
			end
		end, false, Enum.KeyCode.Q)

		InventoryClient.SelectJanitor:GiveChore(function()
			CAS:UnbindAction("DropItem")
		end)

		--Setting stack information
		ItemInfoFrame.Visible = true
		ItemTitleTxtBox.Text = if typeof(slotInfo.Item) == "string"
			then ItemConfigData[slotInfo.Item].Name
			else ItemConfigData[slotInfo.Item.Id].Name
		ItemDescTxtBox.Text = if typeof(slotInfo.Item) == "string"
			then ItemConfigData[slotInfo.Item].Description
			else ItemConfigData[slotInfo.Item.Id].Description

		--TODO: adjust the size of the ItemDescTxtBox as well as the ItemDescScrollingFrame's canvas size based on how much text there is
	else
		ItemInfoFrame.Visible = false
	end
end

-- Dragging item images
function InventoryClient.StartDraggingSlot(targetSlotPos: Types.GridPosition?, dragCount: number?)
	if not targetSlotPos then
		error("Error: targetSlotPos must be present!")
	end

	local TargetSlotFrame = GetSlotFrame(targetSlotPos) :: TextButton
	local DraggingImage = TargetSlotFrame:FindFirstChild("Image") :: ImageLabel?

	local SlotInfo = InventoryUtil.GetSlotInfo(InventoryClient.InvData, targetSlotPos) :: Types.StackData?

	if not SlotInfo then
		error("ERROR: Slot " .. tostring(targetSlotPos) .. " doesn't have an item in it")
	end
	if not DraggingImage then
		error("ERROR: TargetSlotFrame doesn't have an image")
	end
	-- clean up any previous binds for incrementing dragging count
	InventoryClient.DraggingJanitor:Clean()

	InventoryClient.DraggingSlot = targetSlotPos

	if dragCount and dragCount > (SlotInfo.Count or 1) then
		error("can't have the specified drag count be more than the stack count")
	end

	InventoryClient.DraggingCount = dragCount or SlotInfo.Count or 1 -- TODO: allow custom dragcounts, necessary for dealing with swapping slots that you are dragging.

	CAS:BindAction("AdjustDraggingCount", function(actionName, inputState, inputObject)
		if GridScrollingFrame.ScrollingEnabled then
			return Enum.ContextActionResult.Pass
		end -- basically, even if the cursor is outisde of the inventory you still can't increment dragging count

		print("adfj,he")
		if inputState == Enum.UserInputState.Change then
			if inputObject.UserInputType == Enum.UserInputType.MouseWheel then
				print("Scrolled!", inputObject.Position.Z)
				local draggingSlotInfo =
					InventoryUtil.GetSlotInfo(InventoryClient.InvData, InventoryClient.DraggingSlot)

				local countChange = if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then 10 else 1

				InventoryClient.DraggingCount = math.min(
					(draggingSlotInfo.Count or 1),
					math.max(0, InventoryClient.DraggingCount + countChange * inputObject.Position.Z)
				)

				if InventoryClient.DraggingCount == 0 then
					InventoryClient.StopDraggingSlot() -- don't need to call UpdateSlotUI here as the images were handled in the StopDraggingSlot
				else
					UpdateSlotUI(InventoryClient.DraggingSlot, draggingSlotInfo)
				end
			end
		end

		return Enum.ContextActionResult.Sink -- "consume" the input
	end, false, Enum.UserInputType.MouseWheel)

	CAS:BindAction( -- this essentially makes the dragging count half of the stack count, rounding up.
		"SplitDraggingCount",
		function(actionName, inputState, inputObject)
			if inputState == Enum.UserInputState.Begin then
				local draggingSlotInfo =
					InventoryUtil.GetSlotInfo(InventoryClient.InvData, InventoryClient.DraggingSlot)

				local stackCount = draggingSlotInfo.Count or 1

				if InventoryClient.DraggingCount < stackCount then
					InventoryClient.DraggingCount = stackCount
				else
					InventoryClient.DraggingCount = math.ceil(stackCount / 2)
				end

				UpdateSlotUI(InventoryClient.DraggingSlot, draggingSlotInfo)
			end

			return Enum.ContextActionResult.Sink
		end,
		false,
		Enum.KeyCode.LeftControl
	)

	CAS:BindAction( -- this enables the drag count incrementation when you start holding the space bar, due to the inventory being scrollable and all that
		"ToggleDraggingCountIncrement",
		function(actionName, inputState, inputObject)
			if inputState == Enum.UserInputState.Begin then
				GridScrollingFrame.ScrollingEnabled = false
			elseif inputState == Enum.UserInputState.End then
				GridScrollingFrame.ScrollingEnabled = true
			end

			return Enum.ContextActionResult.Sink -- "consume" the input
		end,
		false,
		Enum.KeyCode.Space
	)

	if UIS:IsKeyDown(Enum.KeyCode.Space) then
		GridScrollingFrame.ScrollingEnabled = false
	end

	InventoryClient.DraggingJanitor:GiveChore(DropButton.MouseButton1Up:Connect(function()
		-- If the player lets go of the item on the drop button, they drop the item
		local draggingSlot = InventoryUtil.GetSlotInfo(InventoryClient.InvData, InventoryClient.DraggingSlot)

		print(
			"Dropped  "
				.. InventoryClient.DraggingCount
				.. " of "
				.. (draggingSlot.Item.Id or draggingSlot.Item)
				.. " from Slot "
				.. tostring(InventoryClient.DraggingSlot)
		)
		InventoryClient.Remove(
			{ Item = draggingSlot.Item, Count = InventoryClient.DraggingCount },
			InventoryClient.DraggingSlot
		)

		if InventoryClient.DraggingSlot then
			InventoryClient.StopDraggingSlot()
		end

		InventoryClient.UpdateDisplay()
	end))

	InventoryFrame.Active = false
	ArmorFrame.Active = false
	ItemInfoFrame.Active = false
	SlotButton.Interactable = false
	InventoryButton.Interactable = false

	InventoryClient.DraggingJanitor:GiveChore(function()
		CAS:UnbindAction("AdjustDraggingCount")
		CAS:UnbindAction("SplitDraggingCount")
		CAS:UnbindAction("ToggleDraggingCountIncrement")
		GridScrollingFrame.ScrollingEnabled = true
		InventoryFrame.Active = true
		ArmorFrame.Active = true
		ItemInfoFrame.Active = true
		InventoryButton.Interactable = true
	end)

	-- give the dragimage the same image as the one on the slot
	UpdateItemImage(DraggingOverlay:WaitForChild("DragImage"), SlotInfo.Item, InventoryClient.DraggingCount)
	-- clear the image on the slot
	UpdateItemImage(TargetSlotFrame.Image, nil)
end

function InventoryClient.StopDraggingSlot(ignoreNilDraggingSlot: boolean?)
	print("asdsasdadsaasdsdadsa")
	if InventoryClient.DraggingSlot then
		local DraggingSlotFrame: TextButton? = GetSlotFrame(InventoryClient.DraggingSlot)
		local DraggingSlotInfo: Types.StackData? =
			InventoryUtil.GetSlotInfo(InventoryClient.InvData, InventoryClient.DraggingSlot)

		if not DraggingSlotFrame then
			error("Error: SlotFrame for Slot" .. tostring(InventoryClient.DraggingSlot) .. " does not exist")
		end

		-- clear the DragImage
		UpdateItemImage(DraggingOverlay.DragImage, nil)

		-- if we did update the inventory by moving an item around then the image should be remedied anyway, but in the cases where we dragged the image to nothing (aka, the border, and thus not triggering any move/swap event), we have to make that slot's image visible again

		if not DraggingSlotInfo then
			if not ignoreNilDraggingSlot then
				warn("You shouldn't have been dragging an empty slot")
			end
			UpdateItemImage(DraggingSlotFrame:FindFirstChild("Image") :: ImageLabel, nil)
		else
			UpdateItemImage(
				DraggingSlotFrame:FindFirstChild("Image") :: ImageLabel,
				DraggingSlotInfo.Item,
				DraggingSlotInfo.Count
			)
		end

		InventoryClient.DraggingSlot = nil
		InventoryClient.DraggingCount = 0

		InventoryClient.DraggingJanitor:Clean()
	else
		warn("Tried to stop dragging when you are not currently dragging anything")
	end
end

-- Updating Inventory data
function InventoryClient.UpdateInventoryData() -- for now, we do the fully server sided way, baby steps man, baby steps...
	local retrievedInvData = HttpService:JSONDecode(Signal.InvokeServer("InventoryServer:GetInventoryJSON"))

	ProcessInventoryData(retrievedInvData)

	InventoryClient.InvData = retrievedInvData
end

-- Updating display
function InventoryClient.UpdateDisplay()
	while InventoryClient.UpdatingDebounce do
		task.wait()
	end -- this does feel unnecessary, especially considering that there is nothing async happening here
	InventoryClient.UpdatingDebounce = true

	local InvData: Types.Inventory = InventoryClient.InvData

	if InvData == nil then
		error("InvData not set!")
	end

	-- Clearing any previous connections
	InventoryClient.GridJanitor:Clean()

	-- Update Grid dimensions
	local GridDimensions = InventoryUtil.GridPosition.new(
		10, -- NOTE: for now I'm going to be assuming that the grid is 10 spaces wide, to make it make sense with the hotbar and stuff
		#InvData.Grid
	)

	GridScrollingFrame.Grid:WaitForChild("UIAspectRatioConstraint").AspectRatio = GridDimensions.x / GridDimensions.y
	GridScrollingFrame.Grid:WaitForChild("HotbarBackground").Size = UDim2.fromScale(1, 1 / GridDimensions.y)

	GridScrollingFrame.CanvasSize = UDim2.fromOffset(0, GridScrollingFrame.Grid.AbsoluteSize.Y)

	-- adjust the padding and cell size/spacing of the grid, as of now the cell spacing is set to be 10% of the width of the each grid space,
	local innerCellPadding = { 1 / (11 * GridDimensions.x - 1), 1 / (11 * GridDimensions.y - 1) }
	local outerCellPadding =
		{ innerCellPadding[1] / (innerCellPadding[1] + 1), innerCellPadding[2] / (innerCellPadding[2] + 1) }

	local GridUIPadding = InventoryGrid:WaitForChild("UIPadding")

	GridUIPadding.PaddingTop = UDim.new(outerCellPadding[2] / 2, 0)
	GridUIPadding.PaddingBottom = UDim.new(outerCellPadding[2] / 2, 0)
	GridUIPadding.PaddingLeft = UDim.new(outerCellPadding[1] / 2, 0)
	GridUIPadding.PaddingRight = UDim.new(outerCellPadding[1] / 2, 0)

	local GridUILayout = InventoryGrid:WaitForChild("UIGridLayout")

	GridUILayout.CellSize = UDim2.fromScale(innerCellPadding[1] * 10, innerCellPadding[2] * 10)
	GridUILayout.CellPadding = UDim2.fromScale(innerCellPadding[1], innerCellPadding[2])

	-- Clearing grid slots if they are no longer present, only really a factor if we change the inventory size
	-- TODO: I honestly doubt that this will turn into a performance issue, but I guess I can make it so that it only runs when I actually changed the grid size
	for _, itemF: TextButton in InventoryGrid:GetChildren() do
		if itemF.ClassName == "TextButton" and itemF ~= ItemSample then
			local i, j = itemF.Name:match("(%d+)_(%d+)")

			if tonumber(i) > GridDimensions.y or tonumber(j) > GridDimensions.x then
				itemF:Destroy()
			end
		end
	end

	for i = 1, GridDimensions.y do
		for j = 1, GridDimensions.x do
			local currentGridPos = InventoryUtil.GridPosition.new(j, i)

			local currentItemSlot

			local slotInfo: Types.StackData? = InventoryUtil.GetSlotInfo(InventoryClient.InvData, currentGridPos)

			if slotInfo == nil then
				currentItemSlot = UpdateSlotUI(currentGridPos, nil)
			else -- There is actually an item in this slot
				currentItemSlot = UpdateSlotUI(currentGridPos, slotInfo)

				InventoryClient.GridJanitor:GiveChore(currentItemSlot.MouseButton1Down:Connect(function()
					InventoryClient.SelectGridSlot(currentGridPos)

					if InventoryClient.DraggingSlot then
						InventoryClient.StopDraggingSlot()
					end -- just in case a slot was still being dragged when you clicked on a new slot

					InventoryClient.StartDraggingSlot(currentGridPos)
				end))
			end

			InventoryClient.GridJanitor:GiveChore( -- TODO: maybe I should put this in the start dragging slot function
				currentItemSlot.MouseButton1Up:Connect(function()
					if InventoryClient.DraggingSlot then
						local prevDraggingSlot = InventoryClient.DraggingSlot

						if currentGridPos == prevDraggingSlot then
							InventoryClient.StopDraggingSlot()
							return
						end -- if we "dragged" the dragging slot to the same slot, just ignore it

						print("Dragged Slot" .. tostring(prevDraggingSlot) .. " to Slot " .. tostring(currentGridPos))

						-- in the effort to not trigger any overflow items. Checks to adjust the movecount will be made in advance, and not in the Move function, (it's a warning for a reason, because it should not happen)
						local moveCount = 0
						local dragSlotInfo = InventoryUtil.GetSlotInfo(InventoryClient.InvData, prevDraggingSlot)
						local dragCount = InventoryClient.DraggingCount
						local maxStackCount = nil

						if slotInfo == nil then
							-- we can move all of the dragged items into the empty slot, but we might as well double check to see if the drag count we have isn't somehow more than the max stackCount of the item type
							maxStackCount = if typeof(dragSlotInfo.Item) == "table"
								then 1
								else InventoryUtil.MaxStackData[ItemConfigData[dragSlotInfo.Item].ItemType]
							assert(maxStackCount ~= nil and maxStackCount ~= 0)

							if maxStackCount < dragCount then
								warn("the dragging count shouldn't be larger than the max stack count")
								moveCount = maxStackCount
							else
								moveCount = dragCount
							end
						elseif typeof(dragSlotInfo.Item) == "string" and dragSlotInfo.Item == slotInfo.Item then
							--if the dragged item is a generic item and is of the same Id as the slotItem it was dragged to
							assert(typeof(slotInfo.Item) == "string")

							maxStackCount = InventoryUtil.MaxStackData[ItemConfigData[slotInfo.Item].ItemType]

							moveCount = math.min(maxStackCount - slotInfo.Count, dragCount)
						end

						InventoryClient.Move(prevDraggingSlot, currentGridPos, moveCount)

						-- if we end up moving all the items we were dragging, we might as well just select the slot we moved the items into
						if moveCount == dragCount then
							InventoryClient.SelectGridSlot(currentGridPos)
						end

						InventoryClient.UpdateDisplay()

						if InventoryClient.DraggingSlot then
							InventoryClient.StopDraggingSlot()
						end
					end
				end)
			)

			InventoryClient.GridJanitor:GiveChore(currentItemSlot.MouseButton2Click:Connect(function()
				if InventoryClient.DraggingSlot then
					print(
						"Swapped Slot"
							.. tostring(InventoryClient.DraggingSlot)
							.. " with Slot "
							.. tostring(currentGridPos)
					)
					InventoryClient.Swap(InventoryClient.DraggingSlot, currentGridPos)
					InventoryClient.UpdateDisplay()

					InventoryClient.StopDraggingSlot()
				end
			end))

			InventoryClient.GridJanitor:GiveChore(currentItemSlot.MouseEnter:Connect(function()
				--print("lol".. tostring(currentGridPos))
			end))
		end
	end

	InventoryClient.UpdatingDebounce = false
end

-- Move Item Slots within the inventory grid
function InventoryClient.Move(startPos: Types.GridPosition, endPos: Types.GridPosition, moveCount: number?)
	if not InventoryClient.InvData then
		warn("LocalPlayer's inventory does not exist")
		return
	end

	local startStackData = InventoryUtil.GetSlotInfo(InventoryClient.InvData, startPos)
	if not startStackData then
		warn("Slot" .. tostring(startPos) .. " is empty")
		return
	end
	-- print(startStackData)

	local startStackCount = if typeof(startStackData.Item) == "string" then startStackData.Count else 1

	moveCount = moveCount or (startStackCount or 1)

	-- if the movecount is 0 then we must stop because it will try to move unique items, as they don't look at count
	if moveCount <= 0 then
		return
	end

	if moveCount > startStackCount then
		warn("there are not enough items for there to move, moving what is there")
		moveCount = startStackCount
	end

	-- update the dragging slot
	-- TODO: move the draggingSlot check inside of the selectedSlot check

	if startPos == InventoryClient.DraggingSlot then
		-- TECHNICALLY speaking this only works because draggingSlot should always be the selected slot, just be cautious i guess?
		local stackCount = (InventoryUtil.GetSlotInfo(InventoryClient.InvData, startPos) :: Types.StackData).Count or 1
		-- TODO: I have no idea what the hell I did here with making a new stackCount variable and all that when I could have just used startStackData, nor the reason why.

		if moveCount == stackCount then
			-- all the items in the stack have been moved, so we must deselect and stop dragging as the slot is (going to be) empty
			InventoryClient.StopDraggingSlot()
			InventoryClient.SelectGridSlot()
		elseif moveCount > stackCount then
			-- a quick check I guess
			warn("movecount should not be greater than the items already in the stack")
			InventoryClient.StopDraggingSlot()
			InventoryClient.SelectGridSlot()
		else -- not all the items in the stack were moved, there are still some left, so we have to update the draggingCount
			InventoryClient.DraggingCount = stackCount - moveCount
		end
		-- if the startPos is instead just the selectedSlot then just update the selected slot
	elseif startPos == InventoryClient.SelectedSlot then
		local stackCount = (InventoryUtil.GetSlotInfo(InventoryClient.InvData, startPos) :: Types.StackData).Count or 1

		if moveCount == stackCount then
			-- all the items in the stack have been moved, so we must deselect and stop dragging as the slot is (going to be) empty

			InventoryClient.SelectGridSlot()
		elseif moveCount > stackCount then
			-- a quick check I guess
			warn("movecount should not be greater than the items already in the stack")
			InventoryClient.SelectGridSlot()
		end
	elseif endPos == InventoryClient.DraggingSlot then
		local stackCount = (InventoryUtil.GetSlotInfo(InventoryClient.InvData, endPos) :: Types.StackData).Count or 1

		InventoryClient.DraggingCount = stackCount + moveCount
	end

	-- we unregister the items from the start slot, then try to register them into the end slot
	local overflowItems = InventoryUtil.RegisterItem(
		InventoryClient.InvData,
		InventoryUtil.UnregisterItem(
			InventoryClient.InvData,
			{ Count = if typeof(startStackData.Item) == "string" then moveCount else nil, Item = startStackData.Item },
			startPos
		),
		endPos
	)

	if overflowItems then
		warn("items have overflowed, adjusting movecount and returning items unable to be moved")
		moveCount -= overflowItems.Count or 1
	end

	InventoryUtil.RegisterItem(InventoryClient.InvData, overflowItems, startPos)

	if startPos == InventoryClient.DraggingSlot then
		-- this is mostly just a check, as for this code to be run, the startPos must have been the one we were dragging but not all of the items were removed, so we need to double check if the DraggingCount matches
		local stackCount = (InventoryUtil.GetSlotInfo(InventoryClient.InvData, startPos) :: Types.StackData).Count or 1

		if InventoryClient.DraggingCount ~= stackCount then
			warn("updated dragging count should be equal to the new stackCount")
		end
	elseif endPos == InventoryClient.DraggingSlot then
		local stackCount = (InventoryUtil.GetSlotInfo(InventoryClient.InvData, startPos) :: Types.StackData).Count or 1

		if InventoryClient.DraggingCount ~= stackCount then
			warn("updated dragging count should be equal to the new stackCount")
		end
	end
end

-- Swap Item Slots within the inventory grid
function InventoryClient.Swap(APos: Types.GridPosition, BPos: Types.GridPosition)
	if not InventoryClient.InvData then
		warn("LocalPlayer's inventory does not exist")
		return
	end

	-- stop dragging slots if relevant
	local newDragSlot
	local cachedDragCount = nil

	if APos == InventoryClient.DraggingSlot then
		cachedDragCount = InventoryClient.DraggingCount
		InventoryClient.StopDraggingSlot()
		newDragSlot = BPos
	elseif BPos == InventoryClient.DraggingSlot then
		cachedDragCount = InventoryClient.DraggingCount
		InventoryClient.StopDraggingSlot()
		newDragSlot = APos
	end

	local ASlot = InventoryUtil.UnregisterItem(
		InventoryClient.InvData,
		InventoryUtil.GetSlotInfo(InventoryClient.InvData, APos),
		APos
	)
	local BSlot = InventoryUtil.UnregisterItem(
		InventoryClient.InvData,
		InventoryUtil.GetSlotInfo(InventoryClient.InvData, BPos),
		BPos
	)
	InventoryUtil.RegisterItem(InventoryClient.InvData, ASlot, BPos)
	InventoryUtil.RegisterItem(InventoryClient.InvData, BSlot, APos)

	-- update selected slot
	if APos == InventoryClient.SelectedSlot then
		InventoryClient.SelectGridSlot(BPos)
	elseif BPos == InventoryClient.SelectedSlot then
		InventoryClient.SelectGridSlot(APos)
	end

	-- start dragging the new slot
	if newDragSlot then
		InventoryClient.StartDraggingSlot(newDragSlot, cachedDragCount)
	end
end

-- Add item/s to the player's inventory
function InventoryClient.Add(itemsToAdd: Types.StackData?, targetGridPos: Types.GridPosition?)
	if not InventoryClient.InvData then
		warn(plr.Name .. "'s inventory does not exist")
		return
	end

	if not itemsToAdd then
		return
	end

	local fullStackDragged -- the way this works is as follows: if you were dragging the entire slot, (aka, DraggingCount == slotInfo.count) then the increase in the number of items in the slot is reflected in the dragging count, otherwise there is no increase in the dragging count and the newly added items will be left undragged

	if InventoryClient.DraggingSlot then
		local oldDraggingSlotInfo = InventoryUtil.GetSlotInfo(InventoryClient.InvData, InventoryClient.DraggingSlot)

		fullStackDragged = InventoryClient.DraggingCount == (oldDraggingSlotInfo.Count or 1) --tbh the 'or' shouldn't ever be considered since unique items can't stack, but it probably con't matter
	end

	local overflowItems = InventoryUtil.RegisterItem(InventoryClient.InvData, itemsToAdd, targetGridPos)

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

	if fullStackDragged then
		local newDraggingSlotInfo = InventoryUtil.GetSlotInfo(InventoryClient.InvData, InventoryClient.DraggingSlot)

		InventoryClient.DraggingCount = (newDraggingSlotInfo.Count or 1)
	end

	return overflowItems
end

-- Remove item/s from the player's inventory
function InventoryClient.Remove(itemsToRemove: Types.StackData?, targetGridPos: Types.GridPosition?)
	if not InventoryClient.InvData then
		warn(plr.Name .. "'s inventory does not exist")
		return
	end

	if not itemsToRemove then
		return
	end

	-- NOTE: here we actually need to make sure that the inventory that we are removing from actually has the the items. This will ERROR if there are not enough items present
	local removedItems = InventoryUtil.UnregisterItem(InventoryClient.InvData, itemsToRemove, targetGridPos)
	-- this is annoying as shit, but I guess this is a special case where we have to check if there are any changes to the draggingSlot AFTER the update to the InvData
	if InventoryClient.DraggingSlot then
		local draggingSlotInfo = InventoryUtil.GetSlotInfo(InventoryClient.InvData, InventoryClient.DraggingSlot)

		if draggingSlotInfo == nil then -- the slot is completely removed, so stop dragging the slot
			InventoryClient.StopDraggingSlot(true)
		else
			InventoryClient.DraggingCount = math.min(InventoryClient.DraggingCount, draggingSlotInfo.Count or 1)
		end
	end

	if InventoryClient.SelectedSlot then
		local selectedSlotInfo = InventoryUtil.GetSlotInfo(InventoryClient.InvData, InventoryClient.SelectedSlot)

		if selectedSlotInfo == nil then -- the slot is completely removed, so stop dragging the slot
			InventoryClient.SelectGridSlot()
		end
	end

	return removedItems
end

function InventoryClient.HandleUpdate(
	newInvDataJSON: string?,
	updateInfo: Types.InventoryUpdateInfo --[[to be used later for net code stuff]]
)
	local newInvData = HttpService:JSONDecode(newInvDataJSON)

	ProcessInventoryData(newInvData)
	--print(InventoryClient.InvData)

	if not InventoryClient.InvData then
		warn("LocalPlayer's inventory does not exist yet")
		return
	end

	-- use the update info to do any relevant changes
	if updateInfo then
		local updateData = updateInfo.Data

		if updateInfo.Type == "Swap" then
			-- you can't send metatables via the network so I will need to remake the GridPositions
			updateData.APos = InventoryUtil.GridPosition.new(updateData.APos.x, updateData.APos.y)
			updateData.BPos = InventoryUtil.GridPosition.new(updateData.BPos.x, updateData.BPos.y)

			InventoryClient.Swap(updateData.APos, updateData.BPos)
		elseif updateInfo.Type == "Move" then
			-- you can't send metatables via the network so I will need to remake the GridPositions
			updateData.startPos = InventoryUtil.GridPosition.new(updateData.startPos.x, updateData.startPos.y)
			updateData.endPos = InventoryUtil.GridPosition.new(updateData.endPos.x, updateData.endPos.y)

			InventoryClient.Move(updateData.startPos, updateData.endPos, updateData.moveCount)
		elseif updateInfo.Type == "Add" then
			-- you can't send metatables via the network so I will need to remake the GridPositions
			if updateData.targetGridPos then
				updateData.targetGridPos =
					InventoryUtil.GridPosition.new(updateData.targetGridPos.x, updateData.targetGridPos.y)
			end

			InventoryClient.Add(updateData.itemsToAdd, updateData.targetGridPos)
		elseif updateInfo.Type == "Remove" then
			-- you can't send metatables via the network so I will need to remake the GridPositions
			if updateData.targetGridPos then
				updateData.targetGridPos =
					InventoryUtil.GridPosition.new(updateData.targetGridPos.x, updateData.targetGridPos.y)
			end

			InventoryClient.Remove(updateData.itemsToRemove, updateData.targetGridPos)
		end
	end

	-- check if the selectedGridSlot is empty
	if
		InventoryClient.SelectedSlot
		and InventoryUtil.GetSlotInfo(InventoryClient.InvData, InventoryClient.SelectedSlot) == nil
	then
		warn("selectedSlot should not have no item as that should have been dealt with above")
		InventoryClient.SelectGridSlot()
	end

	-- Check if there is desync in the inventory data
	if not TableUtil.DeepEqual(InventoryClient.InvData, newInvData) then
		warn("DESYNC DETECTED")
		warn("CLIENT:")
		warn(InventoryClient.InvData)
		warn("SERVER:")
		warn(newInvData)

		InventoryClient.SelectGridSlot()
		InventoryClient.StopDraggingSlot()
		InventoryClient.InvData = newInvData
	end

	--print(InventoryClient.InvData)
	-- TODO: look into batching the updates (if the server ends up calling a ton of little changes)
	InventoryClient.UpdateDisplay()
end

-- Starting
function InventoryClient.Start()
	-- Disable default backpack
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

	-- Updating inventory
	task.spawn(function()
		InventoryClient.UpdateInventoryData()
		InventoryClient.UpdateDisplay()
		print(InventoryClient.InvData)
	end)

	-- Connecting signals
	Signal.ListenRemote("InventoryClient:Update", InventoryClient.HandleUpdate)

	-- Making sure that the canvas size of the GridScrollingFrame matches the absolute size of the Grid (in case the window is resized)
	GridScrollingFrame.Grid.Changed:Connect(function(property)
		if property ~= "AbsoluteSize" then
			return
		end

		GridScrollingFrame.CanvasSize = UDim2.fromOffset(0, GridScrollingFrame.Grid.AbsoluteSize.Y)
	end)

	-- Input Bind
	task.spawn(
		function() -- This disables the i and o keys for zooming in and out, so that we can use it for the inventroy toggle
			for _ = 1, 2 do
				while true do
					local info = CAS:GetBoundActionInfo("RbxCameraKeypress")
					if info and info.inputTypes then
						-- print(info)
						CAS:UnbindAction("RbxCameraKeypress")
						break
					else
						task.wait()
					end
				end
			end
		end
	)

	UIS.InputBegan:Connect(InventoryClient.OnInputBegan)
	UIS.InputEnded:Connect(InventoryClient.OnInputEnded)
	UIS.InputChanged:Connect(InventoryClient.OnInputChanged)

	--Open/close
	InventoryButton.MouseButton1Click:Connect(function()
		InventoryClient.ToggleInventory(not InventoryClient.IsOpen)
	end)

	--Update the mouse position for the dragging images I can't use UIS because for some actual BULLSHIT, the UI is offset and slightly shorter to accomodate the DEFAULT roblox UI, so the positions won't match
	DraggingOverlay.MouseMoved:Connect(function(x, y)
		InventoryClient.MousePosition = Vector2.new(x, y)
	end)

	-- Move the Inventory back and forth based on whether it's open or closed
	task.spawn(function()
		RunService:BindToRenderStep(
			"update UI",
			2000,
			function(delta) -- RenderStepped/PreRender happens after the UI rendering for some reason, so I'm using BindToRenderStep, apparently priority 2000 still happens before the UI renders
				if InventoryClient.IsOpen then
					InventoryClient.OpenCloseTimePosition =
						math.min(InventoryClient.OpenCloseTimePeriod, InventoryClient.OpenCloseTimePosition + delta)
				else
					InventoryClient.OpenCloseTimePosition =
						math.max(0.001, InventoryClient.OpenCloseTimePosition - delta) -- not zero as that would cause issues with the math.ceil below, as it would make 100* InventoryClient.OpenCloseTimePosition/InventoryClient.OpenCloseTimePeriod = 0 which is not the first element in the array
				end

				-- the following pair of if statements feels kind of fucked but it should be fine
				if InventoryClient.OpenCloseTimePosition == 0.001 then
					-- when the inventory is fully closed, make the inventoryFrame invisible
					InventoryFrame.Visible = false
				else
					InventoryFrame.Visible = true
				end

				if InventoryClient.OpenCloseTimePosition == InventoryClient.OpenCloseTimePeriod then
					-- when the inventory is fully open, make the hotbar frame invisible
					HotbarFrame.Visible = false
					-- and the instructions visible
					InstructionTxtBox.Visible = true
					-- and only when the inventory is fully open will we make the inventory interactable
					if not InventoryFrame.Interactable then
						InventoryFrame.Interactable = true
					end
				else
					HotbarFrame.Visible = true

					InstructionTxtBox.Visible = false

					if InventoryFrame.Interactable then
						InventoryFrame.Interactable = false
					end
				end

				InventoryFrame.Position = UDim2.fromScale(
					InventoryFrame.Position.X.Scale,
					InventoryClient.YScaleEasingArray.Inventory[math.ceil(
						100 * InventoryClient.OpenCloseTimePosition / InventoryClient.OpenCloseTimePeriod
					)]
				)
				HotbarFrame.Position = UDim2.fromScale(
					HotbarFrame.Position.X.Scale,
					InventoryClient.YScaleEasingArray.Hotbar[math.ceil(
						100 * InventoryClient.OpenCloseTimePosition / InventoryClient.OpenCloseTimePeriod
					)]
				)

				-- Handle the dragging of items

				if InventoryClient.DraggingSlot then
					local DraggingSlotFrame: TextButton? = GetSlotFrame(InventoryClient.DraggingSlot)

					local DraggingImage: ImageLabel = DraggingOverlay:WaitForChild("DragImage")

					if not DraggingSlotFrame then
						error(
							"Error: SlotFrame for Slot"
								.. tostring(InventoryClient.DraggingSlot)
								.. " does not exist to be dragged"
						)
					end

					if DraggingImage then -- The SlotFrame still has the image so parent DraggingImage to the DraggingOverlay if it was not already done
						local itemSampleImage = ItemSample:WaitForChild("Image") :: ImageLabel

						DraggingImage.Size =
							UDim2.fromOffset(itemSampleImage.AbsoluteSize.X * 1.3, itemSampleImage.AbsoluteSize.Y * 1.3)
						DraggingImage.Position =
							UDim2.fromOffset(InventoryClient.MousePosition.X, InventoryClient.MousePosition.Y)
					else -- The slotFrame's image should be in the draggingOverlay
						error("Item image should be in the dragging overlay")
					end
				end
			end
		)
	end)
end

--Returning
return InventoryClient
