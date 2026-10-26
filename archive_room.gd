extends Node2D

signal clue_found(clue_id: String)

var feed_id := "hallway"
var play_area := Vector2(680, 280)
var cursor: CharacterBody2D
var active := false
var found := 0

func _ready() -> void:
	set_physics_process(false)
	_build_room()

func _build_room() -> void:
	cursor = CharacterBody2D.new()
	cursor.name = "EvidenceCursor"
	cursor.position = Vector2(play_area.x * 0.5, play_area.y * 0.82)
	cursor.collision_layer = 1
	cursor.collision_mask = 1
	var player_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(14, 14)
	player_shape.shape = rectangle
	cursor.add_child(player_shape)
	cursor.add_child(CursorVisual.new())
	add_child(cursor)
	_make_wall(Vector2(play_area.x * 0.5, 4), Vector2(play_area.x, 8))
	_make_wall(Vector2(play_area.x * 0.5, play_area.y - 4), Vector2(play_area.x, 8))
	_make_wall(Vector2(4, play_area.y * 0.5), Vector2(8, play_area.y))
	_make_wall(Vector2(play_area.x - 4, play_area.y * 0.5), Vector2(8, play_area.y))
	_spawn_pickups({})
	set_feed(feed_id)

func reset_scan(saved_flags: Dictionary = {}) -> void:
	for child in get_children():
		if child is EvidencePickup:
			child.queue_free()
	found = 0
	cursor.position = Vector2(play_area.x * 0.5, play_area.y * 0.82)
	_spawn_pickups(saved_flags)

func _spawn_pickups(saved_flags: Dictionary) -> void:
	var kinds := [["timecode", "scan_time"], ["keytag", "key"], ["fiber", "scan_fiber"]]
	var points := [Vector2(play_area.x * 0.25, play_area.y * 0.35), Vector2(play_area.x * 0.72, play_area.y * 0.28), Vector2(play_area.x * 0.40, play_area.y * 0.60)]
	for i in range(kinds.size()):
		var clue_id: String = kinds[i][0]
		var flag_name: String = kinds[i][1]
		if saved_flags.has(flag_name):
			found += 1
			continue
		var pickup := EvidencePickup.new()
		pickup.clue_id = clue_id
		pickup.position = points[i]
		pickup.acquired.connect(_on_pickup)
		add_child(pickup)

func set_view_size(new_size: Vector2) -> void:
	scale = Vector2(new_size.x / 680.0, new_size.y / 280.0)
	queue_redraw()

func set_feed(new_feed: String) -> void:
	feed_id = new_feed
	queue_redraw()

func set_active(value: bool) -> void:
	active = value and found < 3
	visible = active
	set_physics_process(active)
	if cursor:
		cursor.visible = active
	queue_redraw()
func _physics_process(_delta: float) -> void:
	if not active or cursor == null:
		return
	var direction := Vector2.ZERO
	if Input.is_action_pressed("archive_left"): direction.x -= 1.0
	if Input.is_action_pressed("archive_right"): direction.x += 1.0
	if Input.is_action_pressed("archive_up"): direction.y -= 1.0
	if Input.is_action_pressed("archive_down"): direction.y += 1.0
	cursor.velocity = direction.normalized() * 150.0
	cursor.move_and_slide()

func _make_wall(at: Vector2, dimensions: Vector2) -> void:
	var wall := StaticBody2D.new()
	wall.position = at
	wall.collision_layer = 1
	wall.collision_mask = 1
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = dimensions
	collider.shape = shape
	wall.add_child(collider)
	add_child(wall)

func _on_pickup(clue_id: String) -> void:
	found += 1
	clue_found.emit(clue_id)
	if found >= 3:
		set_active(false)
	queue_redraw()

func _draw() -> void:
	var bg := Color("#121a18")
	if feed_id == "stairs" or feed_id == "fiber": bg = Color("#17191a")
	elif feed_id == "lobby" or feed_id == "reflection": bg = Color("#192019")
	draw_rect(Rect2(Vector2.ZERO, play_area), bg)
	draw_rect(Rect2(10, 10, play_area.x - 20, play_area.y - 20), Color("#202a22"))
	draw_line(Vector2(10, 10), Vector2(play_area.x * 0.42, play_area.y * 0.44), Color("#65715d"), 2)
	draw_line(Vector2(play_area.x - 10, 10), Vector2(play_area.x * 0.58, play_area.y * 0.44), Color("#65715d"), 2)
	draw_line(Vector2(play_area.x * 0.42, play_area.y * 0.44), Vector2(10, play_area.y - 10), Color("#65715d"), 2)
	draw_line(Vector2(play_area.x * 0.58, play_area.y * 0.44), Vector2(play_area.x - 10, play_area.y - 10), Color("#65715d"), 2)
	for row in range(5):
		var yy := play_area.y * (0.20 + row * 0.11)
		draw_line(Vector2(play_area.x * 0.18, yy), Vector2(play_area.x * 0.82, yy), Color("#344439"), 1)
	if feed_id in ["stairs", "fiber", "cup"]:
		draw_rect(Rect2(play_area.x * 0.68, play_area.y * 0.25, play_area.x * 0.14, play_area.y * 0.42), Color("#0b1413"))
		draw_circle(Vector2(play_area.x * 0.50, play_area.y * 0.40), 8, Color("#a99b7d"))
		draw_colored_polygon(PackedVector2Array([Vector2(play_area.x * 0.47, play_area.y * 0.44), Vector2(play_area.x * 0.53, play_area.y * 0.44), Vector2(play_area.x * 0.57, play_area.y * 0.70), Vector2(play_area.x * 0.43, play_area.y * 0.70)]), Color("#8d8775"))
	elif feed_id in ["lobby", "reflection", "vault", "backup"]:
		draw_rect(Rect2(play_area.x * 0.65, play_area.y * 0.12, play_area.x * 0.23, play_area.y * 0.58), Color("#111c19"))
		draw_rect(Rect2(play_area.x * 0.68, play_area.y * 0.16, play_area.x * 0.17, play_area.y * 0.49), Color("#28332a"))
		draw_circle(Vector2(play_area.x * 0.76, play_area.y * 0.40), 7, Color("#a28c66"))
	else:
		draw_rect(Rect2(play_area.x * 0.76, play_area.y * 0.22, play_area.x * 0.12, play_area.y * 0.36), Color("#0b1413"))
	for y in range(0, int(play_area.y), 4):
		draw_line(Vector2(0, y), Vector2(play_area.x, y), Color(0, 0, 0, 0.18), 1)
	var camera_name := "CAM 09-A"
	if feed_id in ["stairs", "fiber", "cup"]: camera_name = "CAM 12-C"
	elif feed_id in ["lobby", "reflection", "vault", "backup"]: camera_name = "CAM 01-A"
	draw_string(ThemeDB.fallback_font, Vector2(14, 23), camera_name + "  REC", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#e58a65"))
	draw_string(ThemeDB.fallback_font, Vector2(play_area.x - 130, 23), "02:11:36", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#d3e3c8"))
	draw_string(ThemeDB.fallback_font, Vector2(14, play_area.y - 12), "FRAME INDEX: 09     ARCHIVE SIGNAL: UNSTABLE", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#b8c8aa"))

class CursorVisual:
	extends Node2D
	func _draw() -> void:
		draw_circle(Vector2.ZERO, 7, Color("#65e6c0"))
		draw_circle(Vector2.ZERO, 3, Color("#071316"))
		draw_line(Vector2(-11, 0), Vector2(11, 0), Color("#65e6c0"), 1)
		draw_line(Vector2(0, -11), Vector2(0, 11), Color("#65e6c0"), 1)

class EvidencePickup:
	extends Area2D
	signal acquired(clue_id: String)
	var clue_id := ""
	func _ready() -> void:
		collision_layer = 0
		collision_mask = 1
		var collider := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = 12
		collider.shape = shape
		add_child(collider)
		body_entered.connect(_on_body_entered)
		queue_redraw()
	func _draw() -> void:
		draw_circle(Vector2.ZERO, 11, Color("#f3b96b"))
		draw_circle(Vector2.ZERO, 7, Color("#12201d"))
		draw_circle(Vector2.ZERO, 3, Color("#f3b96b"))
	func _on_body_entered(body: Node2D) -> void:
		if body is CharacterBody2D:
			acquired.emit(clue_id)
			queue_free()




