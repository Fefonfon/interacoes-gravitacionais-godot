## menu_principal.gd
##
## Tela inicial. Cada botão carrega a cena de um cenário de simulação.

extends Control

const CENA_SISTEMA_SOLAR: String = "res://sistema-solar.tscn"
const CENA_SANDBOX: String = "res://sandbox.tscn"
const CENA_FIGURA_OITO: String = "res://figura-oito.tscn"
const CENA_TRES_CORPOS: String = "res://tres-corpos.tscn"
const CENA_TERRA_LUA: String = "res://terra-lua.tscn"
const CENA_ESTRELA_BINARIA: String = "res://estrela-binaria.tscn"
const CENA_NBODY_CAOTICO: String = "res://nbody-caotico.tscn"

@onready var lista_botoes: VBoxContainer = $CenterContainer/VBoxContainer


func _ready() -> void:
	_ligar_cenario("SistemaSolarButton", CENA_SISTEMA_SOLAR)
	_ligar_cenario("SandboxButton", CENA_SANDBOX)
	_ligar_cenario("FiguraOitoButton", CENA_FIGURA_OITO)
	_ligar_cenario("TresCorposButton", CENA_TRES_CORPOS)
	_ligar_cenario("TerraLuaButton", CENA_TERRA_LUA)
	_ligar_cenario("EstrelaBinariaButton", CENA_ESTRELA_BINARIA)
	_ligar_cenario("NBodyCaoticoButton", CENA_NBODY_CAOTICO)

	var sair: Button = lista_botoes.get_node_or_null("SairButton")
	if sair:
		sair.pressed.connect(func() -> void: get_tree().quit())

	var primeiro: Button = lista_botoes.get_node_or_null("SistemaSolarButton")
	if primeiro:
		primeiro.grab_focus()


## Conecta o botão `nome` para carregar a cena em `caminho`, se o botão existir.
func _ligar_cenario(nome: String, caminho: String) -> void:
	var botao: Button = lista_botoes.get_node_or_null(nome)
	if botao:
		botao.pressed.connect(func() -> void: get_tree().change_scene_to_file(caminho))
