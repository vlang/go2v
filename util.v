// Copyright (c) 2024 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license that can be found in the LICENSE file.

fn go2v_type(typ string) string {
	match typ {
		'byte' {
			return 'u8'
		}
		'char' {
			return 'u8'
		}
		'float32' {
			return 'f32'
		}
		'float64' {
			return 'f64'
		}
		'int' {
			return 'isize'
		}
		'int8' {
			return 'i8'
		}
		'int16' {
			return 'i16'
		}
		'int32' {
			return 'i32'
		}
		'int64' {
			return 'i64'
		}
		'String' {
			return 'string'
		}
		'uint' {
			return 'usize'
		}
		'uint8' {
			return 'u8'
		}
		'uint16' {
			return 'u16'
		}
		'uint32' {
			return 'u32'
		}
		'uint64' {
			return 'u64'
		}
		else {}
	}
	return typ
}

fn (mut app App) go2v_ident(ident string) string {
	if ident == 'nil' {
		return 'unsafe { nil }'
	}
	if app.force_upper || ident in app.struct_or_alias {
		app.force_upper = false
		id_typ := go2v_type(ident)
		if id_typ != ident {
			return id_typ
		}
		return ident.capitalize()
	}
	return ident.camel_to_snake()
}
