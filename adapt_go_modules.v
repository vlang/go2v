// Copyright (c) 2024 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license that can be found in the LICENSE file.
//
// This file contains logic for adapting Go standard library modules to V equivalents.
// It handles module imports, function call translations, and type mappings.

module main

// Modules that don't exist in V at all and shouldn't be imported
// Note: 'strings' and 'bytes' have special handling in import_spec
const nonexistent_modules = ['fmt', 'path', 'atomic', 'unsafe']

// Type names that conflict with V's standard library and need renaming
// These types exist in V's stdlib (e.g., log.Log) and cause conflicts
const conflicting_type_names = {
	'Log': 'Logger_' // V's log module has log.Log struct
}

// Modules that need function call translation (includes nonexistent + some that exist but need mapping)
const modules_needing_call_translation = ['fmt', 'path', 'strings', 'atomic', 'unsafe', 'os', 'bytes',
	'user', 'sort', 'utf8', 'bits', 'errors']

// Maps Go strings function names to V string method names
const go_strings_to_v = {
	'has_prefix':      'starts_with'
	'has_suffix':      'ends_with'
	'contains':        'contains'
	'to_lower':        'to_lower'
	'to_upper':        'to_upper'
	'trim_space':      'trim_space'
	'trim':            'trim'
	'trim_left':       'trim_left'
	'trim_right':      'trim_right'
	'trim_prefix':     'trim_left'
	'trim_suffix':     'trim_right'
	'replace':         'replace'
	'replace_all':     'replace'
	'split':           'split'
	'join':            'join'
	'index':           'index'
	'last_index':      'last_index'
	'last_index_any':  'last_index_any' // V doesn't have this - needs manual implementation
	'last_index_byte': 'last_index' // V's last_index works for single chars too
	'index_byte':      'index' // V's index works for single chars too
	'repeat':          'repeat'
	'equal_fold':      'eq_ignore_case'
	'count':           'count'
	'fields':          'fields'
}

// Maps Go os function names to V equivalents
const go_os_to_v = {
	'Exit':      'exit'
	'LookupEnv': 'getenv_opt' // Returns ?string instead of (string, bool)
}

// Maps Go os/user function names to V os equivalents
const go_user_to_v = {
	'Current':       'current_user'
	'Lookup':        'lookup_user'
	'LookupId':      'lookup_user_id'
	'LookupGroup':   'lookup_group'
	'LookupGroupId': 'lookup_group_id'
}

// handle_nonexistent_module_call dispatches to the appropriate handler for Go modules
// that don't exist in V or need special translation
fn (mut app App) handle_nonexistent_module_call(sel SelectorExpr, mod_name string, fn_name string, node CallExpr) {
	match mod_name {
		'strings' {
			app.handle_strings_call(app.go2v_ident(fn_name), node.args)
		}
		'path' {
			app.handle_path_call(sel, app.go2v_ident(fn_name), node.args)
		}
		'fmt' {
			app.handle_fmt_call(app.go2v_ident(fn_name), node.args)
		}
		'atomic' {
			app.handle_atomic_call(fn_name, node.args)
		}
		'unsafe' {
			app.handle_unsafe_call(fn_name, node.args)
		}
		'os' {
			app.handle_os_call(fn_name, node.args)
		}
		'bytes' {
			app.handle_bytes_call(fn_name, node.args)
		}
		'user' {
			app.handle_user_call(fn_name, node.args)
		}
		'sort' {
			app.handle_sort_call(fn_name, node.args)
		}
		'utf8' {
			app.handle_utf8_call(fn_name, node.args)
		}
		'bits' {
			app.handle_bits_call(fn_name, node.args)
		}
		'errors' {
			app.handle_errors_call(fn_name, node.args)
		}
		else {}
	}
}

// handle_strings_call maps Go strings functions to string methods in V
// e.g., strings.HasPrefix(s, prefix) => s.starts_with(prefix)
fn (mut app App) handle_strings_call(fn_name string, args []Expr) {
	// Handle special cases that don't map directly to V methods
	match fn_name {
		'last_index_any' {
			// strings.LastIndexAny(s, chars) - V doesn't have this
			// Generate a helper call from the string_helpers module
			app.require_import('string_helpers')
			app.gen('string_helpers.strings_last_index_any(')
			app.expr(args[0])
			app.gen(', ')
			if args.len > 1 {
				app.expr(args[1])
			}
			app.gen(')')
			app.skip_call_parens = true
			return
		}
		'last_index_byte', 'index_byte' {
			// strings.LastIndexByte(s, c) or strings.IndexByte(s, c)
			// Convert char to string: s.last_index(string([c])) or { -1 }
			// The or { -1 } handles the optional return type in V
			app.expr(args[0])
			v_fn_name := if fn_name == 'last_index_byte' { 'last_index' } else { 'index' }
			app.gen('.${v_fn_name}(string([')
			if args.len > 1 {
				app.expr(args[1])
			}
			app.gen('])) or { -1 }')
			app.skip_call_parens = true
			return
		}
		'index', 'last_index' {
			// strings.Index(s, substr) or strings.LastIndex(s, substr)
			// V's index/last_index return ?int, so add or { -1 }
			app.expr(args[0])
			v_fn_name := go_strings_to_v[fn_name] or { fn_name }
			app.gen('.${v_fn_name}(')
			if args.len > 1 {
				app.expr(args[1])
			}
			app.gen(') or { -1 }')
			app.skip_call_parens = true
			return
		}
		else {}
	}
	// Standard case: convert to method call
	app.expr(args[0])
	app.gen('.')
	v_fn_name := go_strings_to_v[fn_name] or { fn_name }
	app.gen(v_fn_name)
	app.skip_first_arg = true
}

// handle_path_call maps Go path functions to V os equivalents
fn (mut app App) handle_path_call(sel SelectorExpr, fn_name string, x []Expr) {
	if fn_name == 'base' {
		app.gen('os.base')
	}
	// Go allows module name shadowing, so we can have a variable `path`
	else {
		app.selector_xxx(sel)
	}
}

// handle_fmt_call maps Go fmt functions to V equivalents
// V uses string interpolation instead of printf-style formatting
fn (mut app App) handle_fmt_call(fn_name string, args []Expr) {
	match fn_name {
		'sprint' {
			app.gen_fmt_joined_args_string(args, false)
			app.skip_call_parens = true
		}
		'sprintln' {
			app.gen_fmt_joined_args_string(args, true)
			app.skip_call_parens = true
		}
		'sprintf' {
			if args.len == 0 {
				app.gen("''")
			} else if !app.gen_fmt_format_string(args[0], args[1..], false) {
				app.gen_fmt_joined_args_string(args, false)
			}
			app.skip_call_parens = true
		}
		'print' {
			app.gen('print(')
			app.gen_fmt_joined_args_string(args, false)
			app.gen(')')
			app.skip_call_parens = true
		}
		'println' {
			app.gen('println(')
			app.gen_fmt_joined_args_string(args, false)
			app.gen(')')
			app.skip_call_parens = true
		}
		'printf' {
			app.gen('print(')
			if args.len == 0 {
				app.gen("''")
			} else if !app.gen_fmt_format_string(args[0], args[1..], false) {
				app.gen_fmt_joined_args_string(args, false)
			}
			app.gen(')')
			app.skip_call_parens = true
		}
		'errorf' {
			app.gen('error(')
			if args.len == 0 {
				app.gen("''")
			} else if !app.gen_fmt_format_string(args[0], args[1..], false) {
				app.gen_fmt_joined_args_string(args, false)
			}
			app.gen(')')
			app.skip_call_parens = true
		}
		'fprint' {
			if args.len > 0 {
				app.gen_fmt_writer_call(args[0], args[1..], false)
			} else {
				app.gen('0')
			}
			app.skip_call_parens = true
		}
		'fprintln' {
			if args.len > 0 {
				app.gen_fmt_writer_call(args[0], args[1..], true)
			} else {
				app.gen('0')
			}
			app.skip_call_parens = true
		}
		'fprintf' {
			if args.len > 1 {
				app.gen_fmt_writer_printf_call(args[0], args[1], args[2..])
			} else {
				app.gen('0')
			}
			app.skip_call_parens = true
		}
		'sscan', 'sscanf', 'fscan', 'fscanf', 'scan', 'scanf' {
			// TODO: translate fmt scan-family calls to V input parsing helpers
			app.gen('0')
			app.skip_call_parens = true
		}
		else {
			// Fallback: preserve call shape as a joined string where possible
			app.gen_fmt_joined_args_string(args, false)
			app.skip_call_parens = true
		}
	}
}

fn (mut app App) gen_fmt_writer_call(writer Expr, args []Expr, trailing_newline bool) {
	app.gen('(')
	app.expr(writer)
	app.gen(').write_string(')
	app.gen_fmt_joined_args_string(args, trailing_newline)
	app.gen(') or { 0 }')
}

fn (mut app App) gen_fmt_writer_printf_call(writer Expr, format Expr, values []Expr) {
	app.gen('(')
	app.expr(writer)
	app.gen(').write_string(')
	if !app.gen_fmt_format_string(format, values, false) {
		mut fallback_args := []Expr{}
		fallback_args << format
		fallback_args << values
		app.gen_fmt_joined_args_string(fallback_args, false)
	}
	app.gen(') or { 0 }')
}

fn (mut app App) gen_fmt_joined_args_string(args []Expr, trailing_newline bool) {
	app.gen("'")
	for i, arg in args {
		if i > 0 {
			app.gen(' ')
		}
		if arg is BasicLit {
			if arg.kind == 'STRING' {
				app.gen(go_fmt_escape_v_interpolation_text(go_fmt_decode_string_lit(arg.value)))
			} else {
				app.gen(arg.value)
			}
		} else {
			app.gen(r'${')
			app.expr(arg)
			app.gen('}')
		}
	}
	if trailing_newline {
		app.gen(r'\n')
	}
	app.gen("'")
}

fn (mut app App) gen_fmt_format_string(format Expr, args []Expr, trailing_newline bool) bool {
	if format !is BasicLit {
		return false
	}
	format_lit := format as BasicLit
	if format_lit.kind != 'STRING' {
		return false
	}
	app.gen_fmt_from_decoded_text(go_fmt_decode_string_lit(format_lit.value), args, trailing_newline)
	return true
}

fn (mut app App) gen_fmt_from_decoded_text(format_text string, args []Expr, trailing_newline bool) {
	app.gen("'")
	mut arg_idx := 0
	mut i := 0
	for i < format_text.len {
		if format_text[i] != `%` {
			start := i
			for i < format_text.len && format_text[i] != `%` {
				i++
			}
			app.gen(go_fmt_escape_v_interpolation_text(format_text[start..i]))
			continue
		}
		if i + 1 < format_text.len && format_text[i + 1] == `%` {
			app.gen('%')
			i += 2
			continue
		}
		mut directive := '%'
		i++
		flags_start := i
		for i < format_text.len && format_text[i] in [`#`, `0`, `-`, `+`, ` `] {
			i++
		}
		flags := format_text[flags_start..i]
		directive += flags
		width_start := i
		for i < format_text.len && go_fmt_is_digit(format_text[i]) {
			i++
		}
		width := format_text[width_start..i]
		directive += width
		mut precision := ''
		if i < format_text.len && format_text[i] == `.` {
			precision_start := i
			i++
			for i < format_text.len && go_fmt_is_digit(format_text[i]) {
				i++
			}
			precision = format_text[precision_start + 1..i]
			directive += format_text[precision_start..i]
		}
		if i >= format_text.len {
			app.gen(go_fmt_escape_v_interpolation_text(directive))
			break
		}
		verb := format_text[i]
		i++
		directive += verb.ascii_str()
		if arg_idx >= args.len {
			app.gen(go_fmt_escape_v_interpolation_text(directive))
			continue
		}
		app.gen_fmt_placeholder(args[arg_idx], flags, width, precision, verb)
		arg_idx++
	}
	if trailing_newline {
		app.gen(r'\n')
	}
	app.gen("'")
}

fn (mut app App) gen_fmt_placeholder(arg Expr, flags string, width string, precision string, verb u8) {
	match verb {
		`q` {
			app.gen('"')
			app.gen(r'${')
			app.expr(arg)
			spec := go_fmt_to_v_interpolation_spec(flags, width, precision, `s`)
			if spec.len > 0 {
				app.gen(':${spec}')
			}
			app.gen('}')
			app.gen('"')
		}
		`T` {
			app.gen(r'${typeof(')
			app.expr(arg)
			app.gen(').name')
			spec := go_fmt_to_v_interpolation_spec(flags, width, precision, `s`)
			if spec.len > 0 {
				app.gen(':${spec}')
			}
			app.gen('}')
		}
		`p` {
			app.gen('0x')
			app.gen(r'${usize(')
			app.expr(arg)
			app.gen('):x}')
		}
		`x`, `X` {
			if flags.contains('#') {
				app.gen(if verb == `X` { '0X' } else { '0x' })
			}
			app.gen(r'${(')
			app.expr(arg)
			app.gen(').hex()')
			if verb == `X` {
				app.gen('.to_upper()')
			}
			spec := go_fmt_to_v_interpolation_spec(flags, width, '', `s`)
			if spec.len > 0 {
				app.gen(':${spec}')
			}
			app.gen('}')
		}
		`d`, `i`, `u`, `c`, `f`, `F`, `e`, `E`, `g`, `G`, `s` {
			app.gen(r'${')
			app.expr(arg)
			spec := go_fmt_to_v_interpolation_spec(flags, width, precision, verb)
			if spec.len > 0 {
				app.gen(':${spec}')
			}
			app.gen('}')
		}
		`v` {
			app.gen(r'${')
			app.expr(arg)
			app.gen('}')
		}
		else {
			app.gen(r'${')
			app.expr(arg)
			app.gen('}')
		}
	}
}

fn go_fmt_is_digit(c u8) bool {
	return c >= `0` && c <= `9`
}

fn go_fmt_to_v_interpolation_spec(flags string, width string, precision string, verb u8) string {
	mut spec := ''
	if flags.contains('-') {
		spec += '-'
	} else if flags.contains('0') {
		spec += '0'
	}
	spec += width
	if precision.len > 0 {
		spec += '.${precision}'
	}
	match verb {
		`i`, `u` {
			spec += 'd'
		}
		`F` {
			spec += 'f'
		}
		else {
			spec += verb.ascii_str()
		}
	}
	return if spec == 's' { '' } else { spec }
}

fn go_fmt_decode_string_lit(lit string) string {
	if lit.len < 2 {
		return lit
	}
	quote := lit[0]
	body := lit[1..lit.len - 1]
	if quote == `\`` {
		return body
	}
	mut decoded := []u8{}
	mut i := 0
	for i < body.len {
		if body[i] != `\\` || i + 1 >= body.len {
			decoded << body[i]
			i++
			continue
		}
		i++
		match body[i] {
			`n` {
				decoded << `\n`
			}
			`t` {
				decoded << `\t`
			}
			`r` {
				decoded << `\r`
			}
			`\\` {
				decoded << `\\`
			}
			`"` {
				decoded << `"`
			}
			`'` {
				decoded << `'`
			}
			`a` {
				decoded << `\a`
			}
			`b` {
				decoded << `\b`
			}
			`f` {
				decoded << `\f`
			}
			`v` {
				decoded << `\v`
			}
			`0` {
				decoded << `\0`
			}
			else {
				decoded << body[i]
			}
		}
		i++
	}
	return decoded.bytestr()
}

fn go_fmt_escape_v_interpolation_text(text string) string {
	mut escaped := text.replace('\\', '\\\\')
	escaped = escaped.replace("'", "\\'")
	escaped = escaped.replace('\n', r'\n')
	escaped = escaped.replace('\t', r'\t')
	escaped = escaped.replace('\r', r'\r')
	escaped = escaped.replace('\0', r'\0')
	escaped = escaped.replace('$', r'\$')
	escaped = escaped.replace('`', r'\`')
	return escaped
}

// handle_os_call maps Go os functions to V equivalents
fn (mut app App) handle_os_call(fn_name string, args []Expr) {
	// Check if this is a function that needs remapping
	if v_fn := go_os_to_v[fn_name] {
		// Exit becomes a standalone function in V
		app.gen(v_fn)
	} else {
		// Keep as os.function_name
		app.gen('os.')
		app.gen(app.go2v_ident(fn_name))
	}
}

// handle_unsafe_call translates Go unsafe operations to V equivalents
// unsafe.Pointer(&x) => voidptr(&x)
// unsafe.Sizeof(x) => sizeof(x)
fn (mut app App) handle_unsafe_call(fn_name string, args []Expr) {
	app.skip_call_parens = true
	match fn_name {
		'Pointer' {
			app.gen('voidptr(')
			if args.len > 0 {
				app.expr(args[0])
			}
			app.gen(')')
		}
		'Sizeof' {
			app.gen('sizeof(')
			if args.len > 0 {
				app.expr(args[0])
			}
			app.gen(')')
		}
		else {
			// Fallback - output as comment
			app.gen('/* unsafe.${fn_name} */')
		}
	}
}

// handle_atomic_call translates Go atomic operations to simple assignments/reads
// atomic.StoreXxx(ptr, val) => *ptr = val
// atomic.LoadXxx(ptr) => *ptr
// atomic.AddXxx(ptr, delta) => *ptr += delta
fn (mut app App) handle_atomic_call(fn_name string, args []Expr) {
	app.skip_call_parens = true
	if fn_name.starts_with('Store') {
		// atomic.StoreUint32(&x, val) => x = val
		if args.len >= 2 {
			if args[0] is UnaryExpr {
				// Skip the & and just use the target
				app.expr((args[0] as UnaryExpr).x)
			} else {
				app.gen('*')
				app.expr(args[0])
			}
			app.gen(' = ')
			app.expr(args[1])
		}
	} else if fn_name.starts_with('Load') {
		// atomic.LoadUint32(&x) => x
		if args.len >= 1 {
			if args[0] is UnaryExpr {
				app.expr((args[0] as UnaryExpr).x)
			} else {
				app.gen('*')
				app.expr(args[0])
			}
		}
	} else if fn_name.starts_with('Add') {
		// atomic.AddInt64(&x, delta) - this is usually handled specially in if_stmt
		// If we get here, just generate a simple add (losing the return value)
		if args.len >= 2 {
			if args[0] is UnaryExpr {
				ux := args[0] as UnaryExpr
				app.expr(ux.x)
				app.gen(' += ')
				app.expr(args[1])
			} else {
				app.gen('*')
				app.expr(args[0])
				app.gen(' += ')
				app.expr(args[1])
			}
		}
	} else {
		// Fallback: just output the function name and args
		app.gen('/* atomic.${fn_name} */ ')
	}
}

// handle_bytes_call maps Go bytes functions to V equivalents
fn (mut app App) handle_bytes_call(fn_name string, args []Expr) {
	match fn_name {
		'Equal' {
			// bytes.Equal(a, b) => a == b
			app.expr(args[0])
			app.gen(' == ')
			app.expr(args[1])
			app.skip_call_parens = true
		}
		'Contains' {
			// bytes.Contains(b, sub) => b.bytestr().contains(sub.bytestr())
			app.expr(args[0])
			app.gen('.bytestr().contains(')
			app.expr(args[1])
			app.gen('.bytestr())')
			app.skip_call_parens = true
		}
		'Index', 'IndexByte' {
			// bytes.Index(b, sep) - needs manual conversion, return -1 for not found
			app.gen('-1')
			app.skip_call_parens = true
		}
		else {
			// For other bytes functions, generate placeholder
			app.gen('0')
			app.skip_call_parens = true
		}
	}
}

// handle_user_call maps Go os/user functions to V os equivalents
// Go's os/user package maps to V's os module user functions
fn (mut app App) handle_user_call(fn_name string, args []Expr) {
	// Map Go function name to V equivalent
	if v_fn := go_user_to_v[fn_name] {
		app.gen('os.')
		app.gen(v_fn)
	} else {
		// Fallback - output as os.function_name with snake_case
		app.gen('os.')
		app.gen(app.go2v_ident(fn_name))
	}
}

// handle_sort_call maps Go sort functions to V equivalents
// sort.Strings(slice) => slice.sort()
// sort.Sort(data) => data.sort()
// sort.Stable(data) => data.sort()
fn (mut app App) handle_sort_call(fn_name string, args []Expr) {
	app.skip_call_parens = true
	if args.len > 0 {
		// If the argument is a pointer dereference (*foo), wrap in parentheses
		// so we get (*foo).sort() instead of *foo.sort()
		if args[0] is StarExpr {
			app.gen('(')
			app.expr(args[0])
			app.gen(')')
		} else {
			app.expr(args[0])
		}
		app.gen('.sort()')
	}
}

// handle_utf8_call maps Go utf8 functions to V equivalents
// utf8.DecodeRuneInString(s) => string_helpers.decode_rune_in_string(s)
// utf8.DecodeLastRuneInString(s) => string_helpers.decode_last_rune_in_string(s)
fn (mut app App) handle_utf8_call(fn_name string, args []Expr) {
	match fn_name {
		'DecodeRuneInString' {
			app.require_import('string_helpers')
			app.gen('string_helpers.decode_rune_in_string(')
			if args.len > 0 {
				app.expr(args[0])
			}
			app.gen(')')
			app.skip_call_parens = true
		}
		'DecodeLastRuneInString' {
			app.require_import('string_helpers')
			app.gen('string_helpers.decode_last_rune_in_string(')
			if args.len > 0 {
				app.expr(args[0])
			}
			app.gen(')')
			app.skip_call_parens = true
		}
		else {
			// For other utf8 functions, use utf8.xxx (V imports as encoding.utf8 but uses utf8 prefix)
			app.gen('utf8.')
			app.gen(app.go2v_ident(fn_name))
		}
	}
}

// handle_bits_call maps Go math/bits functions to V math.bits equivalents
// Go: bits.RotateLeft64(x, k) => bits.rotate_left_64(x, k)
// Note: In V, `import math.bits` means functions are called as `bits.xxx`
fn (mut app App) handle_bits_call(fn_name string, args []Expr) {
	// V uses snake_case with number separated: RotateLeft64 -> rotate_left_64
	// First convert to snake_case, then add underscore before trailing numbers
	mut v_fn_name := fn_name.camel_to_snake()
	// Add underscore before trailing number (e.g., rotate_left64 -> rotate_left_64)
	mut result := []u8{}
	for i, c in v_fn_name {
		if c.is_digit() && i > 0 && !v_fn_name[i - 1].is_digit() && v_fn_name[i - 1] != `_` {
			result << `_`
		}
		result << c
	}
	app.gen('bits.')
	app.gen(result.bytestr())
}

// handle_errors_call maps Go errors functions to V equivalents
// errors.New(msg) => error(msg)
fn (mut app App) handle_errors_call(fn_name string, args []Expr) {
	app.skip_call_parens = true
	match fn_name {
		'New' {
			app.gen('error(')
			if args.len > 0 {
				app.expr(args[0])
			}
			app.gen(')')
		}
		else {
			// Fallback
			app.gen('/* errors.${fn_name} */ error("")')
		}
	}
}
