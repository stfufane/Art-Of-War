class_name KingdomUnit
extends Control
## A little scene representing a unit inside the kingdom.
##
## There is one of each [enum Unit.EUnitType] (except the king)
## inside the [Kingdom] scene and they represent the population
## for every unit type.

enum EStatus { ## Compares the unit to the one from enemy kingdom
    Down = 0, ## The unit type has less units than the enemy
    Up = 1, ## The unit type has more units than the enemy
    Equal = 2  ## The unit type has as many units as the enemy
}

## The possible colors of the crown depending on the status
const COLORS: Array[Color] = [
    Color(0.87, 0.0, 0.10, 1.0),
    Color(1.00, 1.0, 0.08, 1.0)
]

## The type of unit to represent so it can load the right texture for the sprite
@export var unit_type: Unit


## The current status of the unit compared to the enemy
var status: EStatus = EStatus.Equal:
    set(s):
        if s != status:
            flash()
        status = s
        if s == EStatus.Equal:
            crown.hide()
            return
        crown.self_modulate = COLORS[s]
        crown.show()


@onready var sprite := $Sprite as TextureRect ## The character sprite
@onready var crown := $Crown as TextureRect ## A little crown icon for the status
@onready var animation := $Sprite/AnimationPlayer as AnimationPlayer


func _ready() -> void:
    var image: CompressedTexture2D = load("res://resources/sprites/" + unit_type.resource_name + ".png")
    sprite.texture = image


## Triggers a little flash animation of the sprite
func flash() -> void:
    animation.queue("flash")
