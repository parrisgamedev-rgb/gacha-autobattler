extends Node
## Network manager singleton for PvP multiplayer
## Handles ENet peer-to-peer connections with room code system

signal player_connected(id: int)
signal player_disconnected(id: int)
signal connection_failed
signal connection_succeeded
signal server_started

enum NetworkRole { NONE, HOST, CLIENT }

var role: NetworkRole = NetworkRole.NONE
var peer_id: int = 0
var connected_peers: Array[int] = []
var current_room_code: String = ""
var hosted_port: int = 0

const DEFAULT_PORT = 7777
const MAX_CLIENTS = 1  # PvP is 1v1
const CODE_CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"  # Excludes confusing chars (0/O, 1/I)

func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func host_game(port: int = DEFAULT_PORT) -> Error:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, MAX_CLIENTS)
	if error != OK:
		print("Failed to create server: ", error)
		return error

	multiplayer.multiplayer_peer = peer
	role = NetworkRole.HOST
	peer_id = 1  # Host is always peer ID 1
	hosted_port = port

	# Generate room code from local IP and port
	current_room_code = _generate_room_code(port)

	print("Server started on port ", port)
	print("Room code: ", current_room_code)
	server_started.emit()
	return OK

func join_game(ip: String, port: int = DEFAULT_PORT) -> Error:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip, port)
	if error != OK:
		print("Failed to create client: ", error)
		return error

	multiplayer.multiplayer_peer = peer
	role = NetworkRole.CLIENT
	print("Connecting to ", ip, ":", port)
	return OK

func join_with_code(room_code: String) -> Error:
	var connection_info = _parse_room_code(room_code)
	if connection_info.is_empty():
		print("Invalid room code!")
		return ERR_INVALID_PARAMETER

	return join_game(connection_info.ip, connection_info.port)

func get_room_code() -> String:
	return current_room_code

func _get_local_ip() -> String:
	# Get the best local IP address for LAN play
	var addresses = IP.get_local_addresses()

	# Prefer IPv4 private network addresses
	for addr in addresses:
		if addr.begins_with("192.168.") or addr.begins_with("10.") or addr.begins_with("172."):
			return addr

	# Fallback to first non-localhost IPv4
	for addr in addresses:
		if "." in addr and not addr.begins_with("127."):
			return addr

	return "127.0.0.1"

func _generate_room_code(port: int) -> String:
	var ip = _get_local_ip()
	print("Generating room code for IP: ", ip, " port: ", port)
	var parts = ip.split(".")
	if parts.size() != 4:
		return "ERROR"

	# Encode as simple format: each octet as 2-char hex + port as 4-char hex
	# This gives us: AA.BB.CC.DD:PORT -> AABBCCDDPPPP (12 hex chars)
	var hex_code = ""
	for i in range(4):
		hex_code += "%02X" % int(parts[i])
	hex_code += "%04X" % port

	# Format as XXXX-XXXX-XXXX
	var formatted = hex_code.substr(0, 4) + "-" + hex_code.substr(4, 4) + "-" + hex_code.substr(8, 4)
	print("Generated room code: ", formatted)
	return formatted

func _parse_room_code(room_code: String) -> Dictionary:
	# Remove formatting and convert to uppercase
	var code = room_code.replace("-", "").replace(" ", "").to_upper()
	print("Parsing room code: ", code)

	if code.length() != 12:
		print("Invalid code length: ", code.length())
		return {}

	# Validate hex characters
	for c in code:
		if c not in "0123456789ABCDEF":
			print("Invalid character: ", c)
			return {}

	# Parse hex values
	var ip_parts = []
	for i in range(4):
		var hex_part = code.substr(i * 2, 2)
		ip_parts.append(str(hex_part.hex_to_int()))

	var port_hex = code.substr(8, 4)
	var port = port_hex.hex_to_int()

	var ip = ".".join(ip_parts)
	print("Parsed IP: ", ip, " port: ", port)

	return {"ip": ip, "port": port}

func disconnect_from_game():
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	role = NetworkRole.NONE
	peer_id = 0
	connected_peers.clear()
	current_room_code = ""
	hosted_port = 0
	print("Disconnected from game")

func is_host() -> bool:
	return role == NetworkRole.HOST

func is_client() -> bool:
	return role == NetworkRole.CLIENT

func is_connected_to_game() -> bool:
	return role != NetworkRole.NONE and multiplayer.multiplayer_peer != null

func get_local_player_id() -> int:
	# Host is player 1, client is player 2
	if is_host():
		return 1
	elif is_client():
		return 2
	return 0

func has_opponent() -> bool:
	if is_host():
		return connected_peers.size() > 0
	elif is_client():
		return is_connected_to_game()
	return false

func _on_peer_connected(id: int):
	print("Peer connected: ", id)
	connected_peers.append(id)
	player_connected.emit(id)

func _on_peer_disconnected(id: int):
	print("Peer disconnected: ", id)
	connected_peers.erase(id)
	player_disconnected.emit(id)

func _on_connected_to_server():
	peer_id = multiplayer.get_unique_id()
	print("Connected to server with ID: ", peer_id)
	connection_succeeded.emit()

func _on_connection_failed():
	print("Connection failed!")
	role = NetworkRole.NONE
	connection_failed.emit()

func _on_server_disconnected():
	print("Server disconnected!")
	role = NetworkRole.NONE
	peer_id = 0
	connected_peers.clear()
	player_disconnected.emit(1)
