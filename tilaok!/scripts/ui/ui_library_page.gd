class_name UiLibraryPage
extends Resource

## One readable Library page: a title and a body with {tokens} filled from live tuning at bind
## time (never hard-coded numbers). `requires` hides the page until the content it describes is
## enabled in this build: "" (always), "main:KANGAROO" (a mode is available) or
## "stack:KARERA+LAGSANAY" (that compatibility row is enabled). All copy is PLACEHOLDER English
## pending Filipino / Hiligaynon review.
## A page with `steps` shows `body` as its one-line summary and each step as a card under it
## (Figma "Round step"); a page without steps shows `body` as running text.

@export var category: String = ""
@export var title: String = ""
@export_multiline var body: String = ""
@export var requires: String = ""
@export var steps: Array[UiLibraryStep] = []
