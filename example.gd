extends TextEdit

var tokenizer = Tokenizer.new()


func _ready() -> void:
	text_changed.connect(_on_text_changed)


func _on_text_changed():
	if len(text) == 0:
		return

	var encoded = tokenizer.encode(text)  # encode text
	var token_count = tokenizer.token_count(text)  # calc token size

	var decoded = tokenizer.decode(encoded)  # decode encoded array

	var messages = [{"assist": "Hello World! 1"}, {"user": "Hello World! 2"}]  # calc token counts from mutliple messages
	var messages_token_count = tokenizer.token_count_from_messages(messages)

	print("Encode: " + str(encoded))
	print("Token Count: " + str(token_count))
	print("Decoded: " + decoded)
	print("Token Count from messages: " + str(messages_token_count))
