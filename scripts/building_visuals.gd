## Visual building methods for VillageBuilding
## Handles all rendering, materials, and visual generation

extends Node


## Refresh visual state and labels
func refresh_visual_state(building: VillageBuilding) -> void:
	building._apply_visual()
	building._update_label()


## Get localized building type name
func get_type_name(building_type: int) -> String:
	match building_type:
		VillageBuilding.BuildingType.TOWN_HALL:
			return "Refuge"
		VillageBuilding.BuildingType.GOLD_MINE:
			return "Scierie"
		VillageBuilding.BuildingType.ELIXIR_COLLECTOR:
			return "Carrière"
		VillageBuilding.BuildingType.CANNON:
			return "Tourelle"
		VillageBuilding.BuildingType.BARRACKS:
			return "Abri"
		VillageBuilding.BuildingType.GOLD_STORAGE:
			return "Entrepôt"
		VillageBuilding.BuildingType.ELIXIR_STORAGE:
			return "Forge"
		VillageBuilding.BuildingType.FARM:
			return "Potager"
		VillageBuilding.BuildingType.DOOR:
			return "Porte"
		VillageBuilding.BuildingType.PATH:
			return "Chemin"
		VillageBuilding.BuildingType.WORKSHOP:
			return "Atelier"
		VillageBuilding.BuildingType.GUARD_TOWER:
			return "Tour"
		VillageBuilding.BuildingType.DEFENSIVE_WALL:
			return "Mur"
	return "?"


## Create a StandardMaterial3D with specified color
func create_material(color: Color, roughness: float = 0.82, metallic: float = 0.04) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	return m


## Add a box mesh to parent
func add_box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)


## Add a cylinder mesh to parent
func add_cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, mat: Material, rot: Vector3 = Vector3.ZERO) -> void:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = height
	mi.mesh = cyl
	mi.material_override = mat
	mi.position = pos
	mi.rotation_degrees = rot
	parent.add_child(mi)
