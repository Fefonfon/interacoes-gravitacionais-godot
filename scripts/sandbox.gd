## sandbox.gd
##
## Modo "Sandbox": exploração livre com corpos instanciados pelo usuário.
## epsilon_softening > 0 limita a força gravitacional quando dois corpos se
## aproximam muito, evitando que ultrapassem uns aos outros ou sejam ejetados
## a velocidades absurdas após um encontro próximo.

extends SimulacaoGlobal


func _configurar_cenario() -> void:
	nome_cenario            = "Sandbox"
	escala_tempo            = 1.0
	epsilon_softening       = 0.4
	distancia_camera_inicial = 15.0
	camera_distancia_maxima = 120.0
	raio_spawn              = 5.0
	raio_minimo_colisao     = 1.0
	fator_raio_visual       = 3.0     # corpos exagerados para visibilidade de demonstração

	instanciar_multiplos(1)
