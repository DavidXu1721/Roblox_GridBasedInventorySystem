local Types = {}

export type StackData =
	{
		Item: string,
		Count: number,
	}
	| {
		Item: UniqueItemData,
		Count: nil,
	}

export type Armor = {
	Head: number?,
	Torso: number?,
	Legs: number?,
}

export type Inventory = {
	Grid: { [number]: { [number]: StackData? } },
	Armor: Armor,
}

export type GridPosition = typeof(setmetatable({} :: { x: number, y: number }, {} :: any))

export type InventoryMoveData = {
	startPos: GridPosition,
	endPos: GridPosition,
	moveCount: number,
}

export type InventorySwapData = {
	APos: GridPosition,
	BPos: GridPosition,
}

export type InventoryAddData = {
	itemsToAdd: StackData?,
	targetGridPos: GridPosition?,
}

export type InventoryRemoveData = {
	itemsToRemove: StackData?,
	targetGridPos: GridPosition?,
}

export type InventoryUpdateInfo =
	{
		Type: "Move",
		Data: InventoryMoveData,
	}
	| {
		Type: "Swap",
		Data: InventorySwapData,
	}
	| {
		Type: "Add",
		Data: InventoryAddData,
	}
	| {
		Type: "Remove",
		Data: InventoryRemoveData,
	}

export type InventoryVersionHistoryData = {
	VersionNumber: number?,
	LastUpdate: InventoryUpdateInfo,
}

export type ItemConfig = {
	Name: string,
	Id: string?,
	IconId: string?,
	Description: string?,
	ItemType: string,
	IsDroppable: boolean,
	ItemStats: { string: any }?,
}

export type UniqueItemData = {
	Id: string,
	UniqueId: string,
	ItemStats: { string: any },
}

return Types
