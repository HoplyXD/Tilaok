shader_type canvas_item;

// Decorative grass bending. The base of the sprite stays planted and the top leans, so a quad
// sheared by `bend` reads as blades pushed aside. Visual only: nothing here affects collision.

// -1..1, how far the blades currently lean. Driven by GrassPatch from chickens passing through.
uniform float bend = 0.0;
// Ambient breeze phase, advanced continuously so idle grass is never completely still.
uniform float sway = 0.0;
// Pixels of lean at full bend.
uniform float lean_pixels : hint_range(0.0, 128.0) = 26.0;
// Pixels of lean from the breeze alone.
uniform float breeze_pixels : hint_range(0.0, 32.0) = 3.0;

void vertex() {
	// 1.0 at the top of the sprite, 0.0 at the base: the roots never move.
	float height = 1.0 - UV.y;
	// Offset the breeze by UV.x so a row of patches does not pulse in unison.
	float breeze = sin(sway + UV.x * 3.0) * breeze_pixels;
	VERTEX.x += (bend * lean_pixels + breeze) * height;
}
