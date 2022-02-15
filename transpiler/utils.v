module transpiler

// get the value of a variable etc. Basically, everything that can be of multiple types
fn (mut v VAST) get_value(tree Tree) string {
	// get the raw value
	raw_val := if 'Value' in tree.child {
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
		v.extract_declaration(tree.child['Obj'].tree, true)
	}

	return val
}

// get the name of a variable/property/function etc.
fn (mut v VAST) get_name(tree Tree, deep bool, snake_case bool) string {
	// `a = ` syntax
	if 'Name' in tree.child {
		raw_name := if deep {
			tree.child['Name'].tree.child['Name'].val#[1..-1]
		} else {
			tree.child['Name'].val#[1..-1]
		}

		if snake_case {
			// convert to snake case
			mut out := []rune{}

			for i, ch in raw_name {
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
		} else {
			// capitalize
			sub := if `A` <= raw_name[0] && raw_name[0] <= `Z` { 0 } else { 32 }

			return (raw_name[0] - byte(sub)).ascii_str() + raw_name[1..]
		}
	} else {
		// `a.b.c = ` syntax
		mut out := ''
		namespaces := v.get_namespaces(tree)

		for i := namespaces.len - 1; i >= 0; i-- {
			out += namespaces[i].name + if i != 0 { '.' } else { '' }
		}

		return out
	}
}

// get the type of property/function arguments etc.
fn (mut v VAST) get_type(tree Tree) string {
	mut @type := ''
	mut temp := tree.child['Type']

	// arrays
	if temp.tree.name == '*ast.ArrayType' {
		@type = '[]'
		temp = temp.tree.child['Elt']
	}

	v.get_embedded(temp.tree)

	return @type + temp.tree.child['Name'].val#[1..-1]
}

// get the namespaces of the left-hand side of an assignment or a function call
// for further help, see Namespace struct
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

// check if the tree contains an embedded declaration, and extract it if so
fn (mut v VAST) get_embedded(tree Tree) {
	if 'Obj' in tree.child {
		v.extract_declaration(tree.child['Obj'].tree, true)
	}
}

// get the condition string from a tree for if/for/match statements
fn (mut v VAST) get_raw_condition(tree Tree) string {
	if 'Name' !in tree.child {
		x := if 'X' in tree.child['X'].tree.child {
			v.get_raw_condition(tree.child['X'].tree)
		} else {
			v.get_value(tree.child['X'].tree)
		}

		cond := tree.child['Op'].val

		y := if 'Y' in tree.child['Y'].tree.child {
			v.get_raw_condition(tree.child['Y'].tree)
		} else {
			v.get_value(tree.child['Y'].tree)
		}

		if cond == '&&' || cond == '||' {
			return '($x $cond $y)'
		} else {
			return '$x $cond $y'
		}
	} else {
		return v.get_value(tree)
	}
}

// format the condition string obtained from get_raw_condition
fn (mut v VAST) get_condition(tree Tree) string {
	mut cond := v.get_raw_condition(tree)

	mut out := []rune{}
	mut space_count := 0

	for i, ch in cond {
		space_count = if ch == ` ` { space_count + 1 } else { 0 }
		// remove useless spaces and parentheses
		if !(space_count > 1 || (i == 0 && ch == `(`) || (i == cond.len - 1 && ch == `)`)) {
			out << ch
		}
	}
	return out.string()
}

// get the variable statement (VariableStmt) from a tree
fn (mut v VAST) get_var(tree Tree) VariableStmt {
	mut names := []string{}
	mut values := []string{}

	for _, var in tree.child['Lhs'].tree.child {
		names << v.get_name(var.tree, false, true)
	}
	for _, var in tree.child['Rhs'].tree.child {
		if 'X' in var.tree.child {
			// negative numbers, maybe other stuff too
			values << var.tree.child['Op'].val + v.get_value(var.tree.child['X'].tree)
		} else if 'Type' in var.tree.child {
			// structs
			values << v.get_value(var.tree.child['Type'].tree)
		} else {
			// everything else
			values << v.get_value(var.tree)
		}
	}

	v.declared_vars << names

	return VariableStmt{
		names: names
		values: values
		declaration: tree.child['Tok'].val == ':='
	}
}

// get the body of a function/if/for/match statement etc. Basically everything that contains a block of code
fn (mut v VAST) get_body(tree Tree) []Statement {
	mut body := []Statement{}

	// go through every statement
	for _, stmt in tree.child['List'].tree.child {
		match stmt.tree.name {
			// `var` syntax
			'*ast.DeclStmt' {
				base := stmt.tree.child['Decl'].tree.child['Specs'].tree.child['0'].tree

				mut names := []string{}
				mut values := []string{}

				for _, var in base.child['Names'].tree.child {
					names << v.get_name(var.tree, false, true)
				}
				for _, var in base.child['Values'].tree.child {
					values << v.get_value(var.tree)
				}

				v.declared_vars << names

				body << VariableStmt{
					names: names
					values: values
					declaration: true
				}
			}
			// `:=` & `=` syntax
			'*ast.AssignStmt' {
				body << v.get_var(stmt.tree)
			}
			// function/method call
			'*ast.ExprStmt' {
				base := stmt.tree.child['X'].tree

				v.get_embedded(base.child['Fun'].tree)

				// namespaces, see struct Namespace struct for explaination
				mut namespaces := v.get_namespaces(base.child['Fun'].tree)

				// function/method arguments
				for _, arg in base.child['Args'].tree.child {
					namespaces[0].args << v.get_value(arg.tree)
				}

				body << CallStmt{
					namespaces: namespaces.reverse()
				}
			}
			// if/else
			'*ast.IfStmt' {
				mut if_stmt := IfStmt{}
				mut temp := stmt.tree
				mut near_end := if 'Else' in temp.child { false } else { true }

				for ('Else' in temp.child || near_end) {
					mut if_else := IfElse{}

					// `if z := 0; z < 10` syntax
					var := v.get_var(temp.child['Init'].tree)
					if var.names.len > 0 {
						v.declared_vars << var.names[0]
						if_else.body << var
					}

					// condition
					if_else.condition = v.get_condition(temp.child['Cond'].tree)
					if var.names.len != 0 {
						if_else.condition = if_else.condition.replace(var.names[0], var.values[0])
					}

					// body
					if_else.body << if 'Body' in temp.child {
						// `if` or `else if` branchs
						v.get_body(temp.child['Body'].tree)
					} else {
						// `else` branchs
						v.get_body(temp)
					}

					if_stmt.branchs << if_else

					if near_end {
						break
					}
					if 'Else' !in temp.child['Else'].tree.child {
						near_end = true
					}
					temp = temp.child['Else'].tree
				}

				body << if_stmt
			}
			else {}
		}
	}

	return body
}
