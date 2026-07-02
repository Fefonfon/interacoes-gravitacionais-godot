extends Node2D

var corpoi_mas: float
var corpoj_mas: float
var corpoi_pos: Vector2
var corpoj_pos: Vector2

var mas_res: float
var vec_sum: float
var vec_res: Vector2
var pos_res: Vector2
var f_res: Vector2

var corpo_array: Array
var corpo_inst: RigidBody2D

## Instancia um corpo na posição "pos"
func instanciarCorpo(pos: Vector2) -> Node:
	
	# Carrega uma instância de "Corpo2D" na memória
	corpo_inst = preload("res://objetos/corpo_2d.tscn").instantiate()
	add_child(corpo_inst)
	
	# Estabelece atributos do corpo
	corpo_inst.set_position(pos)
	#corpo_inst.set_mass((randf() * 10) + 1); corpo_inst.set_scale(Vector2(1,1)*corpo_inst.get_mass()); print(corpo_inst.get_mass())
	
	# Anexa o corpo instanciado à lista de corpos da cena
	corpo_array.append(corpo_inst)
	
	return corpo_inst

## Checa se um corpo pode ser instanciado na posição "pos", evitando colisões
func checarColisao(pos: Vector2) -> bool:
	var x
	var y
	
	# Busca x e y do corpo a ser analisado
	for corpo in corpo_array:
		x = corpo.get_position()[0]
		y = corpo.get_position()[1]
		
		# Compara se as posições estão dentro de um raio de 60 pixels uma da outra
		if (abs(pos[0] - x) < 60 and abs(pos[1] - y) < 60):
			print("\nComparando ", pos, " com ", x, ", ", y)
			print("!!!!Colisão!!!!")
			return true
		
	return false

## Instancia "N" corpos
func instanciarMultiplos(n: int):
	var random_x: int
	var random_y: int
	var tam_viewport = get_viewport_rect().size
	
	# Cria posições aleatórias dentro dos limites do viewport
	var i: int = 0
	while(i < n):
		random_x = (randi() % int(tam_viewport[0]))
		random_y = (randi() % int(tam_viewport[1]))
		
		# Se retornar "false", não há colisão
		if checarColisao(Vector2(random_x, random_y)):
			print("Pulando...\n")
			continue
		
		print("---- Corpo ", i+1, " instanciado ---- pos:", random_x, ", ", random_y)
		instanciarCorpo(Vector2(random_x, random_y))
		i += 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#instanciarMultiplos(125)
	instanciarCorpo(Vector2(300, 120)); instanciarCorpo(Vector2(500, 300)); instanciarCorpo(Vector2(700, 430)); #instanciarCorpo(Vector2(700, 280)); instanciarCorpo(Vector2(900, 420)); instanciarCorpo(Vector2(900, 220)); instanciarCorpo(Vector2(200, 220)); instanciarCorpo(Vector2(500, 220))
	
	corpo_array[1].apply_central_force(Vector2(3000, -3000))
	
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# Implementar a força que atrai um corpo a outro #f_res = - GRAV * m1 * m2 * (pos2 - pos1) / abs(pos2 - pos1)^3
	# f_res = - 0.00000000006674 * (corpoi_mas * corpoj_mas / (abs(pos2 - pos1) * abs(pos2 - pos1)) )
	
	# multi_forcas = for(j=1, j++, j!=i) {
	#					for(i=1, i++, i<N) {
	#						ai = -G * mi * (rj - ri) / abs(rj - ri)^3
	#					}
	#				}
	
	for i in len(corpo_array):
		for j in len(corpo_array):
			if j == i:
				continue
			
			corpoi_mas = corpo_array[i].get_mass()
			corpoj_mas = corpo_array[j].get_mass()
			corpoi_pos = corpo_array[i].get_position()
			corpoj_pos = corpo_array[j].get_position()
			
			mas_res = -66740 * corpoi_mas * corpoj_mas
			
			vec_res = corpoi_pos - corpoj_pos
			vec_sum = sqrt((vec_res[0] ** 2) + (vec_res[1] ** 2))
			pos_res = (vec_res) / (vec_sum ** 3)
			f_res = mas_res * Vector2(pos_res)
			
			corpo_array[i].apply_central_force(Vector2(f_res))
	pass
