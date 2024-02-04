module rcon

import arrays
import encoding.binary

pub enum PacketType as u32 {
	login    = 3
	command  = 2
	response = 0
}

pub struct PacketHeader {
pub:
	typ        u32
	request_id u32
}

pub struct BinaryPacket {
	PacketHeader
pub:
	data []u8
}

pub struct TextPacket {
	PacketHeader
pub:
	data string
}

pub type Packet = BinaryPacket | TextPacket

fn pack_packet(typ u32, request_id u32, data []u8) []u8 {
	len := 9 + data.len
	mut r := []u8{len: 4 + len}
	binary.little_endian_put_u32_at(mut r, u32(len), 0)
	binary.little_endian_put_u32_at(mut r, u32(request_id), 4)
	binary.little_endian_put_u32_at(mut r, u32(typ), 8)
	arrays.copy(mut r[12..], data)
	r[len + 3] = 0
	return r
}

// pack returns packed byte array which can be sent to RCON socket
pub fn (bp BinaryPacket) pack() []u8 {
	return pack_packet(bp.typ, bp.request_id, bp.data)
}

// pack returns packed byte array which can be sent to RCON socket
pub fn (tp TextPacket) pack() []u8 {
	data := tp.data.bytes()
	idx := data.index(0)
	mut r := if idx != -1 { data[..idx] } else { data }
	r << 0
	return pack_packet(tp.typ, tp.request_id, r)
}

@[inline]
fn (bp BinaryPacket) to_text() TextPacket {
	return TextPacket{
		typ: bp.typ
		request_id: bp.request_id
		data: bp.data.bytestr()
	}
}

// promote converts [BinaryPacket](#BinaryPacket) to [TextPacket](#TextPacket), strips `data` before zero, and if `data` does not contains zero, then it returns error
pub fn (bp BinaryPacket) promote() !TextPacket {
	i := bp.data.index(0)
	if i == -1 {
		return error('data is not zero-terminated')
	}
	return unsafe {
		BinaryPacket{
			typ: bp.typ
			request_id: bp.request_id
			data: bp.data[..i]
		}.to_text()
	}
}

// BinaryPacket.unpack converts payload to [BinaryPacket](#BinaryPacket)
pub fn BinaryPacket.unpack(payload []u8) !BinaryPacket {
	if payload.len < 9 {
		return error('too small packet (<9): ${payload.len}')
	}
	request_id := binary.little_endian_u32_at(payload, 0)
	typ := binary.little_endian_u32_at(payload, 4)
	data := payload[8..payload.len - 1]
	return BinaryPacket{
		request_id: request_id
		typ: typ
		data: data
	}
}

// TextPacket.unpack converts payload to [TextPacket](#TextPacket)
pub fn TextPacket.unpack(payload []u8) !TextPacket {
	if payload.len < 10 {
		return error('too small packet (<10): ${payload.len}')
	}
	request_id := binary.little_endian_u32_at(payload, 0)
	typ := binary.little_endian_u32_at(payload, 4)
	data := payload[8..payload.len - 1]
	i := data.index(0)
	if i == -1 {
		return error('data is not zero-terminated')
	}
	return TextPacket{
		request_id: request_id
		typ: typ
		data: data[..i].bytestr()
	}
}

fn (p Packet) pack() []u8 {
	return match p {
		BinaryPacket { p.pack() }
		TextPacket { p.pack() }
	}
}
