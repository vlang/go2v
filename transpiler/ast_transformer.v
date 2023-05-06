module transpiler

const (
	// `name` as a key includes `name`
	// `name.` as a key includes `name`, `name.foo`, `name.foo.bar`...
	// `name` as a value transforms to `name`
	// `name.` as a key transforms to `name`, `name.foo`, `name.foo.bar`...
	// `` as a key removes the import
	// `nameInGo`: `nameInV`
	module_equivalence = {
		'archive.':           'compress.'
		'bufio':              'io'
		'bytes':              ''
		'compress.flate':     'compress.deflate'
		'container.':         'datatypes'
		'database.':          ''
		'debug.':             ''
		'embed':              ''
		'encoding.json':      'json'
		'errors':             ''
		'expvar':             ''
		'fmt':                ''
		'@go.':               'v.'
		'html.':              ''
		'image.':             'gg'
		'index.':             ''
		'io.fs':              'os'
		'io.ioutil':          'io.util'
		'log.syslog':         ''
		'math.cmplx':         'math.complex'
		'math.rand':          'rand'
		'mime.':              'net.http.mime'
		'net.http.cgi':       'net.http'
		'net.http.cookiejar': 'net.http'
		'net.http.fcgi':      'net.http'
		'net.http.httptest':  ''
		'net.http.httptrace': ''
		'net.http.httputil':  'net.http'
		'net.http.pprof':     ''
		'net.mail':           'net.smtp'
		'net.netip':          ''
		'net.rpc.':           ''
		'net.textproto':      ''
		'net.url':            'net.urllib'
		'os.':                'os'
		'path.':              'os'
		'plugin':             ''
		'reflect':            ''
		'regexp.':            'regex'
		'runtime.':           ''
		'sort':               ''
		'sync.atomic':        'sync.stdatomic'
		'syscall.':           ''
		'testing.':           ''
		'text.':              'strings'
		'time.tzdata':        'time'
		'unicode.':           'encoding.'
		'unsafe':             ''
		'internal.':          ''
	}
	// functions that are in the `strings` module in Go and in the `builtin` module in V
	strings_to_builtin = ['compare', 'contains', 'contains_any', 'count', 'fields', 'index',
		'index_any', 'index_byte', 'last_index', 'last_index_byte', 'repeat', 'split', 'title',
		'to_lower', 'to_upper', 'trim', 'trim_left', 'trim_prefix', 'trim_right', 'trim_space',
		'trim_suffix']
	// function name equivalence (left Go & right V)
	name_equivalence   = {
		'string': 'str'
		'rune':   'runes'
	}
	// methods of the string builder that require a special treatment
	string_builder_diffs  = ['cap', 'grow', 'len', 'reset', 'string', 'write']
	// equivalent of Go's `unicode.utf8.EncodeRune()`
	//
	// fn go2v_utf8_encode_rune(mut p []u8, r rune) int {
	// 	mut bytes := r.bytes()
	// 	p << bytes
	// 	return bytes.len
	// }
	go2v_utf8_encode_rune = FunctionStmt{
		name: 'go2v_utf8_encode_rune'
		args: {
			'p': 'mut []u8'
			'r': 'rune'
		}
		ret_vals: ['int']
		body: [
			VariableStmt{
				names: ['bytes']
				middle: ':='
				values: [CallStmt{
					namespaces: 'r.bytes'
				}]
			},
			PushStmt{BasicValueStmt{'p'}, BasicValueStmt{'bytes'}},
			ReturnStmt{
				values: [BasicValueStmt{'bytes.len'}]
			},
		]
	}
)

// initialize struct field that are references to themself
fn (mut v VAST) struct_transformer(mut s Struct) {
	for name, typ in s.fields {
		if typ == bv_stmt('&${s.name}') {
			s.default_vals[name] = bv_stmt('nil')
		}
	}
}

// transform a statement valid in Go into a valid one in V
fn (mut v VAST) stmt_transformer(stmt Statement) Statement {
	mut ret_stmt := stmt

	if stmt is CallStmt {
		ns := stmt.namespaces.split('.')
		first_ns := ns.first()
		last_ns := ns.last()
		all_but_last_ns := stmt.namespaces#[..-last_ns.len - 1]

		// common changes
		ret_stmt = match first_ns {
			'len', 'cap', 'rune' { v.transform_fn_to_decl(stmt, first_ns) }
			'string' { v.transform_string_casting(stmt) }
			'make' { v.transform_make(stmt) }
			'delete' { v.transform_delete(stmt) }
			'strings' { v.transform_strings_module(stmt, last_ns) }
			'fmt' { v.transform_fmt(stmt, last_ns) }
			'os' { v.transform_exit(stmt, last_ns) }
			'utf8' { v.transform_utf8(stmt, last_ns) }
			else { stmt }
		}
		// string builders
		if v.string_builder_vars.contains(all_but_last_ns)
			&& transpiler.string_builder_diffs.contains(last_ns) {
			ret_stmt = v.transform_string_builder(stmt, all_but_last_ns, last_ns)
		}
		// `err.Error()` -> `err`
		if first_ns in v.vars_with_error_value {
			ret_stmt = BasicValueStmt{first_ns}
		}
	} else if stmt is VariableStmt {
		mut temp_stmt := stmt
		mut multiple_stmt := MultipleStmt{}

		for i, mut value in temp_stmt.values {
			v.current_var_name = stmt.names[i]
			value = v.stmt_transformer(value)

			// because `mut _ := value` is not valid in V (the combination of `mut` and `_`)
			if temp_stmt.names[i] == '_' {
				temp_stmt.mutable = false
			}

			// `append(array, value)` -> `array << value`
			// `append(array, value1, value2)` -> `array << [value1, value2]`
			if mut value is CallStmt {
				if value.namespaces == 'append' {
					// single
					if value.args.len < 3 {
						mut value_to_append := value.args[1]

						// `append(array, sec_array...)` -> `array << sec_array`
						if mut value_to_append is MultipleStmt {
							if value_to_append.stmts[0] == bv_stmt('...') {
								value_to_append = value_to_append.stmts[1]
							}
						}

						multiple_stmt.stmts << PushStmt{
							stmt: BasicValueStmt{stmt.names[i]}
							value: value_to_append
						}
						// multiple
					} else {
						mut push_stmt := PushStmt{
							stmt: BasicValueStmt{stmt.names[i]}
						}
						mut array := ArrayStmt{}

						for arg in value.args[1..] {
							array.values << arg
						}
						push_stmt.value = array

						multiple_stmt.stmts << push_stmt
					}

					temp_stmt.names.delete(i)
					temp_stmt.values.delete(i)
				} else if value.namespaces == 'error' {
					v.vars_with_error_value << stmt.names[i]
				}
			} else if mut value is StructStmt {
				v.vars_with_struct_value[v.current_var_name] = value.name
			}
		}

		// clear now empty variable stmts
		if stmt.names.len > 0 {
			multiple_stmt.stmts << temp_stmt
		}

		ret_stmt = multiple_stmt
	} else if stmt is MatchStmt {
		//	switch variable {
		//	case "a", "b", "c", "d":
		//		return true
		//	}
		// ->
		//	if ['a', 'b', 'c', 'd'].includes(variable) {
		//		return true
		//	}
		if stmt.cases.len == 2 && stmt.cases[1].body.len == 0 {
			array := ArrayStmt{
				values: stmt.cases[0].values
			}

			ret_stmt = IfStmt{[], [
				IfElse{
					condition: CallStmt{
						namespaces: '${v.stmt_to_string(array)}.includes'
						args: [stmt.value]
					}
					body: stmt.cases[0].body
				},
			]}
		}
	} else if stmt is MultipleStmt {
		// `bytes.Buffer{}` -> `strings.new_builder()`
		// `strings.Buffer{}` -> `strings.new_builder()`

		if stmt.stmts.len > 1 {
			// TODO: remove once https://github.com/vlang/v/issues/14766 gets fixed
			old_stmt := stmt.stmts[1]
			if old_stmt is StructStmt {
				if old_stmt.name == 'bytes.Buffer' || old_stmt.name == 'strings.Builder' {
					ret_stmt = CallStmt{
						namespaces: 'strings.new_builder'
						args: [bv_stmt('0')]
					}
				}
			}
		}
	} else if stmt is BasicValueStmt {
		ret_stmt = match stmt.value {
			// utf8.RuneError -> `\uFFFD`
			'utf8.rune_error' { BasicValueStmt{'`\uFFFD`'} }
			// utf8.RuneSelf -> 0x80
			'utf8.rune_self' { BasicValueStmt{'0x80'} }
			// utf8.MaxRune -> `\U0010FFFF`
			'utf8.max_rune' { BasicValueStmt{'`􏿿`'} }
			// utf8.UTFMax -> 4
			'utf8.utfmax' { BasicValueStmt{'4'} }
			else { stmt }
		}
	} else if stmt is StructStmt {
		// error{} -> error()
		if stmt.name == 'error' {
			ret_stmt = CallStmt{
				namespaces: 'error'
				args: [BasicValueStmt{"''"}]
			}
		}
	}

	return ret_stmt
}

// `fn_name(arg)` -> `arg.fn_name`
fn (mut v VAST) transform_fn_to_decl(stmt CallStmt, left string) Statement {
	right := if left in transpiler.name_equivalence {
		transpiler.name_equivalence[left]
	} else {
		left
	}
	return bv_stmt('${v.stmt_to_string(stmt.args[0])}.${right}')
}

// `string(arg)` -> `arg.str()`
fn (mut v VAST) transform_string_casting(stmt CallStmt) Statement {
	return CallStmt{
		namespaces: '${v.stmt_to_string(stmt.args[0])}.str'
	}
}

// `make(map[string]int)` -> `map[string]int{}`
fn (mut v VAST) transform_make(stmt CallStmt) Statement {
	raw := v.stmt_to_string(stmt.args[0])
	mut out := if raw[raw.len - 2] == `}` { raw#[..-3] } else { raw }

	if stmt.args.len > 1 {
		out += '{len: ${v.stmt_to_string(stmt.args[1])}}'
	} else {
		out += '{}'
	}

	return BasicValueStmt{out}
}

// `delete(map, key)` -> `map.delete(key)`
fn (mut v VAST) transform_delete(stmt CallStmt) Statement {
	return CallStmt{
		namespaces: '${v.stmt_to_string(stmt.args[0])}.delete'
		args: [stmt.args[1]]
	}
}

// handle *most of* the Go fmt module
fn (mut v VAST) transform_fmt(stmt CallStmt, right string) Statement {
	match right {
		// fmt.Errorf(fmt, a) err -> error(strconv.v_sprintf(fmt, a)) err
		'errorf' {
			v.imports['strconv'] = ''

			return CallStmt{
				namespaces: 'error'
				args: [
					CallStmt{
						namespaces: 'strconv.v_sprintf'
						args: stmt.args
					},
				]
			}
		}
		// fmt.Fprint(os.Stdout, a) int, err -> print(a)
		// fmt.Fprint(os.Stderr, a) int, err -> eprint(a)
		'fprint' {
			fn_name := if stmt.args[0] == bv_stmt('os.Stderr') { 'eprint' } else { 'print' }

			return CallStmt{
				namespaces: fn_name
				args: v.print_args_to_single(stmt.args[1..])
			}
		}
		// fmt.Fprintf(os.Stdout, fmt, a) int, err -> print(strconv.v_sprintf(fmt, a))
		// fmt.Fprintf(os.Stderr, fmt, a) int, err -> eprint(strconv.v_sprintf(fmt, a))
		'fprintf' {
			v.imports['strconv'] = ''
			fn_name := if stmt.args[0] == bv_stmt('os.Stderr') { 'eprint' } else { 'print' }

			return CallStmt{
				namespaces: fn_name
				args: [
					CallStmt{
						namespaces: 'strconv.v_sprintf'
						args: stmt.args[1..]
					},
				]
			}
		}
		// fmt.Fprintln(os.Stdout, a) int, err -> println(a)
		// fmt.Fprintln(os.Stderr, a) int, err -> eprintln(a)
		'fprintln' {
			fn_name := if stmt.args[0] == bv_stmt('os.Stderr') { 'eprintln' } else { 'println' }

			return CallStmt{
				namespaces: fn_name
				args: v.print_args_to_single(stmt.args[1..])
			}
		}
		// fmt.Print(a) int, err -> print(a)
		'print' {
			return CallStmt{
				namespaces: 'print'
				args: v.print_args_to_single(stmt.args)
			}
		}
		// fmt.Printf(fmt, a) int, err -> strconv.v_printf(fmt, a)
		'printf' {
			return CallStmt{
				namespaces: 'strconv.v_printf'
				args: stmt.args
			}
		}
		// fmt.Println(a) int, err -> println(a)
		'println' {
			return CallStmt{
				namespaces: 'println'
				args: v.print_args_to_single(stmt.args)
			}
		}
		// fmt.Sprint(a) string -> go2v_fmt_a(a) string
		'sprint' {
			return NotYetImplStmt{}
		}
		// fmt.Sprintf(fmt, a) string -> strconv.v_sprintf(fmt, a) string
		'sprintf' {
			return CallStmt{
				namespaces: 'strconv.v_sprintf'
				args: stmt.args
			}
		}
		// fmt.Sprintln(a) string -> go2v_fmt_a(a) + '\n' string
		'sprintln' {
			// TODO
			return NotYetImplStmt{}
		}
		else {
			return NotYetImplStmt{}
		}
	}
}

// `os.exit(a)` -> `exit(a)`
fn (mut v VAST) transform_exit(stmt CallStmt, right string) Statement {
	if right == 'exit' {
		return CallStmt{
			namespaces: right
			args: stmt.args
		}
	} else {
		v.imports['os'] = ''
		return stmt
	}
}

// see `tests/string_builder_bytes` & `tests/string_builder_strings`
fn (v VAST) transform_string_builder(stmt CallStmt, left string, right string) Statement {
	match right {
		'grow' {
			return CallStmt{
				namespaces: '${left}.ensure_cap'
				args: stmt.args
			}
		}
		'cap', 'len' {
			return BasicValueStmt{stmt.namespaces}
		}
		'reset' {
			return UnsafeStmt{[
				CallStmt{
					namespaces: '${left}.free'
				},
				VariableStmt{
					names: ['${left}.offset', '${left}.len']
					middle: '='
					values: [bv_stmt('0'), bv_stmt('0')]
				},
			]}
		}
		'string' {
			return CallStmt{
				namespaces: '${left}.str'
			}
		}
		'write' {
			return OptionalStmt{stmt}
		}
		else {}
	}
	return stmt
}

// transform functions from the `strings` module
fn (mut v VAST) transform_strings_module(stmt CallStmt, right string) Statement {
	if transpiler.strings_to_builtin.contains(right) {
		return CallStmt{
			namespaces: '${v.stmt_to_string(stmt.args[0])}.${right}'
			args: if stmt.args.len > 1 { [stmt.args[1]] } else { []Statement{} }
		}
	} else if right == 'new_builder' {
		v.string_builder_vars << v.current_var_name
	} else {
		v.imports['strings'] = ''
	}
	return stmt
}

fn (mut v VAST) transform_utf8(stmt CallStmt, right string) Statement {
	match right {
		'rune_len' {
			return CallStmt{
				namespaces: '${v.stmt_to_string(stmt.args[0])}.length_in_bytes'
			}
		}
		'encode_rune' {
			if transpiler.go2v_utf8_encode_rune !in v.functions {
				v.functions << transpiler.go2v_utf8_encode_rune
			}
			return CallStmt{
				namespaces: 'go2v_utf8_encode_rune'
				args: [BasicValueStmt{'mut ${v.stmt_to_string(stmt.args[0])}'}, stmt.args[1]]
			}
		}
		'rune_start' {
			return CallStmt{
				namespaces: 'utf8.is_letter'
				args: stmt.args
			}
		}
		'valid' {
			return CallStmt{
				namespaces: 'utf8.validate_str'
				args: [
					CallStmt{
						namespaces: '${v.stmt_to_string(stmt.args[0])}.bytestr'
					},
				]
			}
		}
		else {
			return stmt
		}
	}
}
