extends CanvasLayer

@onready var hearts: Array[TextureRect] = [
	$HeartCointainer/Heart1,
	$HeartCointainer/Heart2,
	$HeartCointainer/Heart3,
]
@onready var label_coin: Label = $CoinContainer/LabelCoin

func _ready() -> void:
	_on_hearts_changed(GameManager.hearts)
	_on_coins_changed(GameManager.coins)
	GameManager.hearts_changed.connect(_on_hearts_changed)
	GameManager.coins_changed.connect(_on_coins_changed)

func _on_hearts_changed(current: int) -> void:
	for i in hearts.size():
		hearts[i].modulate.a = 1.0 if i < current else 0.0

func _on_coins_changed(coins: int) -> void:
	label_coin.text = str(coins)
