## unidades_gravitacionais.gd
##
## Sistema de unidades adimensional adotado pelo simulador (UA, M☉, ano).
## Registrado como Autoload com o nome "UnidadesGravitacionais" em project.godot.
##
## Funções de conversão declaradas como métodos de instância (sem `static`)
## para que possam ser chamadas normalmente via o singleton do Autoload.

extends Node


# ─── Constante gravitacional (SI) ────────────────────────────────────────────
const G_SI: float = 6.674e-11       ## m³ · kg⁻¹ · s⁻²


# ─── Unidades base ────────────────────────────────────────────────────────────
const L_UNIT: float = 1.496e11      ## 1 UA  em metros
const M_UNIT: float = 1.988416e30   ## 1 M☉  em quilogramas
const T_UNIT: float = 3.156e7       ## 1 ano em segundos


# ─── G reescalado para o sistema UA / M☉ / ano ───────────────────────────────
## G = G_SI × (M_unit × T_unit²) / L_unit³ ≈ 39,48 ≈ 4π²
## Corresponde à constante gravitacional gaussiana de Gauss (1809).
const G: float = G_SI * M_UNIT * T_UNIT * T_UNIT / (L_UNIT * L_UNIT * L_UNIT)


# ═══════════════════════════════════════════════════════════════════════════════
#  CONVERSORES  SI → Simulação
# ═══════════════════════════════════════════════════════════════════════════════

func massa_para_sim(kg: float) -> float:
	return kg / M_UNIT

func distancia_para_sim(metros: float) -> float:
	return metros / L_UNIT

func tempo_para_sim(segundos: float) -> float:
	return segundos / T_UNIT

func velocidade_para_sim(ms: float) -> float:
	return ms * T_UNIT / L_UNIT


# ═══════════════════════════════════════════════════════════════════════════════
#  CONVERSORES  Simulação → SI
# ═══════════════════════════════════════════════════════════════════════════════

func massa_para_si(sim: float) -> float:
	return sim * M_UNIT

func distancia_para_si(sim: float) -> float:
	return sim * L_UNIT

func tempo_para_si(sim: float) -> float:
	return sim * T_UNIT

func velocidade_para_si(sim: float) -> float:
	return sim * L_UNIT / T_UNIT


# ═══════════════════════════════════════════════════════════════════════════════
#  FÍSICA
# ═══════════════════════════════════════════════════════════════════════════════

func forca_gravitacional(m1: float, m2: float, r: float) -> float:
	if r <= 0.0:
		return 0.0
	return G * m1 * m2 / (r * r)

func aceleracao_gravitacional_3d(
		pos_corpo: Vector3,
		pos_atrator: Vector3,
		massa_atrator: float) -> Vector3:
	var diferenca: Vector3 = pos_atrator - pos_corpo
	var dist_sq: float = diferenca.length_squared()
	if dist_sq <= 0.0:
		return Vector3.ZERO
	return diferenca.normalized() * (G * massa_atrator / dist_sq)

func velocidade_orbital(massa_atrator: float, r: float) -> float:
	if r <= 0.0:
		return 0.0
	return sqrt(G * massa_atrator / r)
