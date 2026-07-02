## dados_corpos.gd
##
## Catálogo de dados dos corpos do Sistema Solar, baseado nas fact-sheets da NASA
## (NSSDC/GSFC). Centraliza as constantes físicas usadas pelos cenários.
##
## raio_visual : raio da esfera em UA — cosmético (exagerado para visibilidade),
##               menor que a folga orbital para não gerar colisões espúrias.
##               Como visual = colisão, este valor escala o RigidBody3D inteiro.
## emite_luz   : se true, um OmniLight3D é adicionado ao corpo ao instanciá-lo.

class_name DadosCorpos
extends RefCounted


const PLANETAS: Array[Dictionary] = [
	{"nome": "Sol",      "massa_kg": 1.988416e30, "semieixo_ua": 0.0,    "raio_visual": 0.12,  "cor": Color(1.0,  0.88, 0.35, 1), "emite_luz": true},
	{"nome": "Mercúrio", "massa_kg": 0.330e24,    "semieixo_ua": 0.387,  "raio_visual": 0.018, "cor": Color(0.65, 0.60, 0.55, 1)},
	{"nome": "Vênus",    "massa_kg": 4.87e24,     "semieixo_ua": 0.723,  "raio_visual": 0.028, "cor": Color(0.85, 0.70, 0.40, 1)},
	{"nome": "Terra",    "massa_kg": 5.972e24,     "semieixo_ua": 1.0,    "raio_visual": 0.030, "cor": Color(0.25, 0.50, 1.0,  1)},
	{"nome": "Marte",    "massa_kg": 0.642e24,    "semieixo_ua": 1.524,  "raio_visual": 0.022, "cor": Color(0.80, 0.35, 0.20, 1)},
	{"nome": "Júpiter",  "massa_kg": 1898.0e24,   "semieixo_ua": 5.203,  "raio_visual": 0.070, "cor": Color(0.80, 0.70, 0.55, 1)},
	{"nome": "Saturno",  "massa_kg": 568.0e24,    "semieixo_ua": 9.537,  "raio_visual": 0.062, "cor": Color(0.90, 0.82, 0.62, 1)},
	{"nome": "Urano",    "massa_kg": 86.8e24,     "semieixo_ua": 19.191, "raio_visual": 0.042, "cor": Color(0.60, 0.85, 0.90, 1)},
	{"nome": "Netuno",   "massa_kg": 102.0e24,    "semieixo_ua": 30.07,  "raio_visual": 0.042, "cor": Color(0.30, 0.45, 0.90, 1)},
]


# ─── Dados individuais usados por cenários específicos ─────────────────────────
const SOL: Dictionary   = {"nome": "Sol",   "massa_kg": 1.988416e30, "semieixo_ua": 0.0,    "raio_visual": 0.12,  "cor": Color(1.0,  0.88, 0.35, 1), "emite_luz": true}
const TERRA: Dictionary = {"nome": "Terra", "massa_kg": 5.972e24,   "semieixo_ua": 1.0,    "raio_visual": 0.030, "cor": Color(0.25, 0.50, 1.0,  1)}
const LUA: Dictionary   = {"nome": "Lua",   "massa_kg": 0.073e24,   "semieixo_ua": 0.00257,"raio_visual": 0.010, "cor": Color(0.70, 0.70, 0.65, 1)}
