# rcon.v

RCON client in V

[Documentation](https://darphome.github.io/rcon.v/rcon.html)

## Example

```v
import rcon

fn main() {
	// `rcon.connect_tcp` parameter is string in address:port format
	mut client := rcon.connect_tcp('127.0.0.1:25575')!
	defer {
		client.close() or {}
	}
	// perform authentication. it may return 'invalid password' error
	client.login('mypassw0rd')!

	// execute command. returns string as result
	client.execute('say Hello world')!

	players := client.execute('list')!
	println('Players on server: ${players}')
}
```