module transpiler

fn (mut v VAST) get_value(tree Tree) string {
	raw_val := if tree.child['Value'].val.len != 0 {
		tree.child['Value'].val // almost everything
	} else {
		tree.child['Name'].val // bools, iotas (enums), variables
	}

	// format the value
	mut val := raw_val
	if val.len != 0 {
		val = match raw_val[1] {
			`\\` { "'${raw_val#[3..-3]}'" } // strings
			`'` { '`${raw_val#[2..-2]}`' } // runes
			else { raw_val#[1..-1] } // everything else
		}
	}

	// structs
	if 'Obj' in tree.child {
		if !v.declared_vars.contains(val) {
			val += '{}'
		}
		v.get_all(tree.child['Obj'].tree, true)
	}

	return val
}

fn (mut v VAST) get_embedded(tree Tree) {
	if 'Obj' in tree.child {
		v.get_all(tree.child['Obj'].tree, true)
	}
}

fn (mut v VAST) get_name(tree Tree, deep bool, snake_case bool) string {
	// `a = `
	if 'Name' in tree.child {
		raw_name := if deep {
			tree.child['Name'].tree.child['Name'].val#[1..-1]
		} else {
			tree.child['Name'].val#[1..-1]
		}
		return if snake_case { to_snake_case(raw_name) } else { capitalize(raw_name) }
	} else {
		// `a.b.c = `
		mut out := ''
		namespaces := v.get_namespaces(tree)

		for i := namespaces.len - 1; i >= 0; i-- {
			out += namespaces[i].name + if i != 0 { '.' } else { '' }
		}

		return out
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

fn (mut v VAST) get_namespaces(tree Tree) []Namespace {
	mut temp := tree
	mut namespaces := []Namespace{}

	for ('X' in temp.child) {
		namespaces << Namespace{
			name: v.get_name(temp.child['Sel'].tree, false, true)
		}
		temp = temp.child['X'].tree
	}
	namespaces << Namespace{
		name: v.get_name(temp, false, true)
	}

	return namespaces
}

fn to_snake_case(str string) string {
	mut out := []rune{}

	for i, ch in str {
		if `A` <= ch && ch <= `Z` {
			if i != 0 {
				out << `_`
			}
			out << ch + 32
		} else {
			out << ch
		}
	}

	return out.string()
}

fn capitalize(str string) string {
	sub := if `A` <= str[0] && str[0] <= `Z` { 0 } else { 32 }

	return (str[0] - byte(sub)).ascii_str() + str[1..]
}
