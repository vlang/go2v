// Copyright (c) 2024 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by a GPL license that can be found in the LICENSE file.

fn (mut app App) switch_stmt(switch_stmt SwitchStmt) {
	if switch_stmt.init.lhs.len > 0 {
		app.assign_stmt(switch_stmt.init, false)
	}
	app.gen('match ')
	app.expr(switch_stmt.tag)
	app.genln('{')
	for stmt in switch_stmt.body.list {
		case_clause := stmt as CaseClause
		for i, x in case_clause.list {
			app.expr(x)
			if i < case_clause.list.len - 1 {
				app.gen(',')
			}
		}
		if case_clause.list.len == 0 {
			app.gen('else ')
		}
		app.genln('{')
		app.stmt_list(case_clause.body)
		app.genln('}')
	}
	app.genln('}')
}
