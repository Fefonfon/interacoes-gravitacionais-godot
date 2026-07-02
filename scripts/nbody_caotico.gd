## nbody_caotico.gd
##
## Cenário "N-corpos Caótico": corpos com massas, posições e velocidades aleatórias.
## Demonstra o caráter caótico deterministico do problema de N-corpos (N > 2).

extends SimulacaoGlobal

@export var num_corpos: int = 10
@export var massa_min: float = 0.2
@export var massa_max: float = 1.5
@export var velocidade_inicial_max: float = 1.5


func _configurar_cenario() -> void:
	nome_cenario            = "N-Corpos Caótico"
	raio_spawn              = 5.0
	raio_minimo_colisao     = 0.8
	escala_tempo            = 0.5
	epsilon_softening       = 0.0
	distancia_camera_inicial = raio_spawn * 3.0
	camera_distancia_maxima = 120.0

	for i in num_corpos:
		var pos   := _posicao_livre()
		var massa: float = randf_range(massa_min, massa_max)
		var raio: float  = lerpf(0.06, 0.16, (massa - massa_min) / maxf(massa_max - massa_min, 0.001))
		var vel   := Vector3(
			randf_range(-velocidade_inicial_max, velocidade_inicial_max),
			0.0,
			randf_range(-velocidade_inicial_max, velocidade_inicial_max))
		instanciar_corpo(pos, massa, raio, "Corpo %d" % (i + 1),
			vel, Color.from_hsv(randf(), 0.6, 1.0))


func _posicao_livre() -> Vector3:
	for _t in 60:
		var pos := Vector3(
			randf_range(-raio_spawn, raio_spawn),
			randf_range(-raio_spawn, raio_spawn),
			randf_range(-raio_spawn, raio_spawn))
		if not checar_colisao(pos, raio_minimo_colisao):
			return pos
	return Vector3(randf_range(-raio_spawn, raio_spawn), 0.0, randf_range(-raio_spawn, raio_spawn))
