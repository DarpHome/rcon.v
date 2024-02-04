module rcon

import encoding.binary
import io
import net
import strings

fn recv_text(mut r io.Reader) !TextPacket {
	mut buf := []u8{len: 4}
	mut n := r.read(mut buf)!
	if n != 4 {
		return error('expected 4 bytes as packet begin, got ${n}')
	}
	n = binary.little_endian_u32(buf)
	if n > 4105 {
		return error('too large packet (>4105): ${n}')
	}
	mut payload := []u8{len: n}
	m := r.read(mut payload)!
	if m != n {
		return error('expected to receive ${n} bytes, got ${m}')
	}
	$if trace_rcon ? {
		dump(payload)
	}
	tp := TextPacket.unpack(payload)!
	$if trace_rcon ? {
		dump(tp)
	}
	return tp
}

pub struct TcpClient {
mut:
	conn &net.TcpConn
	i    u32
}

fn (mut c TcpClient) send(packet Packet) ! {
	c.conn.write(packet.pack())!
}

fn (mut c TcpClient) recv_text() !TextPacket {
	return recv_text(mut c.conn)!
}

// close closes server connection
pub fn (mut c TcpClient) close() ! {
	if c.conn == unsafe { nil } {
		return
	}
	c.conn.close()!
}

// login authenticates using password
pub fn (mut c TcpClient) login(password string) !&TcpClient {
	c.send(TextPacket{
		request_id: c.i
		typ: u32(PacketType.login)
		data: password
	})!
	c.i++
	p := c.recv_text()!
	if p.request_id == -1 {
		return error('invalid password')
	}
	// successfully logged in
	return unsafe { c }
}

// execute sends an command and returns result
pub fn (mut c TcpClient) execute(command string) !string {
	c.send(TextPacket{
		request_id: c.i
		typ: u32(PacketType.command)
		data: command
	})!
	mut sb := strings.new_builder(32)
	for {
		p := c.recv_text()!
		sb.write_string(p.data)
		if p.data.len < 4096 {
			break
		}
	}
	return sb.str()
}

// command is like execute but returns current instance and accepts an lambda to allow fluent-style usage
pub fn (mut c TcpClient) command(command string, callback fn (result string) !) !&TcpClient {
	callback(c.execute(command)!)!
	return unsafe { c }
}

// connect_tcp creates TcpClient and connects to server (as TCP connection)
pub fn connect_tcp(address string) !TcpClient {
	return TcpClient{
		conn: net.dial_tcp(address)!
		i: 86
	}
}

// // tcp connects to server using address and call provided lambda with TcpClient
// pub fn tcp(address string, callback fn (mut client TcpClient) !) !TcpClient {
// 	mut client := connect_tcp(address)!
// 	callback(mut client)!
// 	return client
// }

pub struct UdpClient {
mut:
	conn &net.UdpConn
	i    u32
}

fn (mut c UdpClient) send(packet Packet) ! {
	c.conn.write(packet.pack())!
}

fn (mut c UdpClient) recv_text() !TextPacket {
	mut buf := []u8{len: 4}
	mut n, _ := c.conn.read(mut buf)!
	if n != 4 {
		return error('expected 4 bytes as packet begin, got ${n}')
	}
	n = binary.little_endian_u32(buf)
	if n > 4105 {
		return error('too large packet (>4105): ${n}')
	}
	mut payload := []u8{len: n}
	m, _ := c.conn.read(mut payload)!
	if m != n {
		return error('expected to receive ${n} bytes, got ${m}')
	}
	return TextPacket.unpack(payload)!
}

// close closes server connection
pub fn (mut c UdpClient) close() ! {
	if c.conn == unsafe { nil } {
		return
	}
	c.conn.close()!
}

// login authenticates using password
pub fn (mut c UdpClient) login(password string) !&UdpClient {
	c.send(TextPacket{
		request_id: c.i
		typ: u32(PacketType.login)
		data: password
	})!
	c.i++
	p := c.recv_text()!
	if p.request_id == -1 {
		return error('invalid password')
	}
	// successfully logged in
	return unsafe { c }
}

// execute sends an command and returns result
pub fn (mut c UdpClient) execute(command string) !string {
	c.send(TextPacket{
		request_id: c.i
		typ: u32(PacketType.command)
		data: command
	})!
	mut sb := strings.new_builder(32)
	for {
		p := c.recv_text()!
		sb.write_string(p.data)
		if p.data.len < 4096 {
			break
		}
	}
	return sb.str()
}

// command is like execute but returns current instance and accepts an lambda to allow fluent-style usage
pub fn (mut c UdpClient) command(command string, callback fn (result string) !) !UdpClient {
	callback(c.execute(command)!)!
	return c
}

// connect_udp creates UdpClient and connects to server (as UDP connection)
pub fn connect_udp(address string) !UdpClient {
	return UdpClient{
		conn: net.dial_udp(address)!
		i: 118
	}
}
