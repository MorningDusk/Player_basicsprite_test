extends CharacterBody2D

@export var gravity = 750
@export var run_speed = 150
@export var jump_speed = -300
@export var dash_speed = 300
@export var dash_duration = 0.2

enum {IDLE, WALK, JUMP, DASH, AIRDASH}
var state = IDLE
var dash_timer = 0
var facing_right = true

func _ready() -> void:
	change_state(IDLE)

func hide_all_sprites():
	for sprite in $Right.get_children():
		sprite.visible = false
	for sprite in $Left.get_children():
		sprite.visible = false

func change_state(new_state):
	state = new_state
	hide_all_sprites()
	
	var direction_node = $Right if facing_right else $Left
	
	match state:
		IDLE:
			$AnimationPlayer.play("right_idle" if facing_right else "left_idle")
			direction_node.get_node("idle").visible = true
		WALK:
			$AnimationPlayer.play("right_walk" if facing_right else "left_walk")
			direction_node.get_node("walk").visible = true
		JUMP:
			$AnimationPlayer.play("right_jump" if facing_right else "left_jump")
			direction_node.get_node("jump").visible = true
		DASH:
			$AnimationPlayer.play("right_dash" if facing_right else "left_dash")
			direction_node.get_node("dash").visible = true
		AIRDASH:
			$AnimationPlayer.play("right_airdash" if facing_right else "left_airdash")
			direction_node.get_node("airdash").visible = true

func get_input():
	var right = Input.is_action_pressed("right")
	var left = Input.is_action_pressed("left")
	var jump = Input.is_action_pressed("jump")
	var dash = Input.is_action_just_pressed("dash")
	
	velocity.x = 0
	
	# 방향 입력에 따른 이동과 방향 전환
	if right:
		velocity.x += run_speed
		if not facing_right:
			facing_right = true
			change_state(state)  # 현재 상태를 유지하면서 방향만 변경
	if left:
		velocity.x -= run_speed
		if facing_right:
			facing_right = false
			change_state(state)  # 현재 상태를 유지하면서 방향만 변경
	
	# 대시 상태 처리
	if dash:
		if is_on_floor():
			change_state(DASH)
		else:
			change_state(AIRDASH)
		dash_timer = 0
	
	# 점프 상태 처리
	if jump and is_on_floor():
		change_state(JUMP)
		velocity.y = jump_speed
	
	# 걷기/대기 상태 처리
	if state != DASH and state != AIRDASH:  # 대시 중이 아닐 때만 상태 변경
		if is_on_floor():
			if velocity.x != 0:
				change_state(WALK)
			else:
				change_state(IDLE)
		else:
			if state != JUMP:  # 이미 점프 상태가 아닐 때만 변경
				change_state(JUMP)

func _physics_process(delta: float) -> void:
	if state == DASH or state == AIRDASH:
		dash_timer += delta
		if dash_timer >= dash_duration:
			dash_timer = 0
			if is_on_floor():
				change_state(IDLE)
			else:
				change_state(JUMP)
		velocity.x = dash_speed * (1 if facing_right else -1)
		
		if state == AIRDASH:
			velocity.y = 0  # 공중 대시 중에는 중력 무시
	else:
		velocity.y += gravity * delta
		get_input()
	
	move_and_slide()
