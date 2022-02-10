module transpiler

fn get_value(tree Tree) string {
	raw_val := if tree.child['Value'].val.len != 0 {
		tree.child['Value'].val // almost everything
	} else {
		tree.child['Name'].val // bools, iotas (enums), variables
	}
	// Format the value
	mut val := raw_val
	if val.len != 0 {
		val = match raw_val[1] {
			`\\` { "'${raw_val#[3..-3]}'" } // strings
			`'` { '`${raw_val#[2..-2]}`' } // runes
			else { raw_val#[1..-1] } // everything else
		}
	}

	return val
}

fn (mut v VAST) get_embedded(tree Tree) {
	if 'Obj' in tree.child {
		v.get_decl(tree.child['Obj'].tree, true)
	}
}

fn get_name(tree Tree, deep bool) string {
	return if deep {
		tree.child['Name'].tree.child['Name'].val#[1..-1]
	} else {
		tree.child['Name'].val#[1..-1]
	}
}

fn (mut v VAST) get_type(tree Tree) string {
	mut @type := ''
	mut temp := tree.child['Type']
	if temp.tree.name == '*ast.ArrayType' {
		@type = '[]'
		temp = temp.tree.child['Elt']
	}

	v.get_embedded(temp.tree)

	return @type + temp.tree.child['Name'].val#[1..-1]
}
