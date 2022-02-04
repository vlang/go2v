module transpiler

enum State {
	tree_name
	body_name
	body_value
	string
	ignore
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
	mut first_iter := true
	mut space_count := 0

	for i, ch in input {
		next_ch = input[i + 1] or { ch }
		next_next_ch = input[i + 2] or { ch }
		match state {
			.ignore {
				match next_ch {
					`.` {}
					` ` {
						// Counting spaces is a hack to know if we've passed the line count present at each line
						space_count++
					}
					else {
						if space_count > 5 {
							space_count = 0
							state = .body_name
						}
					}
				}
			}
			.tree_name {
				match ch {
					` ` {}
					`{` {
						state = .body_name
						tokens << temp_token
						temp_token = Token{.body_name, ''}
					}
					else {
						if first_iter {
							first_iter = false
						} else {
							temp_token.data += ch.str()
						}
					}
				}
			}
			.body_name {
				match ch {
					` ` {}
					`\n` {
						state = .ignore
					}
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
					`\n` {
						state = .ignore
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
	tokens << Token{.tree_close, ''}

	return tokens
}
