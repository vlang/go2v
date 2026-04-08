// Copyright (c) 2024 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license that can be found in the LICENSE file.

// go2v_type converts Go types to V types
// Returns (converted_type, is_basic_type)
fn go2v_type(typ string) string {
	return go2v_type_checked(typ).v_type
}

struct TypeConversion {
	v_type   string
	is_basic bool
}

fn go2v_type_checked(typ string) TypeConversion {
	match typ {
		// Basic types that need conversion
		'byte' {
			return TypeConversion{'u8', true}
		}
		'char' {
			return TypeConversion{'u8', true}
		}
		'float32' {
			return TypeConversion{'f32', true}
		}
		'float64' {
			return TypeConversion{'f64', true}
		}
		'int' {
			return TypeConversion{'isize', true}
		}
		'int8' {
			return TypeConversion{'i8', true}
		}
		'int16' {
			return TypeConversion{'i16', true}
		}
		'int32' {
			return TypeConversion{'i32', true}
		}
		'int64' {
			return TypeConversion{'i64', true}
		}
		'String' {
			return TypeConversion{'string', true}
		}
		'uint' {
			return TypeConversion{'usize', true}
		}
		'uint8' {
			return TypeConversion{'u8', true}
		}
		'uint16' {
			return TypeConversion{'u16', true}
		}
		'uint32' {
			return TypeConversion{'u32', true}
		}
		'uint64' {
			return TypeConversion{'u64', true}
		}
		// Go's error interface - translate to IError in V
		'error' {
			return TypeConversion{'IError', true}
		}
		// Basic types that stay the same
		'string', 'bool', 'voidptr', 'rune' {
			return TypeConversion{typ, true}
		}
		else {}
	}
	return TypeConversion{typ, false}
}

// V keywords that need escaping - split into regular keywords and literals
// V keywords that need escaping in identifiers
// Only include keywords that cause issues when used as variable/function names
const v_keywords = ['match', 'in', 'fn', 'as', 'enum', 'typeof', 'or', 'and', 'is', 'not', 'error',
	'lock']!
const v_literals = ['true', 'false', 'none']! // These are only escaped when converted from different case
// V type names that conflict with field/method names (e.g., name.string would be interpreted as module access)
const v_type_names = ['string', 'int', 'bool', 'f32', 'f64', 'i8', 'i16', 'i32', 'i64', 'u8', 'u16',
	'u32', 'u64', 'isize', 'usize', 'rune', 'voidptr']!

// Greek letters to ASCII equivalents for V compatibility
const greek_to_ascii = {
	'α': 'alpha'
	'β': 'beta'
	'γ': 'gamma'
	'δ': 'delta'
	'ε': 'epsilon'
	'ζ': 'zeta'
	'η': 'eta'
	'θ': 'theta'
	'ι': 'iota_'
	'κ': 'kappa'
	'λ': 'lambda_'
	'μ': 'mu'
	'ν': 'nu'
	'ξ': 'xi'
	'π': 'pi'
	'ρ': 'rho'
	'σ': 'sigma'
	'τ': 'tau'
	'υ': 'upsilon'
	'φ': 'phi'
	'χ': 'chi'
	'ψ': 'psi'
	'ω': 'omega'
	// Uppercase Greek
	'Α': 'Alpha'
	'Β': 'Beta'
	'Γ': 'Gamma'
	'Δ': 'Delta'
	'Ε': 'Epsilon'
	'Ζ': 'Zeta'
	'Η': 'Eta'
	'Θ': 'Theta'
	'Ι': 'Iota'
	'Κ': 'Kappa'
	'Λ': 'Lambda'
	'Μ': 'Mu'
	'Ν': 'Nu'
	'Ξ': 'Xi'
	'Π': 'Pi'
	'Ρ': 'Rho'
	'Σ': 'Sigma'
	'Τ': 'Tau'
	'Υ': 'Upsilon'
	'Φ': 'Phi'
	'Χ': 'Chi'
	'Ψ': 'Psi'
	'Ω': 'Omega'
}

fn (mut app App) go2v_ident(ident string) string {
	mut id := ident

	// Convert Greek letters to ASCII
	for greek, ascii in greek_to_ascii {
		if id.contains(greek) {
			id = id.replace(greek, ascii)
		}
	}

	if id == 'nil' {
		if app.in_unsafe_block {
			return 'nil'
		}
		return 'unsafe { nil }'
	}

	// Check for type name conflicts with V's standard library (when used as types)
	if app.force_upper {
		if renamed := conflicting_type_names[id.capitalize()] {
			app.force_upper = false
			return renamed
		}
	}

	// Preserve original casing for struct/type aliases ONLY when in a type context
	// (i.e., when force_upper is true). Otherwise, field accesses like r.Loc should
	// be converted to r.loc even if Loc is also a struct name.
	if app.force_upper && ident in app.struct_or_alias {
		app.force_upper = false // Reset force_upper even for early return
		// Single letter names need to be doubled (reserved for generics in V)
		if id.len == 1 {
			return id.capitalize() + id.capitalize()
		}
		// Type aliases in V must start with capital letter
		if !id[0].is_capital() {
			return id.capitalize()
		}
		return id
	}

	if app.force_upper {
		app.force_upper = false
		id_typ := go2v_type(id)
		if id_typ != id {
			return id_typ
		}
		id = id.capitalize()
	} else {
		id = id.camel_to_snake()
	}

	// Always escape V keywords (match, in, fn, as, etc.)
	if id in v_keywords {
		id = id + '_'
	}

	// Only escape V literals (true, false, none) if they came from a different case
	// This allows Go boolean literals to pass through unchanged
	if id in v_literals && id != ident {
		id = id + '_'
	}

	// Escape V type names when used as field/method names (e.g., .string becomes .string_)
	// This prevents V from interpreting x.string as module access
	if id in v_type_names {
		id = id + '_'
	}

	return id
}
