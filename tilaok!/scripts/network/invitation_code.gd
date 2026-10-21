class_name InvitationCode
extends RefCounted

const ALPHABET := "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
## v1 §2 `auth_context`: invitation join (0) or seat reclaim (1, keyed by the reclaim token).
const CONTEXT_JOIN := 0
const CONTEXT_RECLAIM := 1


static func generate() -> PackedByteArray:
	return Crypto.new().generate_random_bytes(16)


static func encode(bytes: PackedByteArray) -> String:
	var bits := 0
	var value := 0
	var out := ""
	for byte in bytes:
		value = (value << 8) | int(byte)
		bits += 8
		while bits >= 5:
			bits -= 5
			out += ALPHABET[(value >> bits) & 31]
		value = value & ((1 << bits) - 1)
	if bits > 0:
		out += ALPHABET[(value << (5 - bits)) & 31]
	return out


static func decode(code: String) -> PackedByteArray:
	var normalized := code.to_upper().replace("-", "").replace(" ", "")
	if normalized.length() != 26:
		return PackedByteArray()
	var bits := 0
	var value := 0
	var out := PackedByteArray()
	for character in normalized:
		var digit := ALPHABET.find(character)
		if digit < 0:
			return PackedByteArray()
		value = (value << 5) | digit
		bits += 5
		if bits >= 8:
			bits -= 8
			out.append((value >> bits) & 0xff)
			value = value & ((1 << bits) - 1)
	if out.size() != 16 or (value & 3) != 0:
		return PackedByteArray()
	return out


static func proof(
	token: PackedByteArray,
	epoch: int,
	client_nonce: PackedByteArray,
	server_nonce: PackedByteArray,
	auth_context: int = CONTEXT_JOIN
) -> PackedByteArray:
	if (
		token.size() != 16
		or client_nonce.size() != 16
		or server_nonce.size() != 16
		or auth_context not in [CONTEXT_JOIN, CONTEXT_RECLAIM]
	):
		return PackedByteArray()
	var transcript := "TILK-AUTH-v1".to_utf8_buffer()
	var stream := StreamPeerBuffer.new()
	stream.big_endian = false
	stream.put_u64(epoch)
	stream.put_data(client_nonce)
	stream.put_data(server_nonce)
	stream.put_u8(auth_context)
	stream.put_u8(NetworkFrame.MAJOR)
	stream.put_u8(NetworkFrame.MINOR)
	transcript.append_array(stream.data_array)
	return Crypto.new().hmac_digest(HashingContext.HASH_SHA256, token, transcript)
