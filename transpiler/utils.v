module transpiler

import v.token

const (
	// types equivalence (left Go & right V)
	get_v_type = {
		'bool':    'bool'
		'string':  'string'
		'byte':    'u8'
		'rune':    'rune'
		'int':     'int'
		'int8':    'i8'
		'int16':   'i16'
		'int32':   'i32'
		'int64':   'i64'
		'uint8':   'u8'
		'uint16':  'u16'
		'uint32':  'u32'
		'uint64':  'u64'
		'float32': 'f32'
		'float64': 'f64'
	}
	v_types  = get_v_type.values()
	// keywords to excape with `@`
	keywords = token.keywords
)

// used by `set_naming_style()`
enum NamingStyle {
	ignore
	snake_case
	camel_case
}

// used by `VAST.get_name()`
enum Origin {
	var_decl
	fn_decl
	global_decl
	field
	other
}

// used by `VAST.find_unused_name()`
enum Domain {
	in_vars_in_scope
	in_vars_history
	in_global_scope
	in_struct_fields
}

// transform to snake_case, camelCase, or do nothing
fn set_naming_style(str string, naming_style NamingStyle) string {
	match naming_style {
		.snake_case {
			mut out := []rune{}
			mut prev_ch := ` `

			for i, ch in str {
				if `A` <= ch && ch <= `Z` && i != 0 && !(`A` <= prev_ch && prev_ch <= `Z`) {
					out << `_`
				}

				if `A` <= ch && ch <= `Z` {
					out << ch + 32
				} else if ch != `_` || !(`A` <= prev_ch && prev_ch <= `Z`) {
					out << ch
				}

				prev_ch = ch
			}

			return out.string()
		}
		.camel_case {
			sub := if `A` <= str[0] && str[0] <= `Z` { 0 } else { 32 }

			return (str[0] - u8(sub)).ascii_str() + str[1..]
		}
		.ignore {
			return str
		}
	}
}

// escape keywords
fn escape(str string) string {
	if str !in ['true', 'false'] && str in transpiler.keywords {
		return '@$str'
	}

	return str
}

// apply basic formatting plus a specific naming style
fn format_and_set_naming_style(str string, naming_style NamingStyle) string {
	mut out := str

	if str.len > 0 {
		out = match str[1] {
			// strings
			`\\` {
				"'" + str#[3..-3].replace("'", "\\'").replace('\\\\', '\\') + "'"
			}
			// runes
			`'` {
				'`${str#[2..-2].replace('\\\\', '\\')}`'
			}
			// everything else
			else {
				str#[1..-1]
			}
		}

		if !(out[0] == `'` || out[0] == `\``) {
			out = set_naming_style(out, naming_style)
		}
	}

	return escape(out)
}

// get the zero value of a given type
fn type_to_default_value(@type string) string {
	return match @type {
		'string' { "''" }
		'bool' { 'false' }
		'rune' { '`\0`' }
		'f32', 'f64' { '0.0' }
		'int', 'i8', 'i16', 'i32', 'i64', 'u8', 'u16', 'u32', 'u64' { '0' }
		else { '${@type}{}' }
	}
}

// get the struct corresponding to a given name
fn (v &VAST) struct_name_to_struct(struct_name string) Struct {
	for @struct in v.structs {
		if @struct.name == struct_name {
			return @struct
		}
	}
	return Struct{}
}

// get a statement as a string
fn (mut v VAST) stmt_to_string(stmt Statement) string {
	v.write_stmt(stmt, true)
	return v.out.cut_last(v.out.len)
}

// make sure the given name is unique in its given field/domain, if not, make it unique
fn (v &VAST) find_unused_name(original_name string, domains ...Domain) string {
	if original_name == '_' {
		return '_'
	}

	// suffix the name with an int and increment it until it's unique
	mut suffix := 0
	mut new_name := original_name
	mut condition := true

	for domain in domains {
		for condition {
			condition = match domain {
				.in_vars_in_scope { new_name in v.declared_vars_new }
				.in_vars_history { new_name in v.all_declared_vars }
				.in_global_scope { new_name in v.declared_global_new }
				.in_struct_fields { new_name in v.struct_fields }
			}
			if condition && suffix > 0 {
				new_name = '${original_name}_$suffix'
			}
			suffix++
		}
		condition = true
	}

	return new_name
}

fn last_index(arr []string, val string) int {
	for i := arr.len - 1; i >= 0; i-- {
		if arr[i] == val {
			return i
		}
	}

	return -1
}

// get the type of a struct field, a function argument... from a `Tree`
fn (mut v VAST) get_type(tree Tree) string {
	mut temp := tree.child['Type'].tree
	mut pre_type := ''
	mut raw_type := []string{}
	mut next_is_end := 'X' !in temp.child && 'Elt' !in temp.child

	for ('X' in temp.child || 'Elt' in temp.child || next_is_end) {
		// arrays
		if temp.name == '*ast.ArrayType' {
			pre_type += '[]'
			temp = temp.child['Elt'].tree
		}

		// ellipsis (`...int`)
		if temp.name == '*ast.Ellipsis' {
			pre_type += '...'
			temp = temp.child['Elt'].tree
		}

		// pointers
		// the second condition exists because you can't have a pointer to an array in V
		if temp.name == '*ast.StarExpr' && 'X' in temp.child
			&& temp.child['X'].tree.name != '*ast.ArrayType' {
			pre_type += '&'
		}

		// maps
		if temp.name == '*ast.MapType' {
			raw_type << 'map[' + v.get_name(temp.child['Key'].tree, .ignore, .other) + ']' +
				v.get_name(temp.child['Value'].tree, .ignore, .other)
		}

		// functions
		if temp.name == '*ast.FuncType' {
			mut fn_stmt := v.extract_function(temp.parent, false)
			fn_stmt.name = ''
			fn_stmt.public = false
			raw_type << v.stmt_to_string(fn_stmt)
		}

		// inline structs
		if temp.name == '*ast.StructType' {
			raw_type << v.extract_struct(temp, true)
		}

		// generics
		if temp.name == '*ast.InterfaceType' {
			raw_type << 'T'
		}

		// name
		if 'Name' in temp.child {
			raw_type << format_and_set_naming_style(temp.child['Name'].val, .ignore)
		}

		// `a.Struct` syntax
		if 'Sel' in temp.child {
			raw_type << '.' +
				format_and_set_naming_style(temp.child['Sel'].tree.child['Name'].val, .ignore)
		}

		v.extract_embedded_declaration(temp)

		temp = temp.child['X'].tree

		if next_is_end {
			break
		}
		if 'X' !in temp.child && 'Elt' !in temp.child {
			next_is_end = true
		}
	}

	mut out := ''
	for i := raw_type.len - 1; i >= 0; i-- {
		out += if raw_type[i] in v.declared_global_old {
			v.declared_global_new[v.declared_global_old.index(raw_type[i])]
		} else if raw_type[i] in transpiler.get_v_type {
			// transform Go types into V ones
			transpiler.get_v_type[raw_type[i]]
		} else {
			raw_type[i]
		}
	}

	return pre_type + out
}

// get the name of a variable, a function, a property... from a `Tree`
fn (mut v VAST) get_name(tree Tree, naming_style NamingStyle, origin Origin) string {
	raw_name := v.get_initial_name(tree, .ignore)
	formatted_name := v.get_initial_name(tree, naming_style)
	mut out := ''
	// embedded struct utils
	mut is_current_struct_defined := false
	mut current_struct := Struct{}

	for i := raw_name.len - 1; i >= 0; i-- {
		match origin {
			.var_decl {
				new_name := v.find_unused_name(formatted_name[i], .in_vars_in_scope, .in_global_scope)

				v.declared_vars_old << raw_name[i]
				v.declared_vars_new << new_name

				out += new_name
			}
			.fn_decl {
				new_name := v.find_unused_name(formatted_name[i], .in_vars_history, .in_global_scope)

				v.declared_global_old << raw_name[i]
				v.declared_global_new << new_name

				// the first character is used to tell if the function is public or private
				out += if `A` <= raw_name[i][0] && raw_name[i][0] <= `Z` { 'v' } else { 'x' } +
					new_name
			}
			.global_decl {
				mut new_name := v.find_unused_name(formatted_name[i], .in_global_scope)
				if new_name.len == 1 {
					new_name = set_naming_style(new_name + new_name[0].ascii_str(), .camel_case)
				}

				v.declared_global_old << raw_name[i]
				v.declared_global_new << new_name
				out += new_name
			}
			.field {
				new_name := v.find_unused_name(formatted_name[i], .in_struct_fields)

				v.struct_fields << new_name
				out += new_name
			}
			.other {
				if raw_name[i] in v.declared_vars_old {
					new_name := v.declared_vars_new[last_index(v.declared_vars_old, raw_name[i])]
					out += new_name

					if raw_name[i] in v.vars_with_struct_value {
						is_current_struct_defined = true
						current_struct = v.struct_name_to_struct(v.vars_with_struct_value[raw_name[i]])
					}
				} else if raw_name[i] in v.declared_global_old {
					out += v.declared_global_new[v.declared_global_old.index(raw_name[i])]
				} else if is_current_struct_defined {
					name_old := raw_name[i][1..]
					name_new := set_naming_style(name_old + name_old[0].ascii_str(), .camel_case)

					// add `field_name StructName` to embedded_structs
					for _, val in current_struct.fields {
						if val is BasicValueStmt {
							if `A` <= val.value[0] && val.value[0] <= `Z` {
								current_struct.embedded_structs << val.value
							}
						}
					}

					if name_old in current_struct.embedded_structs {
						out += '.$name_old'
						current_struct = v.struct_name_to_struct(name_old)
					} else if name_new in current_struct.embedded_structs {
						out += '.$name_new'
						current_struct = v.struct_name_to_struct(name_new)
					} else {
						out += formatted_name[i]
					}
				} else {
					out += formatted_name[i]
				}
			}
		}
	}

	return out
}

// util for `VAST.get_name()`, it gets the original name without any transformation
fn (mut v VAST) get_initial_name(tree Tree, naming_style NamingStyle) []string {
	mut temp := tree
	mut namespaces := []string{}
	mut has_ptr_deref := false
	// All `next_is_end` related code is a trick to repeat one more time the loop
	mut next_is_end := 'X' !in temp.child

	for ('X' in temp.child || 'Fun' in temp.child) || next_is_end {
		// pointer dereferencing
		if 'Star' in temp.child {
			has_ptr_deref = true
		}

		// `a.b.c` syntax
		if 'Sel' in temp.child {
			namespaces << '.' +
				format_and_set_naming_style(temp.child['Sel'].tree.child['Name'].val, naming_style)
		}

		// name
		if 'Name' in temp.child {
			if 'Name' in temp.child['Name'].tree.child {
				temp = temp.child['Name'].tree
			}

			namespaces << format_and_set_naming_style(temp.child['Name'].val, naming_style)
		}

		// value
		if 'Value' in temp.child {
			namespaces << format_and_set_naming_style(temp.child['Value'].val, naming_style)

			v.extract_embedded_declaration(temp)
		}

		// `a[idx]` syntax
		if 'Index' in temp.child {
			namespaces << '[' + v.stmt_to_string(v.extract_stmt(temp.child['Index'].tree)) + ']'
		}

		temp = temp.child[if 'X' in temp.child { 'X' } else { 'Fun' }].tree

		if next_is_end {
			break
		}
		if 'X' !in temp.child && 'Fun' !in temp.child {
			next_is_end = true
		}
	}

	// transform Go types into V ones for type casting
	if namespaces.len == 1 && namespaces[0] in transpiler.get_v_type {
		namespaces[0] = transpiler.get_v_type[namespaces[0]]
	}

	// special case for "method variable"
	if has_ptr_deref && namespaces.last() != v.current_method_var_name {
		namespaces << '*'
	}

	return namespaces
}

fn bv_stmt(str string) Statement {
	return Statement(BasicValueStmt{str})
}

// aims at facilitating reporting errors by printing infos to the user
// thus, it isn't used by the transpiler
fn not_implemented(tree Tree) NotYetImplStmt {
	mut hint := ''

	if 'TokPos' in tree.child {
		hint = 'at character ${tree.child['TokPos'].val}'
	} else if 'NamePos' in tree.child {
		hint = 'at character ${tree.child['NamePos'].val}'
	} else if 'OpPos' in tree.child {
		hint = 'at character ${tree.child['OpPos'].val}'
	} else if 'Lbrace' in tree.child {
		hint = 'from character ${tree.child['Lbrace'].val} to character ${tree.child['Rbrace'].val}'
	} else if 'Lparen' in tree.child {
		hint = 'from character ${tree.child['Lparen'].val} to character ${tree.child['Rparen'].val}'
	} else {
		hint = 'at unknown character'
	}

	if hint == 'at unknown character' && 'Tok' in tree.child {
		return not_implemented(tree.child['X'].tree)
	} else if tree.name.len > 0 {
		eprintln('Go feature `$tree.name` $hint not currently implemented.\nPlease report the missing feature at https://github.com/vlang/go2v/issues/new')
	}

	return NotYetImplStmt{}
}
