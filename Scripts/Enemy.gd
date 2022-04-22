extends KinematicBody2D

var floating_text = preload("res://Scenes/Floating Text.tscn")
var xp_gem = preload("res://Scenes/XP_GEM.tscn")

var run_speed = 25
var velocity = Vector2.ZERO
var attackBool = false
var attackedOnce = false

var facingLeft = false;
var facingRight = true;

var path: Array = []


onready var levelNavigation: Navigation2D = get_tree().get_nodes_in_group("LevelNavigation")[0]
onready var player = get_tree().get_nodes_in_group("Player")[0]

var rng : RandomNumberGenerator = RandomNumberGenerator.new()


func _physics_process(_delta):
	
#	if(player && levelNavigation):
#		generate_path()
#		navigate()
	moveTowardsPlayer()
	velocity = move_and_slide(velocity)
	
func navigate():
	if path.size() > 0:
		velocity = global_position.direction_to(path[1]) * $EnemyStats.movement_speed
		
		if global_position == path[0]:
			path.pop_front()
	
func generate_path():
	if levelNavigation != null and player != null:
		path = levelNavigation.get_simple_path(global_position, player.global_position, false)

func moveTowardsPlayer():
	velocity = Vector2.ZERO
#	$AnimationPlayer.playback_speed = $EnemyStats.movement_speed / 22
	if player && $EnemyStats.current_health > 0 && !attackBool:
		velocity = position.direction_to(player.position) * $EnemyStats.movement_speed
		
	if(!attackBool):
		if velocity.x > 0 && !facingRight:
			$AnimatedSprite.flip_h = true
			$AnimatedSprite.position.x = 7
			facingRight = true
			facingLeft = false

	#		$Hitbox.scale.x = 1
		if velocity.x < 0 && !facingLeft:
			$AnimatedSprite.flip_h = false
			$AnimatedSprite.position.x = -6
			facingLeft = true
			facingRight = false
	#		$Hitbox.scale.x = -1
		if(velocity != Vector2.ZERO):
			$AnimationPlayer.play("Run")
		else:
			$AnimationPlayer.play("Idle")

	else:
		$AnimationPlayer.play("Attack")

	

func create_hit_timer():
	$AnimatedSprite.modulate = Color(1,0,0)
	var timer = Timer.new()
	timer.set_one_shot(true)
	timer.connect("timeout", self, "hit_effect")
	add_child(timer)
	timer.start(0.2)

func hit_effect():
	$AnimatedSprite.modulate = Color(1,1,1)

func dealDamage():
	if(attackBool):
		var crit_chance = rand_range(0,1)
		var damage = 0
		var targets = $Hitbox.get_overlapping_bodies()
		if($EnemyStats.crit_chance >= crit_chance):
			damage = rng.randi_range($EnemyStats.base_damage * 3, $EnemyStats.base_damage * 4)
		else:
			damage = rng.randi_range($EnemyStats.base_damage, $EnemyStats.base_damage * 2)
		
		for n in targets:
			n.takeDamage(damage)

func generateXPGem():
	var amount = clamp(randi()%3, 1, 3)
	for n in amount:
		var randPos = randi() % 5
		var xp_gem_instance = xp_gem.instance()
		xp_gem_instance.position.x = (self.position.x + randPos)
		randPos = randi() % 5
		xp_gem_instance.position.y = (self.position.y + randPos)
		get_parent().add_child(xp_gem_instance)
		
	
func takeDamage(damage, crit):
#	damage reduction
	damage -= int(damage * $EnemyStats.armor)

	var instance = floating_text.instance()
	instance.amount = damage 
	instance.crit = crit
	instance.travel = -velocity
	add_child(instance)
	
	if(damage != 0):
		create_hit_timer()
		
	$EnemyStats.current_health -= damage 
	if($EnemyStats.current_health <= 0):
		generateXPGem()
		$AttackTimer.stop()
		$Collision.disabled = true
		z_index = 0
		var tween = Tween.new()
		add_child(tween)
		tween.interpolate_property($AnimatedSprite.get_material(), "shader_param/value", 1, 0, 0.7, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		tween.interpolate_property($Shadow.get_material(), "shader_param/value", 1, 0, 0.7, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		tween.interpolate_property($AnimatedSprite, "modulate", Color(1,1,1,1), Color(0,0,0,1), 0.3, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
		tween.start()
		yield(tween, "tween_all_completed")
		queue_free()
	

func _on_Hitbox_body_entered(_body):
	attackBool = true
	if(!attackedOnce):
		dealDamage()
		$AttackTimer.start($EnemyStats.attack_speed)
		attackedOnce = true
	else:
		$AttackTimer.paused = false

func _on_Hitbox_body_exited(_body):
	attackBool = false
	$AttackTimer.paused = true
	
func _on_AttackTimer_timeout():
	dealDamage()


