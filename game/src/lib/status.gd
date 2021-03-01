class_name Status
extends Resource

# Same order as the standard gRPC error codes.
# https://github.com/grpc/grpc/blob/master/doc/statuscodes.md
enum {
	OK,
	CANCELED,
	UNKNOWN,
	INVALID_ARGUMENT,
	DEADLINE_EXCEEDED,
	NOT_FOUND,
	ALREADY_EXISTS,
	PERMISSION_DENIED,
	RESOURCE_EXHAUSTED,
	FAILED_PRECONDITION,
	ABORTED,
	OUT_OF_RANGE,
	UNIMPLEMENTED,
	INTERNAL,
	UNAVAILABLE,
	DATA_LOSS,
	UNAUTHENTICATED,
}

var code: int = OK
var message: String = ""

func _init(code_: int = OK, message_: String = "") -> void:
	self.code = code_
	self.message = message_

func ok() -> bool:
	return code == OK

static func from_http_code(http_code: int) -> int:
	match http_code:
		HTTPClient.RESPONSE_OK:
			return OK
		
		HTTPClient.RESPONSE_BAD_REQUEST:
			return INTERNAL
		
		HTTPClient.RESPONSE_UNAUTHORIZED:
			return UNAUTHENTICATED
		
		HTTPClient.RESPONSE_FORBIDDEN:
			return PERMISSION_DENIED
		
		HTTPClient.RESPONSE_NOT_FOUND:
			return UNIMPLEMENTED
		
		HTTPClient.RESPONSE_TOO_MANY_REQUESTS:
			return UNAVAILABLE
		
		HTTPClient.RESPONSE_BAD_GATEWAY:
			return UNAVAILABLE
		
		HTTPClient.RESPONSE_SERVICE_UNAVAILABLE:
			return UNAVAILABLE
		
		HTTPClient.RESPONSE_GATEWAY_TIMEOUT:
			return UNAVAILABLE
		
	return UNKNOWN
