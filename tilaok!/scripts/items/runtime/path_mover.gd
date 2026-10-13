class_name PathMover
extends RefCounted

## Back-and-forth travel with endpoint pauses as a closed-form function of elapsed time.
## Starts moving at t=0 from the start endpoint; `travel` is the centre-line length.


static func period(travel: float, speed: float, pause: float) -> float:
	return 2.0 * (travel / speed + pause)


## {offset: 0..travel from the start endpoint, paused: bool, forward: bool}.
static func sample(elapsed: float, travel: float, speed: float, pause: float) -> Dictionary:
	var leg := travel / speed
	var cycle := 2.0 * (leg + pause)
	var u := fposmod(elapsed, cycle)
	if u < leg:
		return {"offset": u * speed, "paused": false, "forward": true}
	if u < leg + pause:
		return {"offset": travel, "paused": true, "forward": true}
	if u < 2.0 * leg + pause:
		return {"offset": travel - (u - leg - pause) * speed, "paused": false, "forward": false}
	return {"offset": 0.0, "paused": true, "forward": false}
