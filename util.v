module main

fn go2v_type(typ string) string {
	match typ {
		'byte' {
			return 'u8'
		}
		'float64' {
			return 'f64'
		}
		else {}
	}
	return typ
}

fn go2v_ident(ident string) string {
	return ident.camel_to_snake() // to_lower()) // TODO ?
}
