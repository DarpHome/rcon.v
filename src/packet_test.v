module rcon

fn test_build_packet() {
	assert pack_packet(u32(PacketType.login), 1234, 'mypassw0rd'.bytes()) == [u8(19), 0, 0, 0,
		210, 4, 0, 0, 3, 0, 0, 0, 109, 121, 112, 97, 115, 115, 119, 48, 114, 100, 0]
	assert pack_packet(u32(PacketType.login), 1234, 'mypassw0rd\0'.bytes()) == [
		u8(20),
		0,
		0,
		0,
		210,
		4,
		0,
		0,
		3,
		0,
		0,
		0,
		109,
		121,
		112,
		97,
		115,
		115,
		119,
		48,
		114,
		100,
		0,
		0,
	]
	assert pack_packet(0, 0, []) == [u8(9), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
}

fn test_binary_packet() {
	assert BinaryPacket{
		typ: u32(PacketType.login)
		request_id: 1234
		data: 'mypassw0rd'.bytes()
	}.pack() == [u8(19), 0, 0, 0, 210, 4, 0, 0, 3, 0, 0, 0, 109, 121, 112, 97, 115, 115, 119, 48,
		114, 100, 0]
	assert BinaryPacket{
		typ: u32(PacketType.login)
		request_id: 1234
		data: 'mypassw0rd\0'.bytes()
	}.pack() == [u8(20), 0, 0, 0, 210, 4, 0, 0, 3, 0, 0, 0, 109, 121, 112, 97, 115, 115, 119, 48,
		114, 100, 0, 0]
	assert BinaryPacket{}.pack() == [u8(9), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
}

fn test_text_packet() {
	assert TextPacket{
		typ: u32(PacketType.login)
		request_id: 1234
		data: 'mypassw0rd'
	}.pack() == [u8(20), 0, 0, 0, 210, 4, 0, 0, 3, 0, 0, 0, 109, 121, 112, 97, 115, 115, 119, 48,
		114, 100, 0, 0]
	assert TextPacket{
		typ: u32(PacketType.login)
		request_id: 1234
		data: 'mypassw0rd\0'
	}.pack() == [u8(20), 0, 0, 0, 210, 4, 0, 0, 3, 0, 0, 0, 109, 121, 112, 97, 115, 115, 119, 48,
		114, 100, 0, 0]
	assert TextPacket{}.pack() == [u8(10), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
}

fn test_unpacking_part1() ! {
	assert BinaryPacket.unpack([u8(1), 0, 0, 0, 0, 0, 0, 0, 0])! == BinaryPacket{
		request_id: 1
		typ: 0
		data: []
	}
	assert BinaryPacket.unpack([u8(2), 0, 0, 0, 0, 0, 0, 0, 0])! == BinaryPacket{
		request_id: 2
		typ: 0
		data: []
	}
	assert BinaryPacket.unpack([u8(255), 255, 255, 255, 0, 0, 0, 0, 0])! == BinaryPacket{
		request_id: 4294967295
		typ: 0
		data: []
	}
	assert BinaryPacket.unpack([u8(0), 0, 0, 0, 0, 0, 0, 0, 0])! == BinaryPacket{
		request_id: 0
		typ: 0
		data: []
	}
}

fn test_unpacking_part2() {
	BinaryPacket.unpack([]) or {
		assert err.msg() == 'too small packet (<9): 0'
		return
	}
	assert false
}

fn test_unpacking_part3() {
	TextPacket.unpack([]) or {
		assert err.msg() == 'too small packet (<10): 0'
		return
	}
	assert false
}
