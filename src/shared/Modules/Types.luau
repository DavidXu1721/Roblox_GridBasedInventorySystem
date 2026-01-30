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

export type InventoryUpdateInfo =
	{
		Type: "Move",
		Data: {
			startPos: GridPosition,
			endPos: GridPosition,
			moveCount: number,
		},
	}
	| {
		Type: "Swap",
		Data: {
			APos: GridPosition,
			BPos: GridPosition,
		},
	}
	| {
		Type: "Add",
		Data: {
			itemsToAdd: StackData,
			targetGridPos: GridPosition?,
		},
	}
	| {
		Type: "Remove",
		Data: {
			itemsToRemove: StackData,
			targetGridPos: GridPosition?,
		},
	}

export type InventoryVersionHistoryData = {
	VersionNumber: number?,
	LastUpdate: InventoryUpdateInfo,
}

export type ItemConfig = {
	Name: string,
	Id: string,
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
