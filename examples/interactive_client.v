module main

import cli
import os
import regex
import rcon
import term

struct Colorizer {
mut:
	pattern regex.RE
}

fn (mut c Colorizer) colorize(x string) string {
	return c.pattern.replace_by_fn(x, fn (_ regex.RE, s string, start int, end int) string {
		c := s[end - 1]
		f := match c {
			`0` {
				fn () string {
					return term.format_esc('30')
				}
			}
			`1` {
				fn () string {
					return term.format_esc('34')
				}
			}
			`2` {
				fn () string {
					return term.format_esc('32')
				}
			}
			`3` {
				fn () string {
					return term.format_esc('36')
				}
			}
			`4` {
				fn () string {
					return term.format_esc('31')
				}
			}
			`5` {
				fn () string {
					return term.format_esc('35')
				}
			}
			`6` {
				fn () string {
					return term.format_esc('93')
				}
			}
			`7` {
				fn () string {
					return term.format_esc('90')
				}
			}
			`8` {
				fn () string {
					return term.format_esc('90')
				}
			}
			`9` {
				fn () string {
					return term.format_esc('94')
				}
			}
			`a` {
				fn () string {
					return term.format_esc('392')
				}
			}
			`b` {
				fn () string {
					return term.format_esc('96')
				}
			}
			`c` {
				fn () string {
					return term.format_esc('91')
				}
			}
			`d` {
				fn () string {
					return term.format_esc('95')
				}
			}
			`e` {
				fn () string {
					return term.format_esc('33')
				}
			}
			`f` {
				fn () string {
					return term.format_esc('37')
				}
			}
			`r` {
				fn () string {
					return term.format_esc('0')
				}
			}
			`k` {
				fn () string {
					return ''
				}
			}
			`l` {
				fn () string {
					return term.format_esc('1')
				}
			}
			`o` {
				fn () string {
					return term.format_esc('3')
				}
			}
			`n` {
				fn () string {
					return term.format_esc('4')
				}
			}
			`m` {
				fn () string {
					return term.format_esc('9')
				}
			}
			else {
				panic('invalid character (${c})')
			}
		}
		return f()
	})
}

fn new_colorizer() Colorizer {
	mut pattern := regex.new()
	pattern.compile_opt('(§[0-9a-frlonmk])') or { panic(err) }
	return Colorizer{
		pattern: pattern
	}
}

@[params]
struct ApplicationParams {
	address  string
	port     int
	password string
	raw      bool
}

fn run_application(params ApplicationParams) ! {
	mut client := rcon.connect_tcp('${params.address}:${params.port}')!
	defer {
		client.close() or {}
	}
	mut colorizer := new_colorizer()
	client.login(params.password)!
	for {
		print('$ ')
		command := os.input('').trim_space()
		if command in ['Q', 'q'] {
			break
		}
		if command == '' {
			continue
		}
		r := client.execute(command)!
		if params.raw {
			println(r)
		} else {
			println(colorizer.colorize(r))
		}
	}
}

fn main() {
	mut app := cli.Command{
		name: 'rcon-client'
		description: 'interactive RCON client'
		execute: fn (cmd cli.Command) ! {
			address := cmd.flags.filter(|c| c.name == 'address')[0].get_string()!
			port := cmd.flags.filter(|c| c.name == 'port')[0].get_int()!
			password := cmd.flags.filter(|c| c.name == 'password')[0].get_string()!
			raw := cmd.flags.filter(|c| c.name == 'raw')[0].get_bool() or { false }
			run_application(address: address, port: port, password: password, raw: raw)!
		}
		flags: [
			cli.Flag{
				flag: .string
				name: 'address'
				abbrev: 'a'
				description: 'the address to use when connecting'
				required: false
				default_value: ['127.0.0.1']
			},
			cli.Flag{
				flag: .int
				name: 'port'
				abbrev: 'P'
				description: 'the port to use when connecting'
				required: false
				default_value: ['25575']
			},
			cli.Flag{
				flag: .string
				name: 'password'
				abbrev: 'p'
				description: 'the password to use when authenticating'
				required: true
			},
			cli.Flag{
				flag: .bool
				name: 'raw'
				abbrev: 'r'
				description: 'whether to print raw responses, if not present, they will automatically colorized'
				required: false
				default_value: ['false']
			},
		]
	}
	app.setup()
	app.parse(os.args)
}
