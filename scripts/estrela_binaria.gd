## estrela_binaria.gd
##
## Cenário "Estrela Binária": duas estrelas em órbita mútua em torno do baricentro
## comum, com um planeta circumbinário opcional em órbita estável a R >> separação.

extends SimulacaoGlobal

@export var massa1: float = 1.0
@export var massa2: float = 0.6
@export var separacao: float = 2.0
@export var incluir_planeta: bool = true
@export var raio_orbita_planeta: float = 8.0


func _configurar_cenario() -> void:
	nome_cenario            = "Estrela Binária"
	escala_tempo            = 0.4
	epsilon_softening       = 0.0
	distancia_camera_inicial = raio_orbita_planeta * 2.5 if incluir_planeta else separacao * 5.0
	camera_distancia_maxima = 120.0

	var massa_total: float = massa1 + massa2
	var r1: float  = separacao * massa2 / massa_total
	var r2: float  = separacao * massa1 / massa_total
	var omega: float = sqrt(G * massa_total / (separacao * separacao * separacao))

	var pos1 := Vector3(-r1, 0.0, 0.0)
	var pos2 := Vector3(r2, 0.0, 0.0)

	instanciar_corpo(pos1, massa1, 0.15, "Estrela A",
		omega * Vector3(-pos1.z, 0.0, pos1.x), Color(1.0, 0.85, 0.4))
	instanciar_corpo(pos2, massa2, 0.12, "Estrela B",
		omega * Vector3(-pos2.z, 0.0, pos2.x), Color(1.0, 0.55, 0.3))

	if incluir_planeta:
		var pos_p := Vector3(raio_orbita_planeta, 0.0, 0.0)
		var vel_p := velocidade_orbital_circular(Vector3.ZERO, pos_p, massa_total)
		instanciar_corpo(pos_p, 3.0e-6, 0.04, "Planeta", vel_p, Color(0.4, 0.6, 1.0))
