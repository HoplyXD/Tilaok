# assets/ui/library

Art for the Library screen, from the team Figma frame `133:1205` "Library".
Name files ui.library.<element>.<ext> and assign them in the Godot inspector to the matching Art_<Element> node.
Register every file in docs/ASSETS.md before it ships.

- ui.library.icon_back.svg: chevron on the Back plank (`BackButton` action icon).
- ui.library.leaf_divider.svg: leaf divider under the "Library" title (`Frame/Art_LeafDivider`).
- ui.library.leaf_divider_small.svg: small leaf divider over the field guide motto (`Art_LeafSmall`).
- ui.library.step_pugad.svg, ui.library.step_place.svg: the PUGAD and PLACE step pictures (`library_step_card.tscn` `Art_Pugad` / `Art_Place`).
- ui.library.finish_flag.svg, ui.library.step_play_chick.png: the pennant and chick on the PLAY step picture (`Art_Play/Art_Flag`, `Art_Play/Art_Chick`).

SVGs import at `svg/scale=2.4` with mipmaps (2x the 1080p size). Everything else on the screen (parchment, planks, rivets, page, cards, keycaps, shadows, grain) is drawn by Theme StyleBoxes (`Library*`).
