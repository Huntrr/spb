class_name Base64Url
extends Reference
# Utils for decoding Base64Url

static func base64url_to_base64(base64url: String) -> String:
	var pad_count: int = (4 - base64url.length() % 4) % 4
	var base64: String = base64url.replace("-", "+").replace("_", "/")
	
	for i in pad_count:
		base64 += "="
	return base64


static func base64url_to_utf8(base64url: String) -> String:
	return Marshalls.base64_to_utf8(base64url_to_base64(base64url))
