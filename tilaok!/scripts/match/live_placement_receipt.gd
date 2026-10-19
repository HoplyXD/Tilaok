class_name LivePlacementReceipt
extends RefCounted

## Host-derived receipt metadata. The input payload cannot choose these values.

var request
var seat_index := -1
var receipt_usec := 0
var boundary := 0
var sequence := 0
var occupied_seats: Array[int] = []


func configure(
	source_request,
	registered_seat: int,
	host_receipt_usec: int,
	host_boundary: int,
	host_sequence: int,
	seats: Array[int]
) -> void:
	request = source_request
	seat_index = registered_seat
	receipt_usec = host_receipt_usec
	boundary = host_boundary
	sequence = host_sequence
	occupied_seats = seats.duplicate()
