extends Node
# Holds server address constants for various client requests.

var environment = "PROD"

const dict = {
	"PROD": {
		"auth": "http://0.0.0.0:30202"
	}
}


func addresses() -> Dictionary:
	return dict[environment]
