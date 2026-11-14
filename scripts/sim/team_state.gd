class_name TeamState
extends RefCounted
## Bir tomonning (o'yinchi yoki dushman) holati.

enum Stance { DEFEND, ATTACK, RETREAT }

var index: int = 0
var dir: int = 1               ## +1: chapdan o'ngga hujum qiladi, -1: aksincha
var gold: float = 0.0
var castle_x: float = 0.0
var castle_hp: float = 2000.0
var castle_max_hp: float = 2000.0
var mine_x: float = 0.0
var stance: int = Stance.DEFEND
var queue: Array[String] = []
var train_progress: float = 0.0
var pop: int = 0
var pop_cap: int = 30
var income_mult: float = 1.0
var damage_mult: float = 1.0
var passive_income: float = 2.0
var castle_shot_cd: float = 0.0
var allowed: Array = []        ## Ushbu bosqichda yollash mumkin bo'lgan birliklar
var hero_type: String = ""     ## "" bo'lsa qahramonsiz
var hero_id: int = -1
var hero_respawn: float = 0.0
var ability_cd: float = 8.0
var buff_time: float = 0.0
var buff_dmg: float = 1.0
var buff_speed: float = 1.0
var hp_mult: float = 1.0           ## Ustaxona: askarlar HP
var hero_mult: float = 1.0         ## Ustaxona: qahramon HP va zarari
var castle_dmg_mult: float = 1.0   ## Ustaxona: minora o'qlari
var ability_cd_mult: float = 1.0   ## Ustaxona: maxsus kuch tiklanishi
var stats: Dictionary = {"trained": 0, "killed": 0, "lost": 0, "gold_mined": 0}


func defend_x() -> float:
	return castle_x + dir * 520.0


func retreat_x() -> float:
	return castle_x - dir * 30.0
