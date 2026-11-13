class_name UnitState
extends RefCounted
## Bitta jangchining holati (faqat ma'lumot, chizish yo'q).

enum State { IDLE, MOVE, ATTACK, MINE_GO, MINING, RETURN, DEAD }

var id: int = 0
var type: String = ""
var def: Dictionary = {}
var team: int = 0
var x: float = 0.0
var lane: float = 0.5          ## 0..1, chuqurlik (vizual)
var hp: float = 1.0
var max_hp: float = 1.0
var state: int = State.IDLE
var cooldown: float = 0.0
var carrying: int = 0
var mine_timer: float = 0.0
var attack_anim: float = 0.0   ## >0 bo'lsa, zarba animatsiyasi davom etmoqda
var walk_phase: float = 0.0
var moving: bool = false
var facing: int = 1
var hurt_flash: float = 0.0
var dead_time: float = 0.0
var controlled: bool = false
var slot: float = 0.0          ## safdagi joy siljishi


func is_alive() -> bool:
	return state != State.DEAD


func has_tag(t: String) -> bool:
	return t in def.get("tags", [])


func is_worker() -> bool:
	return def.get("class", "") == "worker"


func is_ranged() -> bool:
	return def.get("class", "") == "ranged"


func value() -> float:
	## Qo'shin kuchini baholash uchun (AI ishlatadi).
	return float(def.get("cost", 0)) * (hp / max_hp)
