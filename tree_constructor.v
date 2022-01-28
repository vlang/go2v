type Child = Tree | string

struct Tree {
mut:
	name   string
	child  map[string]Child
	parent &Tree = 0
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
					current_tree.child[temp_child_key] = &Tree{
						name: token.data
						parent: current_tree
					}
					current_tree = &(current_tree.child[temp_child_key] or { tree } as Tree) // `or { tree }` here is just a trick to make the compiler happy, it will never be executed
					temp_child_key = ''
				}
			}
			.body_name {
				temp_child_key = token.data
				last_was_body_name = true
			}
			.body_value {
				last_was_body_name = false
				current_tree.child[temp_child_key] = token.data
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
