## sistema_solar.gd
##
## Cenário "Sistema Solar": planetas nas distâncias reais em UA com massas reais
## em M☉ e velocidade tangencial V = √(G·M☉/r) — órbita circular correta sem
## nenhum multiplicador arbitrário. O Sol emite um OmniLight3D.
##
## Além do painel comum, exibe informações orbitais do planeta selecionado:
## distância ao Sol, período (vis-viva), tempo restante para completar a órbita
## atual e excentricidade — calculadas a partir do estado (posição/velocidade).

extends SimulacaoGlobal


## Referência ao Sol (corpo central) para os cálculos orbitais.
var corpo_sol: RigidBody3D

## Ângulo orbital acumulado (rad) por corpo, medido em torno do Sol no plano XZ.
## Usado para estimar a fração da órbita já percorrida.
var angulo_acumulado: Dictionary = {}
var angulo_anterior: Dictionary = {}

# ─── Labels de órbita (existem apenas em sistema-solar.tscn) ──────────────────
@onready var orbita_dist_label: Label     = get_node_or_null("%OrbitaDist")
@onready var orbita_periodo_label: Label  = get_node_or_null("%OrbitaPeriodo")
@onready var orbita_restante_label: Label = get_node_or_null("%OrbitaRestante")
@onready var orbita_excent_label: Label   = get_node_or_null("%OrbitaExcent")


func _configurar_cenario() -> void:
	nome_cenario            = "Sistema Solar"
	escala_tempo            = 0.02      # 1 s real ≈ 7,3 dias simulados; 1 órbita da Terra ≈ 50 s
	epsilon_softening       = 0.0
	distancia_camera_inicial = 7.0      # câmera próxima o suficiente para ver os planetas internos
	camera_distancia_minima = 0.2
	camera_distancia_maxima = 55.0

	angulo_acumulado.clear()
	angulo_anterior.clear()

	var massa_sol: float = UnidadesGravitacionais.massa_para_sim(DadosCorpos.SOL["massa_kg"])

	for dados in DadosCorpos.PLANETAS:
		var massa: float    = UnidadesGravitacionais.massa_para_sim(dados["massa_kg"])
		var raio: float     = float(dados["raio_visual"])
		var nome: String    = String(dados["nome"])
		var cor: Color      = dados.get("cor", Color.WHITE)
		var semieixo: float = float(dados["semieixo_ua"])
		var luz: bool       = dados.get("emite_luz", false)

		if semieixo <= 0.0:
			corpo_sol = instanciar_corpo(Vector3.ZERO, massa, raio, nome, Vector3.ZERO, cor, luz)
		else:
			var pos := Vector3(semieixo, 0.0, 0.0)
			var vel := velocidade_orbital_circular(Vector3.ZERO, pos, massa_sol)
			instanciar_corpo(pos, massa, raio, nome, vel, cor, luz)


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_rastrear_angulos()


## Acumula o ângulo varrido por cada planeta em torno do Sol (plano XZ),
## tratando a descontinuidade de atan2 em ±π com wrapf.
func _rastrear_angulos() -> void:
	if corpo_sol == null or not is_instance_valid(corpo_sol):
		return
	var centro: Vector3 = corpo_sol.global_position
	for corpo in corpo_array:
		if corpo == corpo_sol or not is_instance_valid(corpo):
			continue
		var rel: Vector3 = corpo.global_position - centro
		var ang: float = atan2(rel.z, rel.x)
		if angulo_anterior.has(corpo):
			var d: float = wrapf(ang - angulo_anterior[corpo], -PI, PI)
			angulo_acumulado[corpo] = angulo_acumulado.get(corpo, 0.0) + d
		else:
			angulo_acumulado[corpo] = 0.0
		angulo_anterior[corpo] = ang


## Calcula e exibe os parâmetros orbitais do planeta selecionado a partir do
## estado (posição/velocidade), usando a equação vis-viva e o vetor de Laplace.
func _atualizar_info_orbital(corpo: RigidBody3D) -> void:
	if corpo == corpo_sol or corpo_sol == null or not is_instance_valid(corpo_sol):
		_limpar_labels_orbita()
		return

	var mu: float = G * corpo_sol.mass                    # μ = G·M☉
	var rel: Vector3 = corpo.global_position - corpo_sol.global_position
	var r: float = rel.length()
	if r <= 0.0 or mu <= 0.0:
		_limpar_labels_orbita()
		return

	var vel_vec: Vector3 = corpo.linear_velocity / _get_tau()   # velocidade física (UA/ano)
	var v: float = vel_vec.length()

	# Equação vis-viva: v² = μ·(2/r − 1/a)  →  1/a = 2/r − v²/μ
	var inv_a: float = 2.0 / r - (v * v) / mu
	var texto_periodo: String = "—"
	var texto_restante: String = "—"
	if inv_a > 0.0:                                       # órbita ligada (elíptica)
		var a: float = 1.0 / inv_a
		var periodo: float = TAU * sqrt(a * a * a / mu)   # 3ª lei de Kepler
		texto_periodo = "%.3f anos" % periodo
		var progresso: float = fposmod(angulo_acumulado.get(corpo, 0.0), TAU) / TAU
		texto_restante = "%.3f anos" % ((1.0 - progresso) * periodo)

	# Excentricidade pelo vetor de Laplace-Runge-Lenz:
	# e_vec = ((v² − μ/r)·r_vec − (r_vec·v_vec)·v_vec) / μ
	var e_vec: Vector3 = ((v * v - mu / r) * rel - rel.dot(vel_vec) * vel_vec) / mu
	var e: float = e_vec.length()

	if orbita_dist_label:
		orbita_dist_label.text = "Dist. Sol: %.3f UA" % r
	if orbita_periodo_label:
		orbita_periodo_label.text = "Período: %s" % texto_periodo
	if orbita_restante_label:
		orbita_restante_label.text = "Falta p/ órbita: %s" % texto_restante
	if orbita_excent_label:
		orbita_excent_label.text = "Excentricidade: %.3f" % e


func _limpar_labels_orbita() -> void:
	if orbita_dist_label:
		orbita_dist_label.text = "Dist. Sol: —"
	if orbita_periodo_label:
		orbita_periodo_label.text = "Período: —"
	if orbita_restante_label:
		orbita_restante_label.text = "Falta p/ órbita: —"
	if orbita_excent_label:
		orbita_excent_label.text = "Excentricidade: —"
