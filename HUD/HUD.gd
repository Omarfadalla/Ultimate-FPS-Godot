extends CanvasLayer

## PLAYER HUD
## Handles: red screen flash on damage, floating "-N" damage number,
## a health bar, an ammo counter, and a "YOU'RE DEAD" death screen.
##
## Expected children (see hud.tscn):
##   - DamageFlash (ColorRect, full-rect, starts transparent red)
##   - DeathLabel  (Label, centered, starts hidden)
##   - HealthBar   (ProgressBar, bottom-left)
##   - AmmoLabel   (Label, bottom-right)
##
## Relies on the "global" autoload (global.player set in Player.gd's _ready()).

@export var hud_font: FontFile  # optional: drag your font in for HUD text

@onready var damage_flash: ColorRect = $DamageFlash
@onready var death_label: Label = $DeathLabel
@onready var health_bar: ProgressBar = $HealthBar
@onready var ammo_label: Label = $AmmoLabel


func _ready() -> void:
	damage_flash.color = Color(1, 0, 0, 0)
	death_label.visible = false
	death_label.modulate.a = 0.0

	if hud_font:
		death_label.add_theme_font_override("font", hud_font)
		ammo_label.add_theme_font_override("font", hud_font)

	# Wait a frame so global.player (and its WEAPON_CONTROLLER) are ready.
	await get_tree().process_frame

	if global.player:
		global.player.damaged.connect(_on_player_damaged)
		global.player.died.connect(_on_player_died)
		global.player.health_changed.connect(_on_health_changed)

		# Initialize the health bar to current values immediately.
		health_bar.max_value = global.player.max_health
		health_bar.value = global.player.health

		if global.player.WEAPON_CONTROLLER:
			global.player.WEAPON_CONTROLLER.ammo_changed.connect(_on_ammo_changed)
			ammo_label.text = "%d / %d" % [
				global.player.WEAPON_CONTROLLER.current_ammo,
				global.player.WEAPON_CONTROLLER.magazine_size
			]


func _on_health_changed(current: int, max_health: int) -> void:
	health_bar.max_value = max_health
	health_bar.value = current


func _on_ammo_changed(current_ammo: int, magazine_size: int) -> void:
	ammo_label.text = "%d / %d" % [current_ammo, magazine_size]


func _on_player_damaged(amount: int) -> void:
	_flash_red()
	_show_damage_number(amount)


func _flash_red() -> void:
	damage_flash.color.a = 0.45
	var tween := create_tween()
	tween.tween_property(damage_flash, "color:a", 0.0, 0.4)


func _show_damage_number(amount: int) -> void:
	var label := Label.new()
	label.text = "-%d" % amount
	label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	label.add_theme_font_size_override("font_size", 36)
	if hud_font:
		label.add_theme_font_override("font", hud_font)
	add_child(label)

	var viewport_size := get_viewport().get_visible_rect().size
	label.position = viewport_size / 2 + Vector2(-20, -60)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 40, 0.6)
	tween.tween_property(label, "modulate:a", 0.0, 0.6)
	tween.finished.connect(label.queue_free)


func _on_player_died() -> void:
	death_label.visible = true
	var tween := create_tween()
	tween.tween_property(death_label, "modulate:a", 1.0, 0.6)
	await get_tree().create_timer(2).timeout
	get_tree().quit()
