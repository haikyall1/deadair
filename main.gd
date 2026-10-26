extends Control

const PANEL_COLOR := Color("#0b1d20")
const LINE_COLOR := Color("#20524a")
const TEAL := Color("#65e6c0")
const MUTED := Color("#89a9a0")
const AMBER := Color("#f3b96b")
const ROOM_PATH := "res://ArchiveRoom.tscn"
const SAVE_PATH := "user://archive09_save.cfg"

var flags: Dictionary = {}
var current_id := "boot"
var game_shell: Control
var menu_overlay: Control
var loading_overlay: Control
var loading_bar: ProgressBar
var loading_label: Label
var dialogue_label: RichTextLabel
var choices_box: VBoxContainer
var speaker_label: Label
var evidence_label: RichTextLabel
var status_label: Label
var clock_label: Label
var camera_view
var archive_room
var loading_elapsed := 0.0
var pending_load := false
var restore_after_load := false
var session_started := false
var elapsed_seconds := 0.0

const STORY := {
	"boot": {"speaker":"SYSTEM", "feed":"hallway", "text":"A typo in your credential-scraper opens a door that should have been bricked up twenty-two years ago.\n\nARCHIVE 09 // HAWTHORNE HOTEL // OCTOBER 14, 2004\n\nThe footage ends at 02:17. Someone died in the blind spot between cameras. Your cursor blinks over the first clip.", "choices":[["PLAY THE LAST NIGHT", "hallway", ""]]},
	"hallway": {"speaker":"MARA / CAMERA 09-A", "feed":"hallway", "text":"The corridor swims in green phosphor. A woman in a pale coat passes the elevator at 02:11. She looks directly into the lens.\n\nThe file header says this camera was offline that night. The image says otherwise.", "choices":[["Inspect the corrupted file header", "header", ""],["Follow the woman to the service stairs", "stairs", ""],["Compare neighboring camera headers", "index_check", ""]]},
	"index_check": {"speaker":"YOU / CAMERA INDEX", "feed":"index_check", "text":"You compare the 09-A hallway index with the next camera in sequence. The hallway feed was marked OFFLINE, but its checksum updated at 02:17:43—after the murder. Someone edited the archive index, not the camera itself.", "flag":"time_gap", "choices":[["Follow the timestamp to the service stairs", "stairs", ""]]},
	"header": {"speaker":"YOU", "feed":"header", "text":"You peel back the corrupted header. A second timestamp is buried underneath: 02:17:43. The camera was recording. Somebody changed the index after the murder.\n\nA login token is stamped E.V. You save the tamper record.", "flag":"header", "choices":[["Follow the timeline to the service stairs", "stairs", ""]]},
	"stairs": {"speaker":"MARA / CAMERA 12-C", "feed":"stairs", "text":"On the landing, the woman waits. A guard enters frame with a paper cup. He leaves it on the step, then walks away. Red thread catches on the door latch.\n\nThe camera switches to a second angle: CAM 12-C.", "choices":[["Zoom in on the cup", "cup", ""],["Trace the red thread", "thread", ""],["Check the guard's shift report", "shift_report", ""]]},
	"shift_report": {"speaker":"YOU / NIGHT SHIFT ROSTER", "feed":"shift_report", "text":"The guard clocked out at 01:55, but the roster has a handwritten correction placing him on the east-wing landing at 02:11. The ink is fresh. Either he returned, or someone wanted his name in the record.", "flag":"cup", "choices":[["Compare the roster with the lobby footage", "lobby", ""]]},
	"cup": {"speaker":"YOU", "feed":"cup", "text":"The cup's rim carries a lipstick mark. The guard's shift report says he never entered the east wing. He lied about being here—but a lie is not a murder.", "flag":"cup", "choices":[["Add the guard's false report to the timeline", "lobby", ""]]},
	"thread": {"speaker":"YOU", "feed":"fiber", "text":"A torn fiber is caught in the latch: red wool, matching the night manager Evelyn Vale's scarf. The woman in the pale coat wore no scarf. Whoever came through this door may have followed her.", "flag":"thread", "choices":[["Save the fiber match", "lobby", ""]]},
	"lobby": {"speaker":"MARA / CAMERA 01-A", "feed":"lobby", "text":"The lobby clock jumps from 02:14 to 02:19. In the dark window's reflection, a figure crosses behind the desk while the lobby itself is empty.\n\nA message appears over the feed: STOP LOOKING.", "choices":[["Rebuild the missing reflection", "reflection", ""],["Open the archive maintenance memo", "memo", ""],["Decode an orphaned backup file", "backup", "header"]]},
	"reflection": {"speaker":"YOU", "feed":"reflection", "text":"You brighten the reflection instead of the room. A hand carries a master-key ring; the brass tag reads 09. The reflected figure is shorter than Evelyn Vale. Someone else had access to the archive.", "flag":"key", "choices":[["Pin the key ring to your timeline", "memo", ""]]},
	"memo": {"speaker":"E.V. / MAINTENANCE MEMO", "feed":"memo", "text":"'Camera 09 was manually looped at 02:17. No outside access. I have the only master key.'\n\nSigned Evelyn Vale, Night Manager. Dated two days before the murder.\n\nYour connection stutters. Your own login is still live.", "flag":"memo", "choices":[["Search the orphaned backup sector", "backup", "header"],["Go to the final camera clip", "confront", ""]]},
	"backup": {"speaker":"SYSTEM / RECOVERED SECTOR", "feed":"backup", "text":"The backup is encrypted under an old technician's username: G.SHaw. A partial audio log plays through the static: '...the east service door. Vale said she'd keep the loop running. I can't let the audit go through.'\n\nThe footage shows the pale-coated woman leaving before the murder. A second figure enters with a master key.", "flag":"backup", "choices":[["Match the key tag to the camera log", "confront", "key"],["Protect the witness and preserve the original", "ending_witness", ""],["Send the recovered sector to detectives", "ending_solved", "backup"]]},
	"confront": {"speaker":"SYSTEM // LINK COLLAPSING", "feed":"security", "text":"The archive begins to unmount. The woman in the pale coat stands outside the security office and holds a handwritten sign to the lens:\n\nI DIDN'T KILL HIM. I SAW WHO DID.\n\nYou have one clean upload before the connection closes. The next choice will decide what happens to the evidence.", "choices":[["Preserve the original clip and protect the witness", "ending_witness", ""],["Publish the tamper log naming Evelyn Vale", "ending_expose", "header"],["Send the evidence to the cold-case unit", "ending_police", "key"],["Accuse the guard who lied", "ending_guard", "cup"],["Release the backup naming Gideon Shaw", "ending_solved", "backup"],["Sell the archive to an anonymous buyer", "ending_blackmail", "backup"],["Disconnect and leave the case buried", "ending_silence", ""]]},
	"ending_witness": {"speaker":"ENDING 01 // THE WITNESS", "feed":"ending", "ending":true, "text":"You preserve the unedited clip. The woman is Lena Ortiz, the victim's sister. She tried to report what she saw; the original footage disappeared before anyone could verify her account.\n\nNow the evidence is safe. Your own access trail isn't. The screen goes black.\n\nCASE STATUS: REOPENED"},
	"ending_expose": {"speaker":"ENDING 02 // THE WRONG NAME", "feed":"ending", "ending":true, "text":"You publish Evelyn Vale's tamper log. Her initials spread across the network before the archive closes. She did loop the camera and lie about the key—but the backup shows she was covering for someone else.\n\nAn unknown address sends one line: YOU HAVE THE WRONG VALE.\n\nCASE STATUS: EXPOSED, NOT SOLVED"},
	"ending_police": {"speaker":"ENDING 03 // CHAIN OF CUSTODY", "feed":"ending", "ending":true, "text":"You send the recovered key record and original frames to the cold-case unit. This time, the evidence has a clean chain of custody.\n\nAn officer replies: 'We found Lena Ortiz. She wants to talk.' The archive disconnects before you can ask what she remembers.\n\nCASE STATUS: REOPENED"},
	"ending_guard": {"speaker":"ENDING 04 // EASY ANSWER", "feed":"ending", "ending":true, "text":"You point to the guard's false report. Police reopen the case and question him for three days. He lied because he was stealing from the hotel—not because he killed anyone.\n\nThe real killer gets another twenty-two years.\n\nCASE STATUS: MISDIRECTED"},
	"ending_solved": {"speaker":"ENDING 05 // DEAD AIR", "feed":"ending_solved", "ending":true, "text":"You match the brass key tag, the maintenance loop, and the orphaned audio. Gideon Shaw, the hotel's systems technician, killed the auditor who found his fraud. Evelyn Vale looped the camera to protect her sister, the witness.\n\nLena agrees to testify. The cold case finally has a name, a motive, and evidence.\n\nCASE STATUS: SOLVED"},
	"ending_blackmail": {"speaker":"ENDING 06 // PRIVATE SALE", "feed":"ending", "ending":true, "text":"You sell the backup to an anonymous buyer. The money clears before sunrise. The archive goes dark, and so does the witness's last chance to be heard.\n\nA final message appears: THANK YOU FOR KEEPING THE ORIGINAL.\n\nCASE STATUS: CLOSED BY SOMEONE"},
	"ending_silence": {"speaker":"ENDING 07 // NO SIGNAL", "feed":"ending", "ending":true, "text":"You disconnect without sending anything. The evidence remains in the archive, buried under another layer of corrupted indexes.\n\nIn the terminal reflection, your cursor still blinks. You know where the door is now.\n\nCASE STATUS: UNCHANGED"}
}

func _ready() -> void:
	_ensure_input_actions()
	_build_ui()
	_show_menu()

func _process(delta: float) -> void:
	elapsed_seconds += delta
	if clock_label:
		var seconds := int(elapsed_seconds)
		clock_label.text = "LOCAL 01:%02d:%02d  |  LINK: UNSTABLE" % [42 + int(seconds / 60), seconds % 60]
	if not pending_load:
		return
	loading_elapsed += delta
	var progress: Array = []
	var state := ResourceLoader.load_threaded_get_status(ROOM_PATH, progress)
	if loading_bar and not progress.is_empty():
		loading_bar.value = float(progress[0]) * 100.0
	if loading_label:
		loading_label.text = "MOUNTING SECURITY ARCHIVE…  %d%%" % int(loading_bar.value if loading_bar else 0.0)
	if state == ResourceLoader.THREAD_LOAD_LOADED and loading_elapsed >= 0.35:
		_finish_threaded_load()
	elif state == ResourceLoader.THREAD_LOAD_FAILED or state == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		pending_load = false
		loading_overlay.visible = false
		menu_overlay.visible = true
		loading_label.text = "Archive could not be mounted. Return to the terminal and try again."

func _ensure_input_actions() -> void:
	var keys := {"archive_left": KEY_A, "archive_right": KEY_D, "archive_up": KEY_W, "archive_down": KEY_S}
	for action_name in keys:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
			var key_event := InputEventKey.new()
			key_event.physical_keycode = keys[action_name]
			InputMap.action_add_event(action_name, key_event)
	# Arrow keys are also supported.
	var arrows := {"archive_left": KEY_LEFT, "archive_right": KEY_RIGHT, "archive_up": KEY_UP, "archive_down": KEY_DOWN}
	for action_name in arrows:
		var key_event := InputEventKey.new()
		key_event.physical_keycode = arrows[action_name]
		InputMap.action_add_event(action_name, key_event)

func _build_ui() -> void:
	game_shell = Control.new()
	game_shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_shell.offset_left = 18
	game_shell.offset_right = -18
	game_shell.offset_top = 12
	game_shell.offset_bottom = -10
	add_child(game_shell)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 8)
	game_shell.add_child(root)
	var top := HBoxContainer.new()
	root.add_child(top)
	var logo := Label.new()
	logo.text = "▣  DEAD AIR"
	logo.add_theme_font_size_override("font_size", 22)
	logo.add_theme_color_override("font_color", TEAL)
	top.add_child(logo)
	var subtitle := Label.new()
	subtitle.text = "  /  ARCHIVE 09     HAWTHORNE HOTEL // 2004"
	subtitle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	subtitle.add_theme_color_override("font_color", MUTED)
	top.add_child(subtitle)
	clock_label = Label.new()
	clock_label.text = "LOCAL 01:42:08  |  LINK: UNSTABLE"
	clock_label.add_theme_color_override("font_color", AMBER)
	top.add_child(clock_label)
	_add_line(root)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 9)
	root.add_child(body)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 225
	left.add_theme_constant_override("separation", 8)
	body.add_child(left)
	var profile := _panel(left, "// OPERATOR PROFILE", 210)
	var portrait := OperatorPortrait.new()
	portrait.custom_minimum_size = Vector2(190, 158)
	profile.add_child(portrait)
	var profile_note := Label.new()
	profile_note.text = "GHOST USER\nSELF-TAUGHT // AGE 19\nAUTH: UNVERIFIED"
	profile_note.add_theme_color_override("font_color", MUTED)
	left.add_child(profile_note)
	var evidence := _panel(left, "// RECOVERED CLUES", 155)
	evidence_label = RichTextLabel.new()
	evidence_label.bbcode_enabled = true
	evidence_label.fit_content = true
	evidence_label.add_theme_color_override("default_color", MUTED)
	evidence.add_child(evidence_label)
	_update_evidence()
	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_theme_constant_override("separation", 7)
	body.add_child(center)
	var camera_panel := _panel(center, "● REC   CAM 09-A  /  OCT 14 2004  /  02:11:36", 330)
	camera_view = CameraArt.new()
	camera_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	camera_panel.add_child(camera_view)
	var dialog_panel := _panel(center, "// INCOMING TRANSCRIPT", 205)
	speaker_label = Label.new()
	speaker_label.add_theme_color_override("font_color", AMBER)
	speaker_label.add_theme_font_size_override("font_size", 13)
	dialog_panel.add_child(speaker_label)
	dialogue_label = RichTextLabel.new()
	dialogue_label.bbcode_enabled = true
	dialogue_label.fit_content = true
	dialogue_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialogue_label.add_theme_color_override("default_color", Color("#d4e6dc"))
	dialog_panel.add_child(dialogue_label)
	choices_box = VBoxContainer.new()
	choices_box.add_theme_constant_override("separation", 4)
	dialog_panel.add_child(choices_box)
	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 205
	right.add_theme_constant_override("separation", 7)
	body.add_child(right)
	var status_panel := _panel(right, "// SYSTEM STATUS", 125)
	status_label = Label.new()
	status_label.text = "● ARCHIVE STANDBY\n● READ ONLY\n● LINK: SECURE?\n\nMEMORY 04 / 16 MB"
	status_label.add_theme_color_override("font_color", TEAL)
	status_panel.add_child(status_label)
	var log_panel := _panel(right, "// KERNEL LOG", 180)
	var log_text := RichTextLabel.new()
	log_text.bbcode_enabled = true
	log_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_panel.add_child(log_text)
	log_text.append_text("[color=#89a9a0]01:42:08  ARCHIVE READY\n01:42:09  CAM INDEX: 09\n01:42:10  USER: GHOST\n01:42:11  TRACE: PENDING[/color]")
	var save_button := _button("SAVE CASE", _save_case)
	right.add_child(save_button)
	var menu_button := _button("RETURN TO MENU", _show_menu)
	right.add_child(menu_button)
	var controls := Label.new()
	controls.text = "F5  SAVE CASE\nESC  PAUSE / MENU"
	controls.add_theme_color_override("font_color", MUTED)
	right.add_child(controls)
	_add_line(root)
	var footer := HBoxContainer.new()
	root.add_child(footer)
	var footer_label := Label.new()
	footer_label.text = "HAWTHORNE DIGITAL EVIDENCE ROOM"
	footer_label.add_theme_color_override("font_color", MUTED)
	footer.add_child(footer_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)
	var build := Label.new()
	build.text = "BUILD 0.9.26   //   ACTIVITY LOGGED"
	build.add_theme_color_override("font_color", MUTED)
	footer.add_child(build)
	_build_menu()
	_build_loading_overlay()
	game_shell.visible = false

func _build_menu() -> void:
	menu_overlay = Control.new()
	menu_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(menu_overlay)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color("#050d0f")
	menu_overlay.add_child(shade)
	var card := PanelContainer.new()
	card.anchor_left = 0.5
	card.anchor_top = 0.5
	card.anchor_right = 0.5
	card.anchor_bottom = 0.5
	card.offset_left = -270
	card.offset_top = -225
	card.offset_right = 270
	card.offset_bottom = 225
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.border_color = TEAL
	style.set_border_width_all(1)
	card.add_theme_stylebox_override("panel", style)
	menu_overlay.add_child(card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	card.add_child(column)
	var title := Label.new()
	title.text = "▣  DEAD AIR"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", TEAL)
	column.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "A COLD CASE IN THE STATIC"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", AMBER)
	column.add_child(subtitle)
	var intro := Label.new()
	intro.text = "HAWTHORNE HOTEL  /  ARCHIVE 09\nA lost night. A dead signal. One witness left on tape."
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro.add_theme_color_override("font_color", MUTED)
	column.add_child(intro)
	column.add_child(_button("START NEW CASE", _new_case))
	column.add_child(_button("CONTINUE CURRENT CASE", _continue_case))
	var load_button := _button("LOAD SAVED CASE", _load_saved_case)
	load_button.disabled = not _has_save()
	column.add_child(load_button)
	column.add_child(_button("EXIT", func(): get_tree().quit()))
	var hint := Label.new()
	hint.text = "Click choices to inspect alternate camera angles"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_color_override("font_color", MUTED)
	column.add_child(hint)

func _build_loading_overlay() -> void:
	loading_overlay = Control.new()
	loading_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	loading_overlay.visible = false
	add_child(loading_overlay)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color("#050d0f")
	loading_overlay.add_child(shade)
	var stack := VBoxContainer.new()
	stack.anchor_left = 0.2
	stack.anchor_top = 0.42
	stack.anchor_right = 0.8
	stack.anchor_bottom = 0.58
	stack.add_theme_constant_override("separation", 12)
	loading_overlay.add_child(stack)
	loading_label = Label.new()
	loading_label.text = "MOUNTING SECURITY ARCHIVE…"
	loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	loading_label.add_theme_color_override("font_color", TEAL)
	stack.add_child(loading_label)
	loading_bar = ProgressBar.new()
	loading_bar.min_value = 0
	loading_bar.max_value = 100
	loading_bar.value = 0
	stack.add_child(loading_bar)

func _panel(parent: Node, title_text: String, minimum_height: int) -> VBoxContainer:
	var shell := PanelContainer.new()
	shell.custom_minimum_size.y = minimum_height
	shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.border_color = LINE_COLOR
	style.set_border_width_all(1)
	shell.add_theme_stylebox_override("panel", style)
	parent.add_child(shell)
	var inner := VBoxContainer.new()
	inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inner.add_theme_constant_override("separation", 6)
	shell.add_child(inner)
	var heading := Label.new()
	heading.text = title_text
	heading.add_theme_font_size_override("font_size", 11)
	heading.add_theme_color_override("font_color", TEAL)
	inner.add_child(heading)
	return inner

func _button(label_text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = label_text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = 32
	button.add_theme_color_override("font_color", TEAL)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#102a2a")
	normal.border_color = LINE_COLOR
	normal.set_border_width_all(1)
	button.add_theme_stylebox_override("normal", normal)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color("#1a4540")
	hover.border_color = TEAL
	hover.set_border_width_all(1)
	button.add_theme_stylebox_override("hover", hover)
	button.pressed.connect(callback)
	return button

func _add_line(parent: Node) -> void:
	var line := ColorRect.new()
	line.color = LINE_COLOR
	line.custom_minimum_size.y = 1
	parent.add_child(line)

func _show_menu() -> void:
	if archive_room:
		archive_room.set_active(false)
	game_shell.visible = false
	loading_overlay.visible = false
	menu_overlay.visible = true
	var load_button := _find_button(menu_overlay, "LOAD SAVED CASE")
	if load_button:
		load_button.disabled = not _has_save()

func _find_button(node: Node, caption: String) -> Button:
	if node is Button and node.text == caption:
		return node
	for child in node.get_children():
		var found_button := _find_button(child, caption)
		if found_button:
			return found_button
	return null

func _new_case() -> void:
	flags.clear()
	if archive_room:
		archive_room.reset_scan({})
	current_id = "boot"
	session_started = true
	_begin_archive_load(false)

func _continue_case() -> void:
	if not session_started:
		if _has_save():
			_load_saved_case()
		else:
			_new_case()
		return
	menu_overlay.visible = false
	loading_overlay.visible = false
	game_shell.visible = true
	_show_story(current_id)

func _load_saved_case() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	var saved_flags: PackedStringArray = config.get_value("case", "flags", PackedStringArray())
	flags.clear()
	for flag in saved_flags:
		flags[flag] = true
	current_id = str(config.get_value("case", "scene", "boot"))
	if not STORY.has(current_id):
		current_id = "boot"
	session_started = true
	_begin_archive_load(true)

func _begin_archive_load(restore: bool) -> void:
	menu_overlay.visible = false
	game_shell.visible = false
	loading_overlay.visible = true
	loading_bar.value = 0
	loading_label.text = "MOUNTING SECURITY ARCHIVE…  0%"
	loading_elapsed = 0.0
	restore_after_load = restore
	if archive_room:
		_show_loaded_game()
		return
	var error := ResourceLoader.load_threaded_request(ROOM_PATH, "PackedScene")
	if error != OK:
		loading_label.text = "Archive request failed. Return to the terminal and try again."
		menu_overlay.visible = true
		loading_overlay.visible = false
		return
	pending_load = true

func _finish_threaded_load() -> void:
	pending_load = false
	var packed := ResourceLoader.load_threaded_get(ROOM_PATH) as PackedScene
	if packed == null:
		loading_overlay.visible = false
		menu_overlay.visible = true
		return
	archive_room = packed.instantiate()
	archive_room.connect("clue_found", _on_archive_clue_found)
	camera_view.add_child(archive_room)
	call_deferred("_resize_archive_room")
	_show_loaded_game()

func _show_loaded_game() -> void:
	loading_overlay.visible = false
	menu_overlay.visible = false
	game_shell.visible = true
	if restore_after_load:
		archive_room.reset_scan(flags)
		_show_story(current_id)
	else:
		_show_story("boot")
	restore_after_load = false

func _resize_archive_room() -> void:
	if archive_room and camera_view:
		archive_room.set_view_size(camera_view.size)

func _show_story(id: String) -> void:
	current_id = id
	var beat: Dictionary = STORY.get(id, STORY["boot"])
	speaker_label.text = "// " + str(beat.get("speaker", ""))
	dialogue_label.text = str(beat.get("text", ""))
	camera_view.set_feed(str(beat.get("feed", "hallway")))
	if archive_room:
		archive_room.set_feed(str(beat.get("feed", "hallway")))
		archive_room.set_active(id == "scan")
	if beat.has("flag"):
		flags[str(beat["flag"])] = true
		_update_evidence()
	for child in choices_box.get_children():
		child.queue_free()
	if beat.get("ending", false):
		status_label.text = "● CASE COMPLETE\n● LINK LOST\n● TRACE: ACTIVE\n\nSAVE: AVAILABLE"
		_add_choice("↻  RESTART CASE", "boot")
	else:
		for option in beat.get("choices", []):
			var requirement := str(option[2])
			if _requirements_met(requirement):
				_add_choice(str(option[0]), str(option[1]))
		status_label.text = "● ARCHIVE MOUNTED\n● READ ONLY\n● CONNECTION: POOR\n\nEVIDENCE %02d / 08" % flags.size()
func _requirements_met(requirement: String) -> bool:
	if requirement.is_empty():
		return true
	for part in requirement.split("+"):
		if not flags.has(part):
			return false
	return true

func _add_choice(caption: String, target: String) -> void:
	var button := _button("›  " + caption, func(): _choose(target))
	choices_box.add_child(button)

func _choose(target: String) -> void:
	if target == "boot":
		flags.clear()
		if archive_room:
			archive_room.reset_scan({})
		session_started = true
		_update_evidence()
	_show_story(target)
	if target.begins_with("ending_"):
		_save_case()
func _save_case() -> void:
	if current_id.is_empty():
		return
	var config := ConfigFile.new()
	config.set_value("case", "scene", current_id)
	var saved_flags := PackedStringArray()
	for key in flags.keys():
		saved_flags.append(str(key))
	config.set_value("case", "flags", saved_flags)
	config.set_value("case", "version", 1)
	var error := config.save(SAVE_PATH)
	if error == OK and status_label:
		status_label.text = "● CASE SAVED\n● user://archive09_save.cfg\n● RESUME AVAILABLE\n\nEVIDENCE %02d / 08" % flags.size()
		menu_overlay.visible = menu_overlay.visible
		var load_button := _find_button(menu_overlay, "LOAD SAVED CASE")
		if load_button:
			load_button.disabled = false

func _has_save() -> bool:
	var config := ConfigFile.new()
	return config.load(SAVE_PATH) == OK and config.has_section_key("case", "scene")

func _on_archive_clue_found(clue_id: String) -> void:
	var mapping := {"timecode":"scan_time", "keytag":"key", "fiber":"scan_fiber"}
	if mapping.has(clue_id):
		flags[mapping[clue_id]] = true
	_update_evidence()
	if current_id == "scan":
		var total := int(flags.has("scan_time")) + int(flags.has("key")) + int(flags.has("scan_fiber"))
		dialogue_label.text = "Manual sweep active. Recovered %d of 3 markers. Keep moving through the frame to collect the rest." % total
	if flags.has("scan_time") and flags.has("key") and flags.has("scan_fiber"):
		status_label.text = "● ALL MARKERS RECOVERED\n● CLIP HASH VERIFIED\n● EVIDENCE READY"

func _update_evidence() -> void:
	if evidence_label == null:
		return
	var entries := []
	var labels := {"header":"Camera tampering / E.V.", "time_gap":"Timestamp mismatch", "cup":"Guard's false report", "thread":"Red wool fiber", "key":"Master key / tag 09", "memo":"Maintenance memo", "backup":"Orphaned audio backup", "scan_time":"Missing timecode", "scan_fiber":"Recovered fiber"}
	for key in labels:
		if flags.has(key):
			entries.append("[color=#65e6c0]✓[/color] " + labels[key])
	evidence_label.text = "\n".join(entries) if not entries.is_empty() else "[color=#89a9a0]No evidence secured.[/color]"

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if menu_overlay.visible:
				return
			_show_menu()
		elif event.keycode == KEY_F5 and game_shell.visible:
			_save_case()

class OperatorPortrait:
	extends Control
	func _draw() -> void:
		var w := size.x
		var h := size.y
		draw_rect(Rect2(Vector2.ZERO, size), Color("#081315"))
		draw_circle(Vector2(w * 0.50, h * 0.37), h * 0.25, Color("#26363a"))
		draw_rect(Rect2(w * 0.27, h * 0.54, w * 0.46, h * 0.49), Color("#101d24"))
		draw_circle(Vector2(w * 0.42, h * 0.37), 3, Color("#6ee3c3"))
		draw_circle(Vector2(w * 0.58, h * 0.37), 3, Color("#6ee3c3"))
		draw_line(Vector2(w * 0.44, h * 0.49), Vector2(w * 0.56, h * 0.49), Color("#78908d"), 1)
		for y in range(0, int(h), 4):
			draw_line(Vector2(0, y), Vector2(w, y), Color(0, 0, 0, 0.16), 1)
		draw_string(ThemeDB.fallback_font, Vector2(8, h - 8), "OPERATOR // ONLINE", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, TEAL)

class CameraArt:
	extends Control
	var feed_id := "hallway"
	func set_feed(value: String) -> void:
		feed_id = value
		queue_redraw()
	func _draw() -> void:
		var w := size.x
		var h := size.y
		var background := Color("#111d19")
		if feed_id in ["stairs", "fiber", "cup"]: background = Color("#181a19")
		elif feed_id in ["lobby", "reflection", "backup", "memo"]: background = Color("#1a211b")
		elif feed_id.begins_with("ending"): background = Color("#081516")
		draw_rect(Rect2(Vector2.ZERO, size), background)
		draw_rect(Rect2(w * 0.08, h * 0.10, w * 0.84, h * 0.74), Color("#202a22"))
		draw_line(Vector2(w * 0.08, h * 0.1), Vector2(w * 0.36, h * 0.48), Color("#536457"), 2)
		draw_line(Vector2(w * 0.92, h * 0.1), Vector2(w * 0.64, h * 0.48), Color("#536457"), 2)
		draw_line(Vector2(w * 0.5, h * 0.48), Vector2(w * 0.08, h * 0.84), Color("#75816e"), 2)
		draw_line(Vector2(w * 0.5, h * 0.48), Vector2(w * 0.92, h * 0.84), Color("#75816e"), 2)
		for i in range(5):
			var yy := h * (0.23 + i * 0.12)
			draw_line(Vector2(w * (0.25 - i * 0.025), yy), Vector2(w * (0.75 + i * 0.025), yy), Color("#30443b"), 1)
		if feed_id in ["stairs", "fiber", "cup"]:
			draw_rect(Rect2(w * 0.72, h * 0.22, w * 0.13, h * 0.40), Color("#0b1413"))
			draw_circle(Vector2(w * 0.52, h * 0.39), h * 0.045, Color("#899285"))
			draw_colored_polygon(PackedVector2Array([Vector2(w * 0.49, h * 0.44), Vector2(w * 0.57, h * 0.44), Vector2(w * 0.60, h * 0.69), Vector2(w * 0.46, h * 0.69)]), Color("#a19b7f"))
		elif feed_id in ["lobby", "reflection", "backup", "memo"]:
			draw_rect(Rect2(w * 0.66, h * 0.20, w * 0.21, h * 0.44), Color("#101c19"))
			draw_rect(Rect2(w * 0.69, h * 0.23, w * 0.15, h * 0.37), Color("#2a362d"))
			draw_circle(Vector2(w * 0.76, h * 0.40), h * 0.035, Color("#a28c66"))
		else:
			draw_rect(Rect2(w * 0.74, h * 0.23, w * 0.12, h * 0.35), Color("#0b1413"))
			draw_circle(Vector2(w * 0.53, h * 0.39), h * 0.045, Color("#899285"))
			draw_colored_polygon(PackedVector2Array([Vector2(w * 0.49, h * 0.44), Vector2(w * 0.57, h * 0.44), Vector2(w * 0.60, h * 0.69), Vector2(w * 0.46, h * 0.69)]), Color("#a19b7f"))
		if feed_id == "index_check":
			draw_rect(Rect2(w * 0.12, h * 0.16, w * 0.76, h * 0.60), Color("#0b1413"))
			draw_string(ThemeDB.fallback_font, Vector2(w * 0.17, h * 0.35), "CAM 09-A  OFFLINE", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#f3b96b"))
			draw_string(ThemeDB.fallback_font, Vector2(w * 0.17, h * 0.48), "CHECKSUM UPDATED 02:17:43", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#65e6c0"))
		elif feed_id == "shift_report":
			draw_rect(Rect2(w * 0.22, h * 0.12, w * 0.56, h * 0.66), Color("#c8c2a4"))
			draw_string(ThemeDB.fallback_font, Vector2(w * 0.28, h * 0.30), "NIGHT SHIFT / 14 OCT 04", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#17221e"))
			draw_string(ThemeDB.fallback_font, Vector2(w * 0.28, h * 0.43), "01:55  SIGNED OUT", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#17221e"))
			draw_string(ThemeDB.fallback_font, Vector2(w * 0.28, h * 0.56), "02:11  EAST WING?", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#8f3934"))
		for y in range(0, int(h), 3):
			draw_line(Vector2(0, y), Vector2(w, y), Color(0, 0, 0, 0.20), 1)
		var feed_label := "CAM 09-A  REC"
		var time_label := "02:11:36"
		if feed_id in ["stairs", "fiber", "cup"]:
			feed_label = "CAM 12-C  REC"
		elif feed_id in ["lobby", "reflection", "backup", "memo"]:
			feed_label = "CAM 01-A  REC"
		elif feed_id == "index_check":
			feed_label = "INDEX COMPARE"
			time_label = "02:17:43"
		elif feed_id == "shift_report":
			feed_label = "SHIFT ROSTER"
			time_label = "14 OCT 2004"
		draw_string(ThemeDB.fallback_font, Vector2(12, 21), feed_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#e58a65"))
		draw_string(ThemeDB.fallback_font, Vector2(w - 108, 21), time_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#d3e3c8"))
		draw_string(ThemeDB.fallback_font, Vector2(12, h - 8), "SIGNAL LOSS: 03 SEC", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("#a5b6a1"))







