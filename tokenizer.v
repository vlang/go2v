enum State {
	tree_name
	body_name
	body_value
	string
}

enum TokenType {
	tree_name
	tree_close
	body_name
	body_value
}

struct Token {
mut:
	@type TokenType
	data  string
}

fn tokenizer(input []rune) []Token {
	mut state := State.tree_name
	mut tokens := []Token{}
	mut temp_token := Token{.tree_name, ''}
	mut next_ch := `a`
	mut next_next_ch := `a`

	for i, ch in input {
		next_ch = input[i + 1] or { ch }
		next_next_ch = input[i + 2] or { ch }
		match state {
			.tree_name {
				match ch {
					` ` {}
					`{` {
						state = .body_name
						tokens << temp_token
						temp_token = Token{.body_name, ''}
					}
					else {
						temp_token.data += ch.str()
					}
				}
			}
			.body_name {
				match ch {
					// TODO: check if \r is needed
					` `, `\n`, `\r` {}
					`:` {
						state = .body_value
						tokens << temp_token
						temp_token = Token{.body_value, ''}
					}
					`}` {
						tokens << Token{.tree_close, ''}
					}
					else {
						temp_token.data += ch.str()
					}
				}
			}
			.body_value {
				temp_next := [next_ch, next_next_ch]
				if [[`*`, `a`], [`[`, `]`], [`m`, `a`]].contains(temp_next) {
					state = .tree_name
					temp_token = Token{.tree_name, ''}
				} else {
					state = .string
				}
			}
			.string {
				match ch {
					// TODO: check if \r is needed
					`\n`, `\r` {
						state = .body_name
						tokens << temp_token
						temp_token = Token{.body_name, ''}
					}
					else {
						temp_token.data += ch.str()
					}
				}
			}
		}
	}

	return tokens
}
