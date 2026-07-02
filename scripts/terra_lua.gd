## terra_lua.gd
##
## Cenário "Sol–Terra–Lua": sistema hierárquico com os três corpos.
##
## A distância real Terra–Lua (0,00257 UA) é multiplicada por `fator_distancia_lua`
## (padrão 2). Com fator=2 a Lua fica a 0,00514 UA da Terra, dentro da esfera de
## influência terrestre (≈ 0,006 UA), então orbita a Terra corretamente.
## A velocidade orbital da Lua é recalculada nessa distância, mantendo a mecânica
## consistente. A câmera segue a Terra para mostrar a órbita lunar claramente.
##
## Nota: com fator muito maior (ex. 20, que foi o valor anterior) a Lua ficava fora
## da esfera de influência e passava a orbitar o Sol de forma independente.

extends SimulacaoGlobal

## Multiplica a distância real Terra–Lua (mantida dentro da esfera de influência).
## Padrão 10: Lua a 0,0257 UA da Terra (raios: Terra 0,005 + Lua 0,002 = 0,007 UA << 0,0257).
## Sem Sol, qualquer valor funciona; com Sol, manter abaixo de ~2 (SOI ≈ 0,006 UA).
@export var fator_distancia_lua: float = 10.0
## Inclui o Sol na simulação. Com Sol presente, a perturbação de 3 corpos combinada
## com o integrador de primeira ordem do Jolt desestabiliza a órbita lunar ao longo
## do tempo (ver seção 4.4 do artigo). Padrão false: mostra Terra+Lua corretamente.
@export var incluir_sol: bool = false


@onready var incluir_sol_button: Button = get_node_or_null("%IncluirSolButton")


func _ready() -> void:
	Engine.physics_ticks_per_second = 240
	super._ready()
	_atualizar_botao_sol()
	if incluir_sol_button:
		incluir_sol_button.pressed.connect(_on_incluir_sol_pressed)


func _exit_tree() -> void:
	Engine.physics_ticks_per_second = 60


func _on_incluir_sol_pressed() -> void:
	incluir_sol = not incluir_sol
	_reiniciar_cenario()
	_atualizar_botao_sol()


func _atualizar_botao_sol() -> void:
	if incluir_sol_button:
		incluir_sol_button.text = "Sol: %s" % ("Sim ☀" if incluir_sol else "Não  ○")


func _configurar_cenario() -> void:
	nome_cenario            = "Sol–Terra–Lua"
	escala_tempo            = 0.02
	epsilon_softening       = 0.0
	camera_distancia_minima = 0.001
	camera_distancia_maxima = 4.0

	var massa_sol: float   = UnidadesGravitacionais.massa_para_sim(DadosCorpos.SOL["massa_kg"])
	var massa_terra: float = UnidadesGravitacionais.massa_para_sim(DadosCorpos.TERRA["massa_kg"])
	var massa_lua: float   = UnidadesGravitacionais.massa_para_sim(DadosCorpos.LUA["massa_kg"])

	# Raios visuais reduzidos neste cenário para evitar que Jolt detecte sobreposição
	# entre Terra e Lua: a separação orbital é pequena (0,025 UA) e os raios padrão
	# do catálogo (0,030 + 0,010 = 0,040 UA) são maiores que essa distância.
	const R_TERRA_LOCAL: float = 0.010
	const R_LUA_LOCAL: float   = 0.005

	# fator_distancia_lua = 10 → Lua a 0,0257 UA da Terra; sem Sol não há esfera
	# de influência, então qualquer fator funciona enquanto r > R_Terra + R_Lua.
	var raio_lua: float = DadosCorpos.LUA["semieixo_ua"] * fator_distancia_lua

	var pos_terra := Vector3(1.0, 0.0, 0.0)
	var vel_terra := Vector3.ZERO

	if incluir_sol:
		instanciar_corpo(Vector3.ZERO, massa_sol,
			DadosCorpos.SOL["raio_visual"], "Sol",
			Vector3.ZERO, DadosCorpos.SOL["cor"], true)
		vel_terra = velocidade_orbital_circular(Vector3.ZERO, pos_terra, massa_sol)
	else:
		pos_terra = Vector3.ZERO

	instanciar_corpo(pos_terra, massa_terra, R_TERRA_LOCAL, "Terra",
		vel_terra, DadosCorpos.TERRA["cor"])

	var pos_lua      := pos_terra + Vector3(raio_lua, 0.0, 0.0)
	var vel_lua_rel: float = velocidade_circular(massa_terra, raio_lua)
	var vel_lua      := vel_terra + Vector3(0.0, 0.0, vel_lua_rel)

	instanciar_corpo(pos_lua, massa_lua, R_LUA_LOCAL, "Lua",
		vel_lua, DadosCorpos.LUA["cor"])

	indice_camera_inicial    = 1 if incluir_sol else 0
	distancia_camera_inicial = raio_lua * 8.0
