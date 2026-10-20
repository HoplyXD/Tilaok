# assets/ui/title

Drop final art for the title screen here (PNG for raster, SVG for icons).
Name files ui.title.<element>.<ext> and assign them in the Godot inspector to the matching Art_<Element> node.
Register every file in docs/ASSETS.md before it ships.

- ui.title.emblem.svg: the "Postal emblem" envelope from the Figma "Parchment main menu" frame (103:557), above the title (`Card/Art_Emblem`).
- ui.title.ornament.svg: the "Botanical ornament" leaves and diamond from the same frame (103:560), under the subtitle (`Card/Art_Ornament`).

`ui.title.logo` (a picture title in place of the text) and `ui.title.background` are still empty slots. The card itself (paper, backing page, dashed border, grain, shadows) is drawn by Theme StyleBoxes (`TitleCard*`).
