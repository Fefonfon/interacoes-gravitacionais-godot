## figura_oito.gd
##
## Cenário de validação: coreografia "figura oito" de três corpos iguais
## (Chenciner–Montgomery). Solução periódica e estável do problema de 3 corpos.

extends SimulacaoGlobal


func _configurar_cenario() -> void:
	nome_cenario            = "Figura-Oito"
	G                       = 1.0
	escala_tempo            = 0.6
	epsilon_softening       = 0.0
	distancia_camera_inicial = 4.0
	camera_distancia_minima = 0.5
	camera_distancia_maxima = 20.0

	var m: float   = 1.0
	var raio: float = 0.06

	instanciar_corpo(
		Vector3(-0.97000436, 0.0, 0.24308753), m, raio, "Corpo A",
		Vector3(0.46620368, 0.0, 0.43236573), Color(1.0, 0.45, 0.45))
	instanciar_corpo(
		Vector3(0.97000436, 0.0, -0.24308753), m, raio, "Corpo B",
		Vector3(0.46620368, 0.0, 0.43236573), Color(0.45, 1.0, 0.55))
	instanciar_corpo(
		Vector3.ZERO, m, raio, "Corpo C",
		Vector3(-0.93240737, 0.0, -0.86473146), Color(0.5, 0.6, 1.0))
