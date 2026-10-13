class_name UiPhaseBanner
extends PanelContainer

@onready var _phase_label: Label = %PhaseLabel
@onready var _detail_label: Label = %DetailLabel


func set_phase(title: String, detail: String = "") -> void:
	_phase_label.text = title
	_detail_label.text = detail
	_detail_label.visible = not detail.is_empty()


func title_text() -> String:
	return _phase_label.text
