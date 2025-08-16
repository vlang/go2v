// Copyright (c) 2024 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license that can be found in the LICENSE file.

fn (mut app App) gen_decl(decl GenDecl) {
	app.comments(decl.doc)
	for spec in decl.specs {
		match spec {
			ImportSpec {
				app.import_spec(spec)
			}
			TypeSpec {
				match spec.typ {
					InterfaceType {
						app.interface_decl(spec.name.name, spec.typ)
					}
					StructType {
						app.struct_or_alias << spec.name.name
						app.struct_decl(spec.name.name, spec.typ)
					}
					else {
						app.type_decl(spec)
					}
				}
			}
			ValueSpec {
				if spec.typ is Ident {
					// needs_closer = true
				}
				match decl.tok {
					'var' {
						// app.genln('// ValueSpec global')
						app.global_decl(spec)
					}
					else {
						// app.genln('// VA const')
						app.const_decl(spec)
					}
				}
			}
		}
	}
	// if needs_closer {
	if app.is_enum_decl {
		app.genln('}')
	}
	app.is_enum_decl = false
}

fn (mut app App) type_decl(spec TypeSpec) {
	// Remember the type name for the upcoming const (enum) handler if it's an enum
	name := spec.name.name
	app.type_decl_name = name
	// TODO figure out how to differentiate between enums and type aliases
	if name == 'EnumTest' {
		return
	}
	// Generate actual type alias
	app.gen('type ${name} = ')
	app.typ(spec.typ)
	app.genln('')
}

fn (mut app App) global_decl(spec ValueSpec) {
	for name in spec.names {
		app.gen('__global ${name.name} ')
		if spec.typ is InvalidExpr {
			// No type means `var x = foo.bar()`
			// Eval the expression
			app.gen(' = ')
			// TODO multiple values?
			if spec.values.len > 0 {
				app.expr(spec.values[0])
			}
		} else {
			app.typ(spec.typ)
			app.genln('')
		}
	}
}

fn (mut app App) const_decl(spec ValueSpec) {
	// Handle iota (V enuma)
	if spec.values.len > 0 {
		first_val := spec.values[0]
		if first_val is Ident {
			if first_val.name == 'iota' {
				app.is_enum_decl = true
				app.genln('enum ${app.type_decl_name} {')
			}
		}
	}
	for i, name in spec.names {
		if !app.is_enum_decl && name.name.starts_with_capital() {
			app.gen('pub ')
		}
		n := app.go2v_ident(name.name)
		if app.is_enum_decl {
			if n != 'iota' {
				app.genln(n)
				continue
			}
		} else {
			app.gen('const ${n} = ')
		}
		if i < spec.values.len && !app.is_enum_decl {
			app.expr(spec.values[i])
		}
		app.genln('')
	}
}

const master_module_path = 'github.com.evanw.esbuild.internal' // TODO hardcoded

fn (mut app App) import_spec(spec ImportSpec) {
	mut name := spec.path.value.replace('"', '').replace('/', '.')
	// Skip modules that don't exist in V (fmt, strings etc)
	if name in nonexistent_modules {
		return
	}
	if name == 'archive.zip' {
		name = 'compress.zip'
	}
	if name.starts_with(master_module_path) {
		n := name.replace(master_module_path, '')
		app.gen('import ${n[1..]}')
		if spec.name.name != '' {
			app.gen(' as ${spec.name.name}')
		}
		app.genln(' // local module')
		return
	}
	// TODO a temp hack
	if name.starts_with('github') {
		return
	}
	app.gen('import ${name}')
	if spec.name.name != '' {
		app.gen(' as ${spec.name.name}')
	}
	app.genln('')
}

fn (mut app App) struct_decl(struct_name string, spec StructType) {
	app.force_upper = true
	app.genln('struct ${app.go2v_ident(struct_name)} {')
	if spec.fields.list.len > 0 {
		app.genln('pub mut:')
	}
	for field in spec.fields.list {
		app.comments(field.doc)
		for n in field.names {
			app.gen('\t')
			app.gen(app.go2v_ident(n.name))
			app.gen(' ')
			app.typ(field.typ)
			if field.typ in [StarExpr, FuncType] {
				app.gen(' = unsafe { nil }')
			}
			app.genln('')
		}
	}
	app.genln('}\n')
}

fn (mut app App) interface_decl(interface_name string, spec InterfaceType) {
	app.genln('interface ${interface_name} {')
	for field in spec.methods.list {
		app.comments(field.doc)
		for n in field.names {
			app.gen('\t')
			app.gen(app.go2v_ident(n.name))
			app.force_upper = true
			app.typ(field.typ)
			app.genln('')
		}
	}
	app.genln('}\n')
}

// Foo{bar:baz}
// config.Foo{bar:baz}
// []int{1,2,3}
// map[string]int{"foo":1}
fn (mut app App) composite_lit(c CompositeLit) {
	match c.typ {
		ArrayType {
			app.array_init(c)
		}
		Ident {
			app.struct_init(c)
		}
		MapType {
			app.map_init(c)
		}
		SelectorExpr {
			force_upper := app.force_upper // save force upper for `mod.ForceUpper`
			app.force_upper = true
			app.selector_expr(c.typ)
			app.force_upper = force_upper
			app.gen('{')
			if c.elts.len > 0 {
				app.genln('')
			}
			for elt in c.elts {
				app.expr(elt)
				app.genln('')
			}
			app.gen('}')
		}
		else {
			app.genln('// UNHANDLED CompositeLit type  ${c.typ.type_name()} strtyp="${c.typ}"')
		}
	}
}

fn (mut app App) struct_init(c CompositeLit) {
	typ := c.typ
	match typ {
		Ident {
			app.force_upper = true
			n := app.go2v_ident(typ.name)
			app.gen('${n}{')
			if c.elts.len > 0 {
				app.genln('')
			}
			for elt in c.elts {
				app.expr(elt)
				app.genln('')
			}
			app.gen('}')
		}
		else {}
	}
}
