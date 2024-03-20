extends Node


class_name WorldSave

var elapsed_ticks = 0
var seed = 0
var world_name:String
var world_size:int # world length in chunks
var chunk_size:int # chunk length in tiles
var chunk_area:int
var bounds:Rect2i
var central_storage:Dictionary = {}

var tiledata = []
var noise = []
var tiles = []
var items = []
var terrain = []
var integrity = []
var tile_storage = []

var sandworm_noise_threshold = 30
var sandworm_attack_cooldown = 50
var sandworm_current_cooldown = 0

