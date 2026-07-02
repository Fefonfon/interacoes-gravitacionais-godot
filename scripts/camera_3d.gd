extends Camera3D

var follow_target: Node3D
var look_target: Node3D

## Fator de zoom por passo do scroll (0.15 = 15% da distância atual). Zoom
## proporcional funciona a qualquer escala: 15% de 50 UA ≈ 7,5 UA; 15% de 0,03
## UA ≈ 0,0045 UA — útil tanto no Sistema Solar quanto no cenário Terra–Lua.
@export var zoom_fator: float = 0.15
@export var min_distance: float = 0.5
@export var max_distance: float = 80.0
@export var orbit_sensitivity: float = 0.008
@export var follow_smooth: float = 8.0

var yaw: float = 0.0
var pitch: float = -0.3
var distance_to_target: float = 18.0
var orbitando: bool = false


func _ready() -> void:
	yaw = rotation.y
	pitch = clamp(rotation.x, -1.2, 1.2)


func set_follow_target(target: Node3D) -> void:
	follow_target = target


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance_to_target = max(min_distance, distance_to_target * (1.0 - zoom_fator))
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance_to_target = min(max_distance, distance_to_target * (1.0 + zoom_fator))
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			orbitando = true

	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_MIDDLE:
		orbitando = false

	if event is InputEventMouseMotion and orbitando:
		yaw -= event.relative.x * orbit_sensitivity
		pitch = clamp(pitch + event.relative.y * orbit_sensitivity, -1.4, 1.4)


func _process(delta: float) -> void:
	if follow_target != null and is_instance_valid(follow_target):
		var alvo: Vector3 = follow_target.global_position
		var offset := Vector3(
			cos(pitch) * sin(yaw),
			sin(pitch),
			cos(pitch) * cos(yaw)
		) * distance_to_target
		var destino: Vector3 = alvo + offset
		var t: float = clamp(delta * follow_smooth, 0.0, 1.0)
		global_position = global_position.lerp(destino, t)
		look_at(alvo)
		return

	if look_target != null and is_instance_valid(look_target):
		look_at(look_target.global_position)
