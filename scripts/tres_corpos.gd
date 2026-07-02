## tres_corpos.gd
##
## Cenário de validação com configurações clássicas do problema de três corpos:
##   LAGRANGE — triângulo equilátero girando rigidamente (solução L4/L5).
##   EULER    — três massas colineares girando em torno do centro de massa.

extends SimulacaoGlobal

enum Configuracao { LAGRANGE, EULER }

@export var configuracao: Configuracao = Configuracao.LAGRANGE
@export var massa_corpo: float = 1.0   ## M☉
@export var distancia: float = 2.0    ## UA: circunraio (Lagrange) ou meia-sep. (Euler)

const CORES := [Color(1.0, 0.5, 0.4), Color(0.5, 1.0, 0.6), Color(0.5, 0.7, 1.0)]
const RAIO_CORPO := 0.08


func _configurar_cenario() -> void:
	nome_cenario            = "Três Corpos — Lagrange" if configuracao == Configuracao.LAGRANGE else "Três Corpos — Euler"
	escala_tempo            = 0.5
	epsilon_softening       = 0.0
	distancia_camera_inicial = distancia * 4.0
	camera_distancia_maxima = distancia * 15.0

	if configuracao == Configuracao.LAGRANGE:
		_configurar_lagrange()
	else:
		_configurar_euler()


func _configurar_lagrange() -> void:
	var R: float     = distancia
	var omega: float = sqrt(G * massa_corpo / (sqrt(3.0) * R * R * R))
	for k in 3:
		var ang: float = deg_to_rad([90.0, 210.0, 330.0][k])
		var pos := Vector3(R * cos(ang), 0.0, R * sin(ang))
		var vel := omega * Vector3(-pos.z, 0.0, pos.x)
		instanciar_corpo(pos, massa_corpo, RAIO_CORPO, "Corpo %d" % (k + 1), vel, CORES[k])


func _configurar_euler() -> void:
	var d: float     = distancia
	var omega: float = sqrt(1.25 * G * massa_corpo / (d * d * d))
	var posicoes     := [Vector3(-d, 0.0, 0.0), Vector3.ZERO, Vector3(d, 0.0, 0.0)]
	for k in 3:
		var pos: Vector3 = posicoes[k]
		var vel := omega * Vector3(-pos.z, 0.0, pos.x)
		instanciar_corpo(pos, massa_corpo, RAIO_CORPO, "Corpo %d" % (k + 1), vel, CORES[k])
