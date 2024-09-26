// Copyright (c) 2024 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license that can be found in the LICENSE file.
module main

fn (mut app App) gen_zero_value(t Type) {
	if t is MapType {
		app.map_type(t)
		app.gen('{}')
	} else if t is ArrayType {
		app.array_type(t)
		app.gen('{}')
	} else {
		app.gen('0')
	}
}
