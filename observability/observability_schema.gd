extends RefCounted

const ALLOWED_SEVERITIES: Array[String] = ["warning", "error", "critical"]
const ALLOWED_CONTEXT_KEYS: Array[String] = [
    "release_version",
    "platform",
    "scene",
    "city_tier",
    "save_schema_version",
    "stage",
]
const BANNED_KEYS: Array[String] = [
    "name",
    "email",
    "address",
    "latitude",
    "longitude",
    "gps",
    "token",
    "secret",
    "password",
    "save_payload",
    "save_file",
    "user_text",
]

static func is_valid_severity(value: String) -> bool:
    return value in ALLOWED_SEVERITIES

static func is_safe_code(value: String) -> bool:
    if value.is_empty() or value.length() > 64:
        return false
    for index: int in range(value.length()):
        var code: int = value.unicode_at(index)
        var is_lower: bool = code >= 97 and code <= 122
        var is_digit: bool = code >= 48 and code <= 57
        if not is_lower and not is_digit and code != 95:
            return false
    return true

static func is_safe_context_string(value: String) -> bool:
    # Context strings are codes/versions, never free-form text. Keep the alphabet
    # deliberately small so emails, file-system paths, stack text, and user-entered
    # prose cannot be forwarded accidentally.
    if value.is_empty() or value.length() > 64:
        return false
    for index: int in range(value.length()):
        var code: int = value.unicode_at(index)
        var is_lower: bool = code >= 97 and code <= 122
        var is_upper: bool = code >= 65 and code <= 90
        var is_digit: bool = code >= 48 and code <= 57
        var allowed_punctuation: bool = code in [45, 46, 95] # - . _
        if not is_lower and not is_upper and not is_digit and not allowed_punctuation:
            return false
    return true

static func sanitize_context(input: Dictionary) -> Dictionary:
    var output: Dictionary = {}
    for key_variant: Variant in input.keys():
        var key: String = str(key_variant)
        if key in BANNED_KEYS:
            continue
        if key not in ALLOWED_CONTEXT_KEYS:
            continue
        var value: Variant = input[key_variant]
        if value is String:
            var text: String = String(value)
            if is_safe_context_string(text):
                output[key] = text
        elif value is int or value is float or value is bool:
            output[key] = value
    return output

static func contains_banned_key(input: Dictionary) -> bool:
    for key_variant: Variant in input.keys():
        if str(key_variant) in BANNED_KEYS:
            return true
    return false
