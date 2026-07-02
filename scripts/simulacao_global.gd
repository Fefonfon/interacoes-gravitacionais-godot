## simulacao_global.gd
##
## Classe base de todas as cenas de simulação gravitacional. Concentra a lógica
## comum: gerenciamento dos corpos, cálculo das forças de N-corpos, traçado de
## trajetórias, interface e câmera. Cada cenário estende esta classe e implementa
## apenas `_configurar_cenario()`.
##
## Sistema de unidades (ver UnidadesGravitacionais):
##   posição em UA · massa em M☉ · tempo em ano · G ≈ 39,48.
##
## Integração: forças calculadas em GDScript via `apply_central_force`; o motor
## Jolt Physics realiza a integração temporal (Euler semi-implícito) e as colisões.

extends Node3D
class_name SimulacaoGlobal


# ─── Parâmetros de simulação (@export → ajustáveis por cenário no Inspector) ──

## Constante gravitacional. Padrão ≈ 39,48 para UA/M☉/ano; cenários abstratos
## (ex.: Figura-oito) podem usar G = 1.
@export var G: float = UnidadesGravitacionais.G

## Escala de tempo base τ: anos de simulação por segundo real.
## Controla a velocidade de reprodução de forma dimensionalmente consistente
## (força ∝ τ², velocidade inicial ∝ τ). Valores menores = simulação mais lenta.
@export var escala_tempo: float = 1.0

## Fator de suavização ε (softening) em UA. Padrão 0 (Newton puro): a
## singularidade r→0 já é evitada pelas colisões de raio finito do Jolt.
## Use ε > 0 no Sandbox para limitar forças extremas em encontros próximos.
@export var epsilon_softening: float = 0.0

@export var distancia_camera_inicial: float = 18.0
@export var camera_distancia_minima: float = 0.5
@export var camera_distancia_maxima: float = 80.0
@export var trajetoria_distancia_minima: float = 0.05
@export var trajetoria_largura: float = 0.02
@export var raio_spawn: float = 5.0
@export var raio_minimo_colisao: float = 0.5

## Multiplica o raio visual/colisão de todos os corpos instanciados neste cenário.
## Use > 1 em cenários onde a escala real (UA) torna os corpos invisíveis para fins
## de demonstração (ex.: Sandbox, Terra-Lua sem Sol).
@export var fator_raio_visual: float = 1.0


## Tempo de simulação acumulado (em anos). Incrementado a cada tick de física.
var tempo_simulacao: float = 0.0

## Nome do cenário exibido na interface (definido em _configurar_cenario).
var nome_cenario: String = "Simulação"

## Índice do corpo que a câmera segue ao iniciar.
var indice_camera_inicial: int = 0


# ─── Constantes e estado interno ──────────────────────────────────────────────
const CENA_CORPO: PackedScene = preload("res://corpo.tscn")
const CENA_MENU: String = "res://menu_principal.tscn"

# ─── Fundo estelar (céu de "espaço sideral") ─────────────────────────────────
const FUNDO_COR: Color = Color(0.01, 0.012, 0.02)  ## cor do espaço (quase preto)
const FUNDO_TEX_LARGURA: int = 2048   ## resolução equiretangular da textura do céu
const FUNDO_TEX_ALTURA: int = 1024
const FUNDO_NUM_ESTRELAS: int = 1100
const FUNDO_SEED: int = 20260616      ## seed fixa → todos os cenários veem o mesmo céu
const RAIO_BASE: float = 0.5  ## raio da esfera em corpo.tscn sem escala aplicada

## 1 massa terrestre em M☉ — usada para exibir massas pequenas (planetas) de forma
## legível ("M⊕") em vez de notação científica em massas solares.
const MASSA_TERRA_MSOL: float = 5.972e24 / UnidadesGravitacionais.M_UNIT
## Faixa do slider de massa (escala log₁₀, em M☉): 10⁻⁸ a 10¹.
const MASSA_LOG_MIN: float = -8.0
const MASSA_LOG_MAX: float = 1.0

var corpo_array: Array[RigidBody3D] = []
var corpo_select: int = 0

var trajetoria_root: Node3D
var trajetoria_linhas: Dictionary = {}
var trajetoria_ultimo_ponto: Dictionary = {}

var catalogo: Array[Dictionary] = DadosCorpos.PLANETAS
var massa_select: float = 1.0
var raio_select: float = 0.1
var nome_select: String = "Corpo"
var cor_select: Color = Color.WHITE


# ─── Referências de UI (nomes únicos na cena, sintaxe %) ──────────────────────
@onready var camera_3d: Camera3D = get_node_or_null("Camera3D")
@onready var num_corpos_label: Label       = get_node_or_null("%NumCorpos")
@onready var tempo_label: Label            = get_node_or_null("%TempoSimulacao")
@onready var pos_corpo_label: Label        = get_node_or_null("%PosCorpo")
@onready var pos_corpox_label: Label       = get_node_or_null("%PosCorpox")
@onready var pos_corpoy_label: Label       = get_node_or_null("%PosCorpoy")
@onready var pos_corpoz_label: Label       = get_node_or_null("%PosCorpoz")
@onready var lista_corpos: ItemList        = get_node_or_null("%ListaCorpos")
@onready var novo_corpo_button: Button     = get_node_or_null("%NovoCorpo")
@onready var massa_option: OptionButton    = get_node_or_null("%MassaCorpo")
@onready var nome_cenario_label: Label     = get_node_or_null("%NomeCenario")
@onready var massa_info_label: Label       = get_node_or_null("%MassaInfo")
@onready var diametro_info_label: Label    = get_node_or_null("%DiametroInfo")
@onready var vel_info_label: Label         = get_node_or_null("%VelInfo")
@onready var massa_slider: HSlider         = get_node_or_null("%MassaSlider")
@onready var massa_slider_valor: Label     = get_node_or_null("%MassaSliderValor")


# ═══════════════════════════════════════════════════════════════════════════════
#  HELPERS DE TEMPO
# ═══════════════════════════════════════════════════════════════════════════════

func _get_tau() -> float:
	return escala_tempo


# ═══════════════════════════════════════════════════════════════════════════════
#  CICLO DE VIDA
# ═══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_configurar_fundo_estelar()  # fundo de espaço sideral, comum a todos os cenários
	_popular_opcoes_massa()
	_configurar_cenario()        # cada cenário define corpos, escala_tempo, etc.

	_conectar_interface()
	_inicializar_camera()
	_atualizar_contador_corpos()

	if nome_cenario_label:
		nome_cenario_label.text = nome_cenario
	if pos_corpo_label:
		pos_corpo_label.text = "Corpo selecionado"


## Cria por código o fundo de "espaço sideral" (céu escuro com estrelas), comum a
## todos os cenários. Roda antes de _configurar_cenario() para existir desde o início.
##
## A textura do céu é gerada UMA ÚNICA VEZ (bake) e usada como PanoramaSky, então o
## fundo é totalmente estável ao orbitar/dar zoom. O céu fica em PROCESS_MODE_REALTIME
## para evitar o artefato do cubemap incremental (estrelas que "somem" durante o
## movimento da câmera e só reaparecem quando ela para).
func _configurar_fundo_estelar() -> void:
	var pano := PanoramaSkyMaterial.new()
	pano.panorama = _gerar_textura_estrelas()
	var ceu := Sky.new()
	ceu.sky_material = pano
	ceu.process_mode = Sky.PROCESS_MODE_REALTIME
	ceu.radiance_size = Sky.RADIANCE_SIZE_1024  # estrelas nítidas se o fundo vier do cubemap
	var ambiente := Environment.new()
	ambiente.background_mode = Environment.BG_SKY
	ambiente.sky = ceu
	# Preserva a aparência atual dos corpos (iluminados pela própria emissão):
	# não adicionar luz ambiente vinda do céu.
	ambiente.ambient_light_source = Environment.AMBIENT_SOURCE_DISABLED
	var we := WorldEnvironment.new()
	we.environment = ambiente
	add_child(we)


## Gera (uma vez) uma textura equiretangular de céu estrelado: fundo escuro com pontos
## brilhantes distribuídos uniformemente na esfera celeste. Determinística (seed fixa).
func _gerar_textura_estrelas() -> ImageTexture:
	var img := Image.create(FUNDO_TEX_LARGURA, FUNDO_TEX_ALTURA, true, Image.FORMAT_RGBA8)
	img.fill(FUNDO_COR)
	var rng := RandomNumberGenerator.new()
	rng.seed = FUNDO_SEED
	for _i in FUNDO_NUM_ESTRELAS:
		# Direção uniforme na esfera → coordenadas equiretangulares (lon × lat).
		var lon: float = rng.randf()
		var lat: float = acos(rng.randf_range(-1.0, 1.0)) / PI  # cos(colatitude) uniforme
		var px: int = int(lon * float(FUNDO_TEX_LARGURA))
		var py: int = int(lat * float(FUNDO_TEX_ALTURA))
		_plotar_estrela(img, px, py, rng.randf_range(0.45, 1.0))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## Desenha uma estrela na imagem: núcleo brilhante com bordas suaves (aditivo, com
## envolvimento horizontal para não criar costura na textura equiretangular).
func _plotar_estrela(img: Image, cx: int, cy: int, brilho: float) -> void:
	var l: int = img.get_width()
	var a: int = img.get_height()
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var peso: float = 1.0 if (dx == 0 and dy == 0) else 0.25
			var x: int = ((cx + dx) % l + l) % l
			var y: int = clampi(cy + dy, 0, a - 1)
			var c: Color = img.get_pixel(x, y)
			var v: float = brilho * peso
			img.set_pixel(x, y, Color(min(c.r + v, 1.0), min(c.g + v, 1.0), min(c.b + v, 1.0), 1.0))


## Sobrescrito por cada cenário para instanciar seus corpos. A base não cria nada.
func _configurar_cenario() -> void:
	pass


## Limpa todos os corpos e trajetórias e reconfigura o cenário do zero.
## Útil para botões de reinício sem recarregar a cena inteira.
func _reiniciar_cenario() -> void:
	for corpo in corpo_array:
		if is_instance_valid(corpo):
			corpo.queue_free()
	corpo_array.clear()
	for linha in trajetoria_linhas.values():
		if is_instance_valid(linha):
			linha.queue_free()
	trajetoria_linhas.clear()
	trajetoria_ultimo_ponto.clear()
	if lista_corpos:
		lista_corpos.clear()
	tempo_simulacao = 0.0
	_configurar_cenario()
	_inicializar_camera()
	if nome_cenario_label:
		nome_cenario_label.text = nome_cenario


func _conectar_interface() -> void:
	if novo_corpo_button and not novo_corpo_button.pressed.is_connected(_on_novo_corpo_pressed):
		novo_corpo_button.pressed.connect(_on_novo_corpo_pressed)
	if lista_corpos and not lista_corpos.item_selected.is_connected(_on_lista_corpos_item_selected):
		lista_corpos.item_selected.connect(_on_lista_corpos_item_selected)
	if massa_option and not massa_option.item_selected.is_connected(_on_massa_item_selected):
		massa_option.item_selected.connect(_on_massa_item_selected)
	if massa_slider:
		massa_slider.min_value = MASSA_LOG_MIN
		massa_slider.max_value = MASSA_LOG_MAX
		massa_slider.step = 0.01
		if not massa_slider.value_changed.is_connected(_on_massa_slider_changed):
			massa_slider.value_changed.connect(_on_massa_slider_changed)
	var btn_menu: Button = get_node_or_null("%SairParaMenu")
	if btn_menu and not btn_menu.pressed.is_connected(_on_menu_pressed):
		btn_menu.pressed.connect(_on_menu_pressed)


func _popular_opcoes_massa() -> void:
	if massa_option == null:
		return
	massa_option.clear()
	for dados in catalogo:
		var m: float = UnidadesGravitacionais.massa_para_sim(dados["massa_kg"])
		massa_option.add_item("%s | %s M☉" % [dados["nome"], m])
	if not catalogo.is_empty():
		massa_option.select(0)
		_on_massa_item_selected(0)


func _inicializar_camera() -> void:
	if camera_3d == null:
		return
	if "min_distance" in camera_3d:
		camera_3d.min_distance = camera_distancia_minima
	if "max_distance" in camera_3d:
		camera_3d.max_distance = camera_distancia_maxima
	if "distance_to_target" in camera_3d:
		camera_3d.distance_to_target = distancia_camera_inicial
	if corpo_array.is_empty():
		return
	var idx: int = clampi(indice_camera_inicial, 0, corpo_array.size() - 1)
	_selecionar_corpo(idx)


# ═══════════════════════════════════════════════════════════════════════════════
#  CALLBACKS DA INTERFACE
# ═══════════════════════════════════════════════════════════════════════════════

func _on_massa_item_selected(index: int) -> void:
	if index < 0 or index >= catalogo.size():
		return
	var dados: Dictionary = catalogo[index]
	massa_select = UnidadesGravitacionais.massa_para_sim(dados["massa_kg"])
	raio_select  = dados["raio_visual"]
	nome_select  = dados["nome"]
	cor_select   = dados.get("cor", Color.WHITE)


func _on_lista_corpos_item_selected(index: int) -> void:
	_selecionar_corpo(index)


func _on_novo_corpo_pressed() -> void:
	instanciar_multiplos(1)
	if corpo_array.is_empty():
		return
	_selecionar_corpo(corpo_array.size() - 1)


## Ajusta a massa do corpo selecionado ao vivo (escala log₁₀, em M☉).
## Não altera os valores iniciais do cenário — só a massa do corpo atual.
func _on_massa_slider_changed(valor: float) -> void:
	if corpo_select < 0 or corpo_select >= corpo_array.size():
		return
	var corpo: RigidBody3D = corpo_array[corpo_select]
	if not is_instance_valid(corpo):
		return
	var nova_massa: float = pow(10.0, valor)
	corpo.mass = nova_massa
	if massa_slider_valor:
		massa_slider_valor.text = _fmt_massa(nova_massa)
	if massa_info_label:
		massa_info_label.text = "M: %s" % _fmt_massa(nova_massa)


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file(CENA_MENU)


# ═══════════════════════════════════════════════════════════════════════════════
#  SELEÇÃO DE CORPO (lista, clique do mouse, novo corpo)
# ═══════════════════════════════════════════════════════════════════════════════

## Seleciona o corpo de índice `index`: centraliza a câmera nele, marca-o na lista
## e atualiza todo o painel (posição, massa, diâmetro, velocidade, órbita).
## Ponto único de entrada para seleção por lista, clique do mouse ou novo corpo.
func _selecionar_corpo(index: int) -> void:
	if index < 0 or index >= corpo_array.size():
		return
	var corpo: RigidBody3D = corpo_array[index]
	if not is_instance_valid(corpo):
		return
	corpo_select = index
	if camera_3d and camera_3d.has_method("set_follow_target"):
		camera_3d.set_follow_target(corpo)
	if lista_corpos:
		lista_corpos.select(index)   # select() não emite item_selected (sem recursão)
	_sincronizar_slider_massa(corpo)
	_atualizar_painel_corpo(corpo)


## Posiciona o slider de massa no valor atual do corpo, sem disparar o sinal.
func _sincronizar_slider_massa(corpo: RigidBody3D) -> void:
	if massa_slider == null:
		return
	var lv: float = clampf(_log10(maxf(corpo.mass, 1e-12)), MASSA_LOG_MIN, MASSA_LOG_MAX)
	massa_slider.set_value_no_signal(lv)
	if massa_slider_valor:
		massa_slider_valor.text = _fmt_massa(corpo.mass)


## Seleciona o corpo sob o cursor por interseção raio-esfera, priorizando o mais
## próximo da câmera (menor t ao longo do raio). Cliques sobre o painel da UI são
## consumidos pelo próprio Control e nunca chegam aqui (a UI tem prioridade).
func _selecionar_por_clique(mouse_pos: Vector2) -> void:
	if camera_3d == null:
		return
	var origem: Vector3 = camera_3d.project_ray_origin(mouse_pos)
	var dir: Vector3 = camera_3d.project_ray_normal(mouse_pos)
	var melhor_idx: int = -1
	var melhor_t: float = INF
	for i in corpo_array.size():
		var corpo: RigidBody3D = corpo_array[i]
		if not is_instance_valid(corpo):
			continue
		var centro: Vector3 = corpo.global_position
		var raio: float = corpo.scale.x * RAIO_BASE
		var oc: Vector3 = origem - centro
		var b: float = oc.dot(dir)
		var c: float = oc.dot(oc) - raio * raio
		var disc: float = b * b - c
		if disc < 0.0:
			continue
		var sq: float = sqrt(disc)
		var t: float = -b - sq
		if t < 0.0:
			t = -b + sq        # câmera dentro da esfera: usa a raiz de saída
		if t < 0.0:
			continue           # esfera totalmente atrás da câmera
		if t < melhor_t:
			melhor_t = t
			melhor_idx = i
	if melhor_idx >= 0:
		_selecionar_corpo(melhor_idx)


# ═══════════════════════════════════════════════════════════════════════════════
#  INSTANCIAÇÃO DE CORPOS
# ═══════════════════════════════════════════════════════════════════════════════

## Instancia um corpo na posição `pos` (UA), com massa `massa` (M☉), raio
## `raio` (UA — escala o RigidBody inteiro: malha visual = forma de colisão),
## velocidade física `vel_fisica` (UA/ano) e opcionalmente um OmniLight3D
## (para o Sol e outros corpos emissivos).
func instanciar_corpo(pos: Vector3, massa: float, raio: float, nome: String,
		vel_fisica: Vector3 = Vector3.ZERO, cor: Color = Color.WHITE,
		emite_luz: bool = false) -> RigidBody3D:
	var corpo: RigidBody3D = CENA_CORPO.instantiate()
	add_child(corpo)

	corpo.global_position = pos
	corpo.scale = Vector3.ONE * (raio * fator_raio_visual / RAIO_BASE)
	corpo.mass = massa
	if corpo.is_inside_tree():
		corpo.reset_physics_interpolation()

	# Velocidade convertida para o ritmo de reprodução atual (τ = escala_tempo × mult).
	corpo.linear_velocity = vel_fisica * _get_tau()

	_aplicar_aparencia(corpo, cor, emite_luz)

	if emite_luz:
		_adicionar_omni_luz(corpo, cor)

	corpo_array.append(corpo)
	_criar_trajetoria(corpo, cor)
	_atualizar_contador_corpos()
	if lista_corpos:
		lista_corpos.add_item("Corpo %d | %s" % [corpo_array.size(), nome])

	return corpo


func _aplicar_aparencia(corpo: RigidBody3D, cor: Color,
		emissivo_forte: bool = false) -> void:
	var malha: MeshInstance3D = corpo.get_node_or_null("MeshInstance3D")
	if malha == null:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = cor
	mat.emission_enabled = true
	mat.emission = cor
	# Corpos emissores de luz (Sol) brilham muito mais que os demais.
	mat.emission_energy_multiplier = 3.0 if emissivo_forte else 0.5
	malha.material_override = mat


## Adiciona um OmniLight3D como filho do corpo, iluminando os planetas ao redor.
func _adicionar_omni_luz(corpo: RigidBody3D, cor: Color = Color.WHITE) -> void:
	var luz := OmniLight3D.new()
	luz.light_color = cor.lightened(0.25)
	luz.light_energy = 1.4
	luz.omni_range = 65.0
	luz.omni_attenuation = 1.8
	luz.shadow_enabled = false
	corpo.add_child(luz)


func checar_colisao(pos: Vector3, raio_min: float) -> bool:
	for corpo in corpo_array:
		if is_instance_valid(corpo) and corpo.global_position.distance_to(pos) < raio_min:
			return true
	return false


func instanciar_multiplos(n: int) -> void:
	var instanciados: int = 0
	var tentativas: int = 0
	while instanciados < n and tentativas < n * 50:
		tentativas += 1
		var pos := Vector3(
			randf_range(-raio_spawn, raio_spawn),
			randf_range(-raio_spawn, raio_spawn),
			randf_range(-raio_spawn, raio_spawn))
		if checar_colisao(pos, raio_minimo_colisao):
			continue
		instanciar_corpo(pos, massa_select, raio_select, nome_select,
				Vector3.ZERO, cor_select)
		instanciados += 1


func _atualizar_contador_corpos() -> void:
	if num_corpos_label:
		num_corpos_label.text = "Corpos: %d" % corpo_array.size()


# ═══════════════════════════════════════════════════════════════════════════════
#  TRAJETÓRIAS
# ═══════════════════════════════════════════════════════════════════════════════

func _get_trajetoria_root() -> Node3D:
	if trajetoria_root == null or not is_instance_valid(trajetoria_root):
		trajetoria_root = Node3D.new()
		trajetoria_root.name = "Trajetorias"
		add_child(trajetoria_root)
	return trajetoria_root


func _criar_trajetoria(corpo: RigidBody3D, cor: Color = Color(0.0, 1.0, 1.0)) -> void:
	if trajetoria_linhas.has(corpo):
		return
	var linha := Line3D.new()
	linha.name = "Trajetoria_%s" % str(corpo.get_instance_id())
	linha.width = trajetoria_largura
	linha.top_level = true

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = cor
	linha.material_override = mat

	_get_trajetoria_root().add_child(linha)

	var inicio: Vector3 = corpo.global_position
	linha.add_point(inicio)
	trajetoria_linhas[corpo] = linha
	trajetoria_ultimo_ponto[corpo] = inicio


func _atualizar_trajetorias() -> void:
	for corpo in corpo_array:
		if not is_instance_valid(corpo):
			_remover_trajetoria(corpo)
			continue
		if not trajetoria_linhas.has(corpo):
			_criar_trajetoria(corpo)
		var ultimo: Vector3 = trajetoria_ultimo_ponto.get(corpo, corpo.global_position)
		var atual: Vector3 = corpo.global_position
		if atual.distance_to(ultimo) >= trajetoria_distancia_minima:
			trajetoria_linhas[corpo].add_point(atual)
			trajetoria_ultimo_ponto[corpo] = atual


func _remover_trajetoria(corpo) -> void:
	if not trajetoria_linhas.has(corpo):
		return
	var linha = trajetoria_linhas[corpo]
	if is_instance_valid(linha):
		linha.queue_free()
	trajetoria_linhas.erase(corpo)
	trajetoria_ultimo_ponto.erase(corpo)


# ═══════════════════════════════════════════════════════════════════════════════
#  FÍSICA
# ═══════════════════════════════════════════════════════════════════════════════

func _physics_process(delta: float) -> void:
	_aplicar_forcas_gravitacionais()
	_atualizar_trajetorias()
	tempo_simulacao += delta * _get_tau()


## Força gravitacional de N-corpos pela superposição (O(N²)):
##   F_i = −G · Σ_{j≠i} mᵢ·mⱼ · (rᵢ−rⱼ) / (|rᵢ−rⱼ|²+ε²)^1.5 · τ²
##
## τ² converte de UA/ano² para o ritmo real de reprodução.
## ε = epsilon_softening limita a força em encontros próximos (Sandbox).
func _aplicar_forcas_gravitacionais() -> void:
	var n: int = corpo_array.size()
	if n < 2:
		return
	var tau_sq: float = _get_tau() * _get_tau()
	var eps_sq: float = epsilon_softening * epsilon_softening

	for i in n:
		var corpo_i: RigidBody3D = corpo_array[i]
		if not is_instance_valid(corpo_i):
			continue
		var pos_i: Vector3 = corpo_i.global_position
		var massa_i: float = corpo_i.mass
		var forca_total := Vector3.ZERO

		for j in n:
			if j == i:
				continue
			var corpo_j: RigidBody3D = corpo_array[j]
			if not is_instance_valid(corpo_j):
				continue
			var diferenca: Vector3 = pos_i - corpo_j.global_position
			var dist_sq: float = diferenca.length_squared()
			if dist_sq < 1e-12:
				continue
			var denominador: float = pow(dist_sq + eps_sq, 1.5)
			forca_total += -G * massa_i * corpo_j.mass * diferenca / denominador

		corpo_i.apply_central_force(forca_total * tau_sq)


# ═══════════════════════════════════════════════════════════════════════════════
#  HELPERS DE ÓRBITA CIRCULAR
# ═══════════════════════════════════════════════════════════════════════════════

## Módulo da velocidade para órbita circular: √(G · M / r), em UA/ano.
func velocidade_circular(massa_central: float, raio: float) -> float:
	if raio <= 0.0:
		return 0.0
	return sqrt(G * massa_central / raio)


## Vetor velocidade tangencial no plano XZ para órbita circular em torno de
## `centro`. Perpendicular ao raio → aceleração centrípeta v²/r = GM/r² ✓.
func velocidade_orbital_circular(centro: Vector3, pos: Vector3,
		massa_central: float) -> Vector3:
	var raio_vetor: Vector3 = pos - centro
	var raio: float = raio_vetor.length()
	if raio <= 0.0:
		return Vector3.ZERO
	var tangente: Vector3 = Vector3(-raio_vetor.z, 0.0, raio_vetor.x).normalized()
	return tangente * velocidade_circular(massa_central, raio)


# ═══════════════════════════════════════════════════════════════════════════════
#  ATUALIZAÇÃO DE INTERFACE E ENTRADA
# ═══════════════════════════════════════════════════════════════════════════════

func _process(_delta: float) -> void:
	if corpo_select >= 0 and corpo_select < corpo_array.size():
		var corpo: RigidBody3D = corpo_array[corpo_select]
		if is_instance_valid(corpo):
			_atualizar_painel_corpo(corpo)

	# Atualiza contador de tempo (atualizado a cada frame visual para suavidade)
	if tempo_label:
		tempo_label.text = "%.2f anos" % tempo_simulacao


## Atualiza todos os campos do painel para o corpo selecionado: coordenadas,
## massa, diâmetro visual, velocidade e (via hook) informações orbitais.
func _atualizar_painel_corpo(corpo: RigidBody3D) -> void:
	var pos: Vector3 = corpo.global_position
	if pos_corpox_label:
		pos_corpox_label.text = "x: %.4f UA" % pos.x
	if pos_corpoy_label:
		pos_corpoy_label.text = "y: %.4f UA" % pos.y
	if pos_corpoz_label:
		pos_corpoz_label.text = "z: %.4f UA" % pos.z
	if massa_info_label:
		massa_info_label.text = "M: %s" % _fmt_massa(corpo.mass)
	if diametro_info_label:
		diametro_info_label.text = "Ø: %.3f UA" % _diametro_visual(corpo)
	if vel_info_label:
		vel_info_label.text = "v: %.3f UA/a" % _vel_fisica(corpo)
	_atualizar_info_orbital(corpo)


## Hook sobrescrito por cenários com corpo central (ex.: Sistema Solar) para
## exibir período, distância e excentricidade da órbita. A base não faz nada.
func _atualizar_info_orbital(_corpo: RigidBody3D) -> void:
	pass


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo \
			and event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file(CENA_MENU)
	elif event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		_selecionar_por_clique(event.position)


# ═══════════════════════════════════════════════════════════════════════════════
#  HELPERS DE FORMATAÇÃO E CONVERSÃO
# ═══════════════════════════════════════════════════════════════════════════════

func _log10(x: float) -> float:
	return log(x) / log(10.0)


## Formata uma massa (M☉) de forma legível: massas grandes em M☉, massas pequenas
## (planetas) em massas terrestres (M⊕) para evitar notação científica.
func _fmt_massa(m_msol: float) -> String:
	if m_msol >= 0.01:
		return "%.3f M☉" % m_msol
	return "%.2f M⊕" % (m_msol / MASSA_TERRA_MSOL)


## Diâmetro visual (renderizado) do corpo em UA = escala × raio base × 2.
func _diametro_visual(corpo: RigidBody3D) -> float:
	return corpo.scale.x * RAIO_BASE * 2.0


## Velocidade física do corpo em UA/ano (desfaz a escala de tempo τ aplicada à
## linear_velocity na instanciação).
func _vel_fisica(corpo: RigidBody3D) -> float:
	var tau: float = _get_tau()
	if tau == 0.0:
		return 0.0
	return corpo.linear_velocity.length() / tau
