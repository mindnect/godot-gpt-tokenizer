# Godot GPT Tokenizer
Simple Godot Tokenizer for GPT and Codex Models by OpenAI.

It is a simple conversion of the [GPT-3-Encoder](https://github.com/latitudegames/GPT-3-Encoder) to Godot4.


## Example:
```
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
	
	# calc token counts from mutliple messages
	var messages = [{"assist": "Hello World! 1"}, {"user": "Hello World! 2"}]
	var messages_token_count = tokenizer.token_count_from_messages(messages)

	print("Encode: " + str(encoded))
	print("Token Count: " + str(token_count))
	print("Decoded: " + decoded)
	print("Token Count from messages: " + str(messages_token_count))
```
