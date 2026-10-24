class_name ForgeRecipe
extends RefCounted

static func can_craft(materials: Dictionary, requirements: Dictionary) -> bool:
	if requirements.is_empty():
		return false
	for material in requirements:
		if requirements[material] <= 0 or materials.get(material, 0) < requirements[material]:
			return false
	return true
