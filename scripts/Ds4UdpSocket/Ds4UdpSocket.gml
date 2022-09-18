/// @desc A funky UDP client wrapper class that is used by Ds4UdpClient
function Ds4UdpSocket() constructor {
	sockId = network_create_socket(network_socket_udp);
	onDataFunction = undefined;
	
	/// @ignore
	/// @desc !DO NOT CALL THIS METHOD FROM PUBLIC CODE!
	chkDisposed = function() {
		if (sockId < 0) {
			throw new Ds4UdpException("Ds4UdpSocket is disposed");
		}
	};
	
	/// @arg {Function} callbackFunction Function that is called on some data
	/// @desc Sets a function that gets called when some data is received.
	setOnData = function(callbackFunction) {
		chkDisposed();
		onDataFunction = callbackFunction;
		return self;
	};
	
	/// @arg {String} addressString the URL or IP of the target as a string
	/// @arg {Real} portReal port to send data to
	/// @arg {Struct.Ds4UdpBuffer} dataBuffer buffer that contains the data to be sent
	/// @arg {Real} [sizeReal] size in bytes to sent, or nothing for full buffer
	/// @desc Sends data to target via UDP, no guarantees are provided, throws on error.
	sendTo = function(addressString, portReal, dataBuffer, sizeReal = undefined) {
		chkDisposed();
		if (is_undefined(sizeReal) || sizeReal < 0) {
			sizeReal = dataBuffer.getSize();
		}
		
		var sentReal = network_send_udp_raw(
			sockId,
			addressString,
			portReal,
			dataBuffer.getId(),
			sizeReal
		);
		
		// throw if we didn't send enough data
		if (sentReal != sizeReal) {
			throw new Ds4UdpException(
				"Failed to send a UDP packet, expected to send " + string(sizeReal) +
				" but sent only " + string(sentReal)
			);
		}
		
		return self;
	};
	
	/// @arg {Id.DsMap} [asyncLoadId] An id of async_load or nothing
	/// @desc Call in the 'Async - Networking' event like so: sck.performNetworkingEvent();
	performNetworkingEvent = function(asyncLoadId = undefined) {
		chkDisposed();
		if (is_undefined(asyncLoadId) || asyncLoadId < 0) {
			asyncLoadId = async_load;
		}
		
		var e = asyncLoadId;
		// UDP sockets have no conect of connection or disconnection
		// so only the "Data" event really applies to us...
		if (e[? "id"] == sockId
		&&  e[? "type"] == network_type_data
		&&  !is_undefined(onDataFunction)) {
			var inb = new Ds4UdpBuffer(e[? "buffer"]);
			onDataFunction(inb, e[? "ip"], e[? "port"], e[? "size"]);
			inb = inb.dispose();
		}
		return self;
	};
	
	/// @desc Recreates the native socket used by the class, use sparingly.
	reset = function() {
		chkDisposed();
		dispose();
		sockId = network_create_socket(network_socket_udp);
		// actually verify the socket id now
		if (sockId < 0) {
			throw new Ds4UdpException("Unable to reset a UDP socket: " + string(sockId));
		}
		return self;
	};
	
	/// @desc Disposes of this socket, no methods can be called on an instance of this class after this one.
	dispose = function() {
		if (sockId >= 0) {
			network_destroy(sockId);
			sockId = -1;
		}
		
		return undefined;
	};
	
	// actually verify the socket id now
	if (sockId < 0) {
		throw new Ds4UdpException("Unable to create a UDP socket: " + string(sockId));
	}
}
