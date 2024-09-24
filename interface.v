fn (mut app App) interface_type(t InterfaceType) {
	// app.gen('INTERFACE TYPE ${t}')
	// interface{}
	if t.methods.list.len == 0 {
		// app.gen('interface{}')
		app.gen('voidptr')
	}
}
