extends Node3D
class_name Line3D

# Lightweight line rendering for Godot versions without built-in Line3D.

var width: float = 0.05:
	set(value):
		_width = value
		_apply_line_width()

var material_override: Material:
	set(value):
		_material_override = value
		if _mesh_instance != null and is_instance_valid(_mesh_instance):
			_mesh_instance.material_override = value
		_apply_line_width()
	get:
		return _material_override

var _material_override: Material
var _mesh_instance: MeshInstance3D
var _mesh: ImmediateMesh
var _points: PackedVector3Array = []
var _width: float = 0.05

func _ready() -> void:
	_ensure_mesh()

func add_point(point: Vector3) -> void:
	_ensure_mesh()
	_points.append(point)
	_rebuild()

func clear_points() -> void:
	_points.clear()
	_rebuild()

func _ensure_mesh() -> void:
	if _mesh_instance != null and is_instance_valid(_mesh_instance):
		return
	_mesh = ImmediateMesh.new()
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh = _mesh
	if _material_override != null:
		_mesh_instance.material_override = _material_override
	add_child(_mesh_instance)
	_apply_line_width()

func _apply_line_width() -> void:
	if _material_override == null:
		return
	for prop in _material_override.get_property_list():
		if prop.name == "line_width":
			_material_override.set("line_width", _width)
			return

func _rebuild() -> void:
	if _mesh == null:
		return
	_mesh.clear_surfaces()
	if _points.size() < 2:
		return
	_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for p in _points:
		_mesh.surface_add_vertex(p)
	_mesh.surface_end()
