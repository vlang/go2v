module transpiler

enum TokenizerState {
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

// it's best to use a struct instead of a sumtype because for the ast construction stage it make the code extremly complex to write and read
struct Child {
mut:
	// tree & val will never be both set
	tree Tree
	val  string
}

struct Tree {
mut:
	name   string
	child  map[string]Child
	parent &Tree = 0
}

fn tokenizer(input []rune) []Token {
	mut state := TokenizerState.tree_name
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
						// counting spaces is a hack to know if we've passed the line count present at each line
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

fn tree_constructor(tokens []Token) Tree {
	mut tree := Tree{}
	mut current_tree := &tree
	mut temp_child_key := ''
	mut last_was_body_name := false

	for token in tokens {
		match token.@type {
			.tree_name {
				if !last_was_body_name {
					current_tree.name = token.data
				} else {
					last_was_body_name = false
					current_tree.child[temp_child_key].tree = &Tree{
						name: token.data
						parent: current_tree
					}
					current_tree = &current_tree.child[temp_child_key].tree // `or { tree }` here is just a trick to make the compiler happy, it will never be executed
					temp_child_key = ''
				}
			}
			.body_name {
				temp_child_key = token.data
				last_was_body_name = true
			}
			.body_value {
				last_was_body_name = false
				current_tree.child[temp_child_key].val = token.data
				temp_child_key = ''
			}
			.tree_close {
				if current_tree.parent != 0 {
					current_tree = current_tree.parent
				}
			}
		}
	}

	return tree
}
