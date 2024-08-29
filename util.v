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
	// println('ident=${ident} force_upper=${app.force_upper}')
	if app.force_upper {
		app.force_upper = false
		return ident // go2v_ident2(ident)
	}
	return go2v_ident2(ident)
	/*
	return if ident[0].is_capital() {
		// println('is cap')
		ident
	} else {
		go2v_ident2(ident)
	}
	*/
}

fn go2v_ident2(ident string) string {
	return ident.camel_to_snake() // to_lower()) // TODO ?
}
