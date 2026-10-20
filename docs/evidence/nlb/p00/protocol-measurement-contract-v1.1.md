# NLB-P00 contract clarification — wire minor 1

**Contract version:** wire major 1, minor 1. **Date:** 2026-10-19. **Status:** scoped P02 clarification, implemented with NLB-P02. This record supplements [the reviewed v1 contract](protocol-measurement-contract-v1.md); the original P00 evidence remains preserved.

**Invitation lifecycle amendment (2026-10-20):** the room invitation is reusable for the entire active room lifetime. It is revoked at room stop/rehost only. This corrects the original P02 one-use/300-second behavior; wire framing and family IDs do not change.

**Superseded P03 amendment (2026-10-20):** P03 briefly changed the invitation to one-use/300-second as recorded in its implementation history. At the user's later request on 2026-10-20, the active rule returns to one reusable 128-bit access credential per host room. The code is shared by all joining players and remains valid until the host stops or rehosts. The `tilaok://join` URI uses canonical `expires=0` to mean no time expiry within that room; the host session is the authority and clients do not persist credentials. Each peer still proves possession using its own fresh, single-use challenge. Every join still passes compatibility checks, host approval, and current seat/admission limits. Decline, full capacity, disconnect, or leaving does not consume or rotate the room code. Stopping/rehosting clears it and a new room receives a new code. Raw ENet framing, message families and version 1.1 do not change.

The local `tilaok://join` URI has a required canonical decimal `expires` Unix-seconds query field, validated with the existing 512-byte and duplicate-field limits. `expires=0` denotes the room-lifetime invitation; nonzero canonical values remain parseable for compatibility but the current room-lifetime host does not consume or expire the code by timestamp. The field is a local locator/schema detail, not a wire framing change. Lobby ID/manual IP entry still requires the active room code separately. Invitation credentials remain memory-only and are revoked on room stop/rehost.

## Transport and envelope

P02 uses Godot 4.7.2 `ENetConnection` and `ENetPacketPeer` directly. Each application message is one raw packed-byte packet with the exact 22-byte `TILK` envelope from v1. SceneMultiplayer RPCs, object decoding, peer relay and gameplay families are disabled. P02 allocates one ENet channel and uses channel 0 with `FLAG_RELIABLE` for all control messages. Runtime tests record that packets arrive on channel 0 and complete the production handshake. Additional channels are not used or claimed verified.

Wire major stays 1. Minor advances to 1. A P02 compatibility hello carries the 32-byte manifest digest, major, minor, uint16 schema version, and uint16 feature bitmap. P02 requires feature bits 0–3 (`0x000F`): raw TILK framing, compatibility manifest, invitation proof, and lobby seat/readiness messages. A peer with a different digest or missing required feature is incompatible. Unknown family, enum, flags, or payload shape is `MALFORMED`.

## P02 family allocation

| ID | Family | P02 direction |
|---:|---|---|
| `0x01` | Discovery query | LAN client → local subnet |
| `0x02` | Beacon | Host → local subnet |
| `0x03` | Compatibility hello | Candidate → host |
| `0x04` | Compatibility result | Host → candidate |
| `0x05` | Join begin | Candidate → host |
| `0x06` | Challenge | Host → candidate |
| `0x07` | Proof | Candidate → host |
| `0x08` | Admission decision | Host → candidate |
| `0x09` | Seat assignment | Host → assigned candidate |
| `0x0A` | Assignment acknowledgment | Assigned candidate → host |
| `0x0B` | Lobby state | Host → acknowledged peers |
| `0x0C` | Ready request | Assigned peer → host |
| `0x0D` | Ready result | Host → requesting peer |
| `0x0E` | Session close | Host → peers; assigned peer may send a bounded voluntary-leave notice |

P03 and later families retain their v1 reservations. No P02 family carries gameplay input, transforms, item actions or match-state writes.

## Discovery and invitation lookup

Discovery query payload is `requested_lobby_id:uint64_le` followed by `discovery_port:uint16_le`. Lobby ID zero requests all active beacons; a nonzero ID requests only the matching active lobby. It remains a public lookup key and grants no authority. A beacon includes Lobby ID, session epoch, selected IPv4 address bytes, ENet and discovery ports, 32-byte compatibility digest, occupancy, open/closed state, beacon counter and expiry (1–3 seconds). Each source may query once per second; scheduled beacons are sent once per second, with a global beacon-send ceiling of two per second including query responses. Clients keep at most 64 entries and expire each after three seconds. Manual IPv4/IPv6 address entry remains available when UDP discovery cannot reach the host.

One 128-bit invitation credential is active per host session. It is represented by 26 unambiguous uppercase Base32 characters and stays valid for the lifetime of that room, including after successful joins, leave/rejoin, declined/full requests, and content-manifest changes. QR data includes a `tilaok://join` locator with Lobby ID, host address, ENet port, protocol, manifest digest, access code, and `expires=0`. The same code is shared by every player. A Lobby ID query and manual address only locate the host; the client enters the access code separately. The access token is never included in a join packet or written to disk. The host revokes it when the room stops or is rehosted. Every join still requires a fresh per-connection proof, compatibility validation, host approval, and an available seat.

## Admission, assignment and IPv4 interface behavior

After transport connect, the host creates an untrusted candidate in `COMPATIBILITY`. Compatibility success permits `JOIN_BEGIN`; a 30-second one-use challenge then leads to constant-time HMAC proof verification. A valid candidate enters `PENDING_APPROVAL`; it has no seat, ownership or ready state. At most four candidates await approval. Approval rechecks lobby admission, current manifest revision and total seat capacity in the same main-thread operation that assigns the next empty seat. A closed lobby rejects with `LOBBY_CLOSED`/`WRONG_PHASE`; a full seat registry rejects with `LOBBY_FULL`. The client receives the assignment and must acknowledge the server-selected seat before it can send ready state. Ready requests can affect only the sender's server-owned seat.

`ADMISSION_DECISION` payload is `reason:uint16_le`, optionally followed by `approval_status:uint8` only when `reason=APPROVAL_REQUIRED`: `0=PENDING`, `1=CLOSED`, `2=REJECTED`. The pending response is bounded and contains no client text. A successful decision uses `reason=OK` and is followed by the separate assignment family. A rejection or closure response is followed by transport close.

The P02 assignment carries seat number and visual identifier only. It issues no reclaim token; reclaim and reservations remain P08. Disconnect or voluntary leave clears the remote binding and frees the seat. Local devices continue to use the existing `PlayerSeatRegistry`.

The host selects one currently usable non-loopback IPv4 address for ENet binding and discovery. Other detected interfaces and their eligibility are shown. Only that selected, currently available address may be advertised. Discovery blockage and interface loss are surfaced without disabling manual address entry. Clients may enter an IPv4 or IPv6 address where the selected host binding is reachable; no IPv6 host listener is claimed by P02.

## Engine experiment

On Godot `4.7.2.stable.official.ed1daf0bf`, the production raw ENet host and client exchanged the production compatibility, proof, approval, assignment acknowledgment, ready and leave packets over reliable channel 0. The observed ENet service event supplies the peer object and receive channel; disconnected peers may no longer expose endpoint getters, so transport bookkeeping uses its connection-time peer mapping and application leave is handled by the bounded session-close family. No RPC, object decoding, encryption, internet service or gameplay traffic was enabled. See [P02 verification](../p02/README.md) and the [dated test record](../p02/verification-2026-10-20.txt).
