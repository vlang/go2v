module transpiler

// these functions are a collection of utility functions than can be inserted into the generated code
const go2v_fns = {
	/*
	fn go2v_fmt_x(str string, upper_case bool, space_separator bool, leading_zero bool) string {
		mut out := ''
		if str.len > 0 {
			mut zerox := if leading_zero {
				'0x'
			} else {
				''
			}
			if space_separator {
				out += str.bytes().map(zerox + it.hex()).join(' ')
			} else {
				out += zerox + str.bytes().map(it.hex()).join('')
			}
			if upper_case {
				out = out.to_upper()
			}
		}
		return out
	}
	*/
	'go2v_fmt_x':            FunctionStmt{
		name: 'go2v_fmt_x'
		args: {
			'str':             'string'
			'upper_case':      'bool'
			'space_separator': 'bool'
			'leading_zero':    'bool'
		}
		ret_vals: ['string']
		body: [
			VariableStmt{
				names: ['out']
				middle: ':='
				values: [ValStmt{"''"}]
			},
			IfStmt{
				branchs: [IfElse{
					condition: ValStmt{'str.len > 0'}
					body: [
						VariableStmt{
							names: [
								'beginning',
							]
							middle: ':='
							values: [
								IfStmt{
									branchs: [
										IfElse{
											condition: ValStmt{'leading_zero'}
											body: [ValStmt{"'0x'"}]
										},
										IfElse{
											body: [ValStmt{"''"}]
										},
									]
								},
							]
						},
						IfStmt{
							branchs: [
								IfElse{
									condition: ValStmt{'space_separator'}
									body: [
										VariableStmt{
											names: ['out']
											middle: '+='
											values: [
												ValStmt{"str.bytes().map(beginning + it.hex()).join(' ')"},
											]
										},
									]
								},
								IfElse{
									body: [
										VariableStmt{
											names: [
												'out',
											]
											middle: '+='
											values: [
												ValStmt{"beginning + str.bytes().map(it.hex()).join('')"},
											]
										},
									]
								},
							]
						},
						IfStmt{
							branchs: [
								IfElse{
									condition: ValStmt{'upper_case'}
									body: [
										VariableStmt{
											names: [
												'out',
											]
											middle: '='
											values: [
												ValStmt{'out.to_upper()'},
											]
										},
									]
								},
							]
						},
					]
				}]
			},
			ReturnStmt{[ValStmt{'out'}]},
		]
	}
	/*
	fn go2v_utf8_encode_rune(mut p []u8, r rune) int {
		mut bytes := r.bytes()
		p << bytes
		return bytes.len
	}
	*/
	'go2v_utf8_encode_rune': FunctionStmt{
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
				values: [ValStmt{'r.bytes()'}]
			},
			PushStmt{ValStmt{'p'}, ValStmt{'bytes'}},
			ReturnStmt{[ValStmt{'bytes.len'}]},
		]
	}
}
