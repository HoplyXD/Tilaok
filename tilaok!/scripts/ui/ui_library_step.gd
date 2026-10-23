class_name UiLibraryStep
extends Resource

## One step card on a Library page (Figma "Round step"): a short name, a note shown on the right of
## the name, the explanation and the illustration beside them ("pugad", "place" or "play"; see
## UiLibraryStepCard). Text may use the page's {tokens}. PLACEHOLDER copy, like every page.

@export var heading: String = ""
@export var note: String = ""
@export_multiline var body: String = ""
@export var art: String = ""
