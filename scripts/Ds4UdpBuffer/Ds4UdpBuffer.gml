/// @desc Wraps a native GameMaker buffer.
/// @arg {Any} sizeOrBufferId Size of the buffer or it's id
/// @arg {Constant.BufferType} [bufferType] Buffer type constant
/// @arg {Real} [bufferAlignment] Buffer alignment, defaults to 1
function Ds4UdpBuffer(sizeOrBufferId) constructor {
	isBufferManaged = argument_count > 1; // are we responsible for freeing the buffer?
	bufferId = isBufferManaged
		? buffer_create(
				sizeOrBufferId,
				argument[1],
				argument[2]
			)
		: sizeOrBufferId;
	
	/// @ignore
	/// @desc !DO NOT CALL THIS METHOD FROM PUBLIC CODE!
	chkDisposed = function() {
		if (bufferId < 0) {
			throw new Ds4UdpException("Ds4UdpBuffer is disposed");
		}
	};
	
	writeU8 = function(value) {
		chkDisposed();
		buffer_write(bufferId, buffer_u8, value);
	};
	
	writeU16 = function(value) {
		chkDisposed();
		buffer_write(bufferId, buffer_u16, value);
	};
	
	writeU32 = function(value) {
		chkDisposed();
		buffer_write(bufferId, buffer_u32, value);
	};
	
	writeS32 = function(value) {
		chkDisposed();
		buffer_write(bufferId, buffer_s32, value);
	};
	
	readU8 = function() {
		chkDisposed();
		return buffer_read(bufferId, buffer_u8);
	};
	
	readU16 = function() {
		chkDisposed();
		return buffer_read(bufferId, buffer_u16);
	};
	
	readU32 = function() {
		chkDisposed();
		return buffer_read(bufferId, buffer_u32);
	};
	
	readU64 = function() {
		chkDisposed();
		return buffer_read(bufferId, buffer_u64);
	};
	
	readF32 = function() {
		chkDisposed();
		return buffer_read(bufferId, buffer_f32);
	};
	
	tell = function() {
		chkDisposed();
		return buffer_tell(bufferId);
	};
	
	seek = function(toAddress = 0) {
		chkDisposed();
		buffer_seek(bufferId, buffer_seek_start, toAddress);
	};
	
	fillAndReset = function() {
		chkDisposed();
		buffer_fill(bufferId, 0, buffer_u8, 0, buffer_get_size(bufferId));
		seek();
	};
	
	correctCrc32 = function(offsetReal, sizeReal) {
		chkDisposed();
		return (~buffer_crc32(bufferId, offsetReal, sizeReal)) & 0xFFFFFFFF;
	};
	
	pokeU16 = function(at, value) {
		chkDisposed();
		var ppos = tell();
		seek(at);
		writeU16(value);
		seek(ppos);
	};
	
	pokeU32 = function(at, value) {
		chkDisposed();
		var ppos = tell();
		seek(at);
		writeU32(value);
		seek(ppos);
	};
	
	/// @desc NOT NULL TERMINATED! Use when you have to!
	writeString = function(value) {
		chkDisposed();
		buffer_write(bufferId, buffer_text, value);
	};
	
	writeCString = function(value) {
		chkDisposed();
		buffer_write(bufferId, buffer_string, value);
	};
	
	readCString = function() {
		chkDisposed();
		return buffer_read(bufferId, buffer_string);
	};
	
	readS32 = function() {
		chkDisposed();
		return buffer_read(bufferId, buffer_s32);
	};
	
	getSize = function() {
		chkDisposed();
		return buffer_get_size(bufferId);
	};
	
	getId = function() {
		return bufferId;
	};
	
	dispose = function() {
		if (bufferId >= 0) {
			if (isBufferManaged) {
				buffer_delete(bufferId);
			}
			
			bufferId = -1;
		}
		
		return undefined;
	};
}