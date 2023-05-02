class_name Tokenizer
extends RefCounted

# Instance variables
var cache := {}
var encoder := {}
var decoder := {}
var bpe_ranks := {}
var byte_encoder := {}
var byte_decoder := {}
var pat: RegEx

# Constants for file paths
var ENCODER_FILE = "res://tokenizer/encoder.json"
var BPE_FILE = "res://tokenizer/vocab.bpe"


func _init():
	_load_resources()


func _load_resources() -> void:
	# Load encoder and decoder from JSON file
	var file = FileAccess.open(ENCODER_FILE, FileAccess.READ)
	encoder = JSON.parse_string(file.get_as_text())
	file.close()
	for key in encoder:
		decoder[encoder[key]] = key

	# Load BPE merges from vocab.bpe file
	file = FileAccess.open(BPE_FILE, FileAccess.READ)
	var lines := file.get_as_text().split("\n")
	file.close()

	# Regex patterns for tokenization and BPE merge extraction
	pat = RegEx.new()
	pat.compile(
		"'s|'t|'re|'ve|'m|'ll|'d| ?\\p{L}+| ?\\p{N}+| ?[^\\s\\p{L}\\p{N}]+|\\s+(?!\\S)|\\s+"
	)

	var bpe_merges := []
	var pattern = RegEx.new()
	pattern.compile("(\\S+\\s*)")

	for i in range(1, lines.size() - 1):
		var split_result = []
		var matches = pattern.search_all(lines[i])

		for m in matches:
			var captured_string = m.get_string().strip_edges()
			if captured_string.length() > 0:
				split_result.append(captured_string)

		bpe_merges.append(split_result)

	bpe_ranks = _dict_zip(bpe_merges, range(0, bpe_merges.size()))

	# Byte Encoder
	byte_encoder = _bytes_to_unicode()
	for key in byte_encoder:
		byte_decoder[byte_encoder[key]] = key


func token_count_from_messages(messages: Array) -> int:
	var num_tokens := 0
	for message in messages:
		num_tokens += 4
		for key in message.keys():
			num_tokens += token_count(message[key])
			if key == "name":
				num_tokens -= 1
	num_tokens += 3
	return num_tokens


func token_count(text: String) -> int:
	return encode(text).size()


func encode(text: String) -> Array:
	var bpe_tokens := []
	var matches = pat.search_all(text).map(func(x): return x.get_string())

	for token in matches:
		token = "".join(_encode_str(token).map(func(x): return byte_encoder[int(x)]))
		Array(_bpe(token).split(" ")).map(func(x): bpe_tokens.append(encoder[x]))

	return bpe_tokens


func decode(tokens: Array) -> String:
	var text := "".join(tokens.map(func(x): return decoder.get(x, "")))
	text = _decode_str(Array(text.split("")).map(func(x): return byte_decoder[x]))
	return text


func _bpe(token: String) -> String:
	if cache.has(token):
		return cache[token]

	var word := token.split("")
	var pairs = _get_pairs(word)

	if pairs.size() == 0:
		return token

	while true:
		var min_pairs = {}

		for pair in pairs:
			var rank = bpe_ranks.get(pair, INF)
			min_pairs[rank] = pair

		var bigram = min_pairs[min_pairs.keys().min()]

		if not bigram in bpe_ranks:
			break

		var first = bigram[0]
		var second = bigram[1]
		var new_word = []
		var i = 0
		while i < word.size():
			var j = word.find(first, i)
			if j == -1:
				new_word.append_array(word.slice(i, word.size()))
				break

			new_word.append_array(word.slice(i, j))
			i = j

			if word[i] == first and i < (word.size() - 1) and word[i + 1] == second:
				new_word.append(first + second)
				i += 2
			else:
				new_word.append_array([word[i]])
				i += 1

		word = new_word
		if word.size() == 1:
			break
		else:
			pairs = _get_pairs(word)

	var joined_word := " ".join(word)
	cache[token] = joined_word

	return joined_word


func _dict_zip(x, y):
	var result = {}
	for i in range(0, len(x)):
		result[x[i]] = y[i]
	return result


func _encode_str(text: String) -> Array:
	var utf8 = text.to_utf8_buffer()
	var result = []
	for i in range(utf8.size()):
		result.append(str(utf8[i]))

	return result


func _decode_str(arr) -> String:
	var utf8_data := PackedByteArray()
	for i in arr:
		utf8_data.append(int(i))
	return utf8_data.get_string_from_utf8()


func _get_pairs(word):
	var pairs = []
	for i in range(len(word) - 1):
		pairs.append([word[i], word[i + 1]])
	return pairs


func _bytes_to_unicode():
	var bs = []
	for i in range("!".unicode_at(0), "~".unicode_at(0) + 1):
		bs.append(i)
	for i in range("¡".unicode_at(0), "¬".unicode_at(0) + 1):
		bs.append(i)
	for i in range("®".unicode_at(0), "ÿ".unicode_at(0) + 1):
		bs.append(i)

	var cs = bs.duplicate()
	var n = 0
	for b in range(0, 2 ** 8):
		if not bs.has(b):
			bs.append(b)
			cs.append(2 ** 8 + n)
			n += 1
	cs = cs.map(func(x): return char(x))
	return _dict_zip(bs, cs)
