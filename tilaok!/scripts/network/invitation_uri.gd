class_name InvitationUri
extends RefCounted

const SCHEME_PREFIX := "tilaok://join?"
const MAX_URI_BYTES := 512
const REQUIRED_FIELDS := ["lobby", "host", "port", "protocol", "digest", "code", "epoch", "expires"]
const LOBBY_ALPHABET := "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"


static func parse(uri: String) -> Dictionary:
	var bytes := uri.to_utf8_buffer()
	if bytes.size() > MAX_URI_BYTES or not uri.begins_with(SCHEME_PREFIX):
		return {"ok": false, "error": "This is not a supported Tilaok! invitation."}
	var query := uri.substr(SCHEME_PREFIX.length())
	if query.is_empty() or query.contains("#") or query.contains("%") or query.contains("+"):
		return {"ok": false, "error": "The invitation contains unsupported encoding."}
	var fields := {}
	for component in query.split("&", false):
		var pair := component.split("=", false, 2)
		if pair.size() != 2 or pair[0].is_empty() or fields.has(pair[0]):
			return {"ok": false, "error": "The invitation has a missing or repeated field."}
		fields[pair[0]] = pair[1]
	if fields.size() != REQUIRED_FIELDS.size():
		return {"ok": false, "error": "The invitation is missing required fields."}
	for field in REQUIRED_FIELDS:
		if not fields.has(field) or str(fields[field]).is_empty():
			return {"ok": false, "error": "The invitation is missing required fields."}
	var lobby := str(fields.lobby)
	if not _valid_lobby_id(lobby):
		return {
			"ok": false,
			"error": "Scanned Lobby ID '%s' is invalid; expected 13 Base32 characters." % lobby,
		}
	if lobby[0] > "B":
		return {
			"ok": false,
			"error": "Scanned Lobby ID '%s' is outside the supported range." % lobby,
		}
	var host := str(fields.host)
	if not _valid_ipv4(host):
		return {"ok": false, "error": "The host address is invalid."}
	var port_text := str(fields.port)
	if not port_text.is_valid_int() or port_text.length() > 5:
		return {"ok": false, "error": "The host port is invalid."}
	var port := int(port_text)
	if port < 1024 or port > 65535 or str(port) != port_text:
		return {"ok": false, "error": "The host port is outside the supported range."}
	if str(fields.protocol) != "%d.%d" % [NetworkFrame.MAJOR, NetworkFrame.MINOR]:
		return {"ok": false, "error": "This invitation uses an unsupported protocol version."}
	var digest_text := str(fields.digest)
	if digest_text.length() != 64 or not _is_hex(digest_text):
		return {"ok": false, "error": "The compatibility digest is invalid."}
	var code := str(fields.code)
	if code.length() != 26 or code != code.to_upper() or InvitationCode.decode(code).size() != 16:
		return {"ok": false, "error": "The invitation access code is invalid."}
	var epoch_text := str(fields.epoch)
	if not epoch_text.is_valid_int() or epoch_text.length() > 20:
		return {"ok": false, "error": "The host session identifier is invalid."}
	var epoch := int(epoch_text)
	if epoch <= 0 or str(epoch) != epoch_text:
		return {"ok": false, "error": "The host session identifier is invalid."}
	var expires_text := str(fields.expires)
	if not expires_text.is_valid_int() or expires_text.length() > 20:
		return {"ok": false, "error": "The invitation expiry is invalid."}
	var expires := int(expires_text)
	if expires <= 0 or str(expires) != expires_text:
		return {"ok": false, "error": "The invitation expiry is invalid."}
	var digest := PackedByteArray()
	digest.append_array(digest_text.hex_decode())
	return {
		"ok": true,
		"lobby_id": lobby,
		"address": host,
		"port": port,
		"protocol": str(fields.protocol),
		"digest": digest,
		"code": code,
		"epoch": epoch,
		"expires_unix": expires,
	}


static func _valid_lobby_id(value: String) -> bool:
	if value.length() != 13:
		return false
	for character in value:
		if LOBBY_ALPHABET.find(character) < 0:
			return false
	return true


static func _valid_ipv4(value: String) -> bool:
	var parts := value.split(".", false)
	if parts.size() != 4:
		return false
	for part in parts:
		if part.is_empty() or not part.is_valid_int() or part.length() > 3:
			return false
		var octet := int(part)
		if octet < 0 or octet > 255 or str(octet) != part:
			return false
	var first_octet := int(parts[0])
	return (
		value != "0.0.0.0"
		and value != "255.255.255.255"
		and not value.begins_with("127.")
		and not (first_octet >= 224 and first_octet <= 239)
	)


static func _is_hex(value: String) -> bool:
	for character in value.to_lower():
		if "0123456789abcdef".find(character) < 0:
			return false
	return true
