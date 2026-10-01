extends Button
class_name CCButton
## Kreslené tlačítko: zaoblené, s „3D“ hranou, leskem a výrazným písmem.
## Při stisku se zmáčkne a pruží zpět.

var caption := ""
var color := Color("6fcf2f")
var font_size := 30
var radius := 18.0
var icon_key := ""          ## upečená ikona (Baker) vlevo od textu
var icon_scale := 0.5
var sub := ""               ## malý text pod popiskem (např. cena)
var sub_icon := ""          ## ikona u malého textu (např. "coin")
var badge := ""             ## červený odznak v rohu


static func make(text_: String, col: Color, sz: Vector2, fs: int = 30) -> CCButton:
	var bt := CCButton.new()
	bt.caption = text_
	bt.color = col
	bt.custom_minimum_size = sz
	bt.size = sz
	bt.font_size = fs
	return bt


func _init() -> void:
	flat = true
	focus_mode = Control.FOCUS_NONE
	var empty := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "focus", "disabled", "hover_pressed"]:
		add_theme_stylebox_override(st, empty)
	button_down.connect(_on_down)
	button_up.connect(_on_up)
	resized.connect(func(): pivot_offset = size * 0.5)


func _on_down() -> void:
	Sfx.play("click", -6.0, 0.05, 0.0)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(0.94, 0.94), 0.06)


func _on_up() -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	var col := color if not disabled else Color("9aa0a6")
	var pressed := get_draw_mode() == DRAW_PRESSED or get_draw_mode() == DRAW_HOVER_PRESSED
	var face := Art.button(self, Rect2(Vector2.ZERO, size), col, pressed, radius)
	var cy := face.get_center().y
	var tx := face.get_center().x
	var has_sub := sub != ""
	var ty := cy + font_size * 0.36 - (font_size * 0.32 if has_sub else 0.0)
	if icon_key != "" and Baker.has(icon_key):
		var tex := Baker.tex(icon_key)
		var isz := tex.get_size() * icon_scale
		var tw := Art.text_width(caption, font_size)
		var total := isz.x + 6.0 + tw
		var ix := tx - total * 0.5
		if caption == "":
			ix = tx - isz.x * 0.5
		draw_texture_rect(tex, Rect2(Vector2(ix, cy - isz.y * 0.5 - (font_size * 0.3 if has_sub else 0.0)), isz), false)
		tx = ix + isz.x + 6.0 + tw * 0.5
	if caption != "":
		Art.text(self, Vector2(tx, ty), caption, font_size, Color.WHITE if not disabled else Color("e0e0e0"), maxi(5, font_size / 4))
	if has_sub:
		var sfs := int(font_size * 0.62)
		var sw := Art.text_width(sub, sfs)
		var sx := face.get_center().x
		if sub_icon != "" and Baker.has("icon:" + sub_icon):
			var t2 := Baker.tex("icon:" + sub_icon)
			var s2 := Vector2(sfs, sfs) * 1.2
			draw_texture_rect(t2, Rect2(Vector2(sx - (sw + s2.x) * 0.5 - 2, cy + font_size * 0.12), s2), false)
			sx += s2.x * 0.5
		Art.text(self, Vector2(sx, cy + font_size * 0.12 + sfs * 0.95), sub, sfs, Color("fff6c8"), 5)
	if badge != "":
		var bc := Vector2(size.x - 8, 8)
		Art.circle(self, bc, 13, Color("e2382c"), 2.5)
		Art.text(self, bc + Vector2(0, 6), badge, 16, Color.WHITE, 4)
