local Types = {}

export type StackData =
	{
		Item: string,
		Count: number,
	}
	| {
		Item: UniqueItemData,
	}

export type Armor = {
	Head: number?,
	Torso: number?,
	Legs: number?,
}

export type Inventory = {
	Grid: { [number]: { [number]: StackData } },
	Armor: Armor,
}

export type GridPosition = {
	x: number,
	y: number,

	__eq: (a: GridPosition, b: GridPosition) -> boolean,
	__tostring: (self: GridPosition) -> string,
}

export type InventoryUpdateInfo =
	{
		Type: "Move",
		startPos: GridPosition,
		endPos: GridPosition,
		moveCount: number,
	}
	| {
		Type: "Swap",
		APos: GridPosition,
		BPos: GridPosition,
	}
	| {
		Type: "Add",
		itemsToAdd: StackData,
		targetGridPos: GridPosition?,
	}
	| {
		Type: "Remove",
		itemsToRemove: StackData,
		targetGridPos: GridPosition?,
	}

export type InventoryVersionData = {
	VersionNumber: number,
	InventoryData: Inventory,
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
