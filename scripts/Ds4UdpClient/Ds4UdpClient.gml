// Feather disable GM2017
// that thing is so awful at naming suggestions that I gave up
// everything else? Sure, please!

/// @arg {String} [ipString] IP of the server, optional
/// @arg {Real} [portReal] Port of the server, optional
/// @desc This class communicates with the DS4Windows built-in UDP server, it must be enabled.
///       Will use the default address of 127.0.0.1:26760 if none is provided.
function Ds4UdpClient(ipString = undefined, portReal = undefined) constructor {
	/// @ignore
	srvIp = (is_undefined(ipString)) ? "127.0.0.1" : ipString;
	/// @ignore
	srvPort = (is_undefined(portReal) || portReal <= 0) ? 26760 : portReal;
	/// @ignore
	clSck = new Ds4UdpSocket();
	/// @ignore
	handlerFunction = undefined;
	
	// send out buffer area:
	/// @ignore
	scratchDataPos = 0;
	/// @ignore
	scratchPacketSizePos = 0;
	/// @ignore
	scratchBuff = buffer_create(64, buffer_fixed, 1);
	
	// constants:
	/// @desc Supported protocol version
	protocolVersionReal = 1001;
	// the time when we reach this line cannot be predicated normally
	// since we allocate some stuff, set some variables, this takes microseconds.
	// so it's fiiine
	/// @desc Pseudo-random client id, does not use GM's own random.
	clientIdReal = (pi * get_timer()) & 0xFFFFFFFF; // must be random and u32, only if I cared
	
	/// @desc !DO NOT CALL THIS METHOD FROM PUBLIC CODE!
	/// @ignore
	chkDisposed = function() {
		if (is_undefined(clSck) || scratchBuff < 0) {
			throw new Ds4UdpException("Ds4UdpClient is already disposed");
		}
	};
	
	/// @desc !DO NOT CALL THIS METHOD FROM PUBLIC CODE!
	/// @ignore
	beginPacket = function(messageIdReal) {
		chkDisposed();
		var b = scratchBuff;
		// prepare the buffer:
		buffer_fill(b, 0, buffer_u8, 0, buffer_get_size(b));
		buffer_seek(b, buffer_seek_start, 0);
		// -- header:
		//      magic:
		buffer_write(b, buffer_u8, 0x44); // 'D'
		buffer_write(b, buffer_u8, 0x53); // 'S'
		buffer_write(b, buffer_u8, 0x55); // 'U'
		buffer_write(b, buffer_u8, 0x43); // 'C'
		//      protocol version:
		buffer_write(b, buffer_u16, protocolVersionReal);
		//      packet size: (will need this later, stub for now)
		scratchPacketSizePos = buffer_tell(b);
		buffer_write(b, buffer_u16, 0x0000);
		//      packet crc32: (will need this later, stub for now)
		scratchDataPos = buffer_tell(b);
		buffer_write(b, buffer_u32, 0x00000000);
		//      client id:
		buffer_write(b, buffer_u32, clientIdReal);
		//      message id:
		buffer_write(b, buffer_u32, messageIdReal);
		return undefined;
	};
	
	/// @desc !DO NOT CALL THIS METHOD FROM PUBLIC CODE!
	/// @ignore
	endPacket = function() {
		chkDisposed();
		var b = scratchBuff;
		var posEnd = buffer_tell(b);
		// calculate packet size to fill in:
		// i have NO IDEA how is that supposed to work???
		// it always adds 16 to packet size when recieving
		// and it's commented "//packet size"
		// so... I just decrement 16 from final buffer????? wtf????
		buffer_poke(b, scratchPacketSizePos, buffer_u16, posEnd - 16);
		// calculate crc32 of the packet:
		var pktCrc32 = (~buffer_crc32(b, 0, posEnd)) & 0xFFFFFFFF;
		buffer_poke(b, scratchDataPos, buffer_u32, pktCrc32);
		// prepare for network send:
		buffer_seek(b, buffer_seek_start, 0);
		// do it:
		clSck.sendTo(srvIp, srvPort, b, posEnd);
		// await for an async event now:
		return undefined;
	};
	
	/// @desc !DO NOT CALL THIS METHOD FROM PUBLIC CODE!
	/// @ignore
	onSocketData = function(bufferId, inIpString, inPortReal, inDataSize) {
		chkDisposed();
		// -- socket events are handled here -- //
		if (inIpString != srvIp || inPortReal != srvPort) {
			// not our specific server instance, ignore
			return undefined;
		}
		
		if (inDataSize < 16) {
			// too few bytes, must be at least 16 to have anything meaningful
			throw new Ds4UdpException("Too few bytes to parse a packet, got " + string(inDataSize));
		}
		
		var b = bufferId;
		// actually parse the thing:
		var h1 = buffer_read(b, buffer_u8);
		var h2 = buffer_read(b, buffer_u8);
		var h3 = buffer_read(b, buffer_u8);
		var h4 = buffer_read(b, buffer_u8);
		if (h1 != 0x44 || h2 != 0x53 || h3 != 0x55 || h4 != 0x53) {
			throw new Ds4UdpException("Invalid packet header, expected 'DSUS' as raw bytes.");
		}
		
		var srvProtocol = buffer_read(b, buffer_u16);
		if (srvProtocol > protocolVersionReal) {
			throw new Ds4UdpException("Server protocol is higher than us, it is " + string(srvProtocol));
		}
		
		var srvPktLen = buffer_read(b, buffer_u16); // who cares about the length?
		srvPktLen += 16; // I hate this idea, this makes no sense! Just send the size of the entire pkt!
		if (inDataSize < srvPktLen) {
			throw new Ds4UdpException("Got packet but not enough bytes, " + string(srvPktLen));
		}
		
		// le crc stuff
		var srvCrc32Pos = buffer_tell(b); // where it starts
		var srvPktCrc32 = buffer_read(b, buffer_u32); // read it
		buffer_poke(b, srvCrc32Pos, buffer_u32, 0x00000000); // dummy out the crc32 for calculation
		var srvActualCrc32 = (~buffer_crc32(b, 0, srvPktLen)) & 0xFFFFFFFF;
		if (srvActualCrc32 != srvPktCrc32) {
			throw new Ds4UdpException("Invalid CRC32 checksum of the packet."); 
		}
		
		var srvId = buffer_read(b, buffer_u32); // will be pseudo-random, will not match our Client ID
		var msgType = buffer_read(b, buffer_u32); // ideally should be >0
		
		var that = self;
		var eventData = {
			clientSelf: that,
			serverIdReal: srvId,
			messageTypeReal: msgType
		};
		
		if (msgType == 0x100000) {
			// DSUC_VersionReq
			eventData.maxProtocolVersion = buffer_read(b, buffer_u16);
			// and also 2 bytes padding for alignment which we can ignore
			// they should ideally be set to 0
		}
		else if (msgType == 0x100001) {
			// DSUC_ListPorts
			eventData.padId = buffer_read(b, buffer_u8);
			eventData.padState = buffer_read(b, buffer_u8);
			eventData.model = buffer_read(b, buffer_u8);
			eventData.connectionType = buffer_read(b, buffer_u8);
			eventData.address = undefined;
			var m1 = buffer_read(b, buffer_u8);
			var m2 = buffer_read(b, buffer_u8);
			var m3 = buffer_read(b, buffer_u8);
			var m4 = buffer_read(b, buffer_u8);
			var m5 = buffer_read(b, buffer_u8);
			var m6 = buffer_read(b, buffer_u8);
			if (m1 != 0 && m2 != 0 && m3 != 0 && m4 != 0 && m5 != 0 && m6 != 0) {
				// the order of the [] literal is undefined and is different between VM and YYC
				eventData.address = [ m1, m2, m3, m4, m5, m6 ];
			}
			eventData.batteryStatus = buffer_read(b, buffer_u8);
			// and then there's a 1 byte of padding for alignment which we can ignore
			// ideally that byte should always be 0
		}
		else if (msgType == 0x100002) {
			// DSUC_PadDataReq
			eventData.padId = buffer_read(b, buffer_u8);
			eventData.padState = buffer_read(b, buffer_u8);
			eventData.model = buffer_read(b, buffer_u8);
			eventData.connectionType = buffer_read(b, buffer_u8);
			eventData.address = undefined;
			var m1 = buffer_read(b, buffer_u8);
			var m2 = buffer_read(b, buffer_u8);
			var m3 = buffer_read(b, buffer_u8);
			var m4 = buffer_read(b, buffer_u8);
			var m5 = buffer_read(b, buffer_u8);
			var m6 = buffer_read(b, buffer_u8);
			if (m1 != 0 && m2 != 0 && m3 != 0 && m4 != 0 && m5 != 0 && m6 != 0) {
				// the order of the [] literal is undefined and is different between VM and YYC
				eventData.address = [ m1, m2, m3, m4, m5, m6 ];
			}
			eventData.batteryStatus = buffer_read(b, buffer_u8);
			// here instead of the 0 padding byte we have extra fields:
			eventData.isActive = buffer_read(b, buffer_u8);
			eventData.packetCounter = buffer_read(b, buffer_u32);
			eventData.buttons1 = buffer_read(b, buffer_u8);
			eventData.buttons2 = buffer_read(b, buffer_u8);
			eventData.psButton = buffer_read(b, buffer_u8);
			eventData.touchButton = buffer_read(b, buffer_u8);
			eventData.lx = buffer_read(b, buffer_u8);
			eventData.ly = buffer_read(b, buffer_u8);
			eventData.rx = buffer_read(b, buffer_u8);
			eventData.ry = buffer_read(b, buffer_u8);
			eventData.dpadLeft = buffer_read(b, buffer_u8);
			eventData.dpadDown = buffer_read(b, buffer_u8);
			eventData.dpadRight = buffer_read(b, buffer_u8);
			eventData.dpadUp = buffer_read(b, buffer_u8);
			eventData.square = buffer_read(b, buffer_u8);
			eventData.cross = buffer_read(b, buffer_u8);
			eventData.circle = buffer_read(b, buffer_u8);
			eventData.triangle = buffer_read(b, buffer_u8);
			eventData.r1 = buffer_read(b, buffer_u8);
			eventData.l1 = buffer_read(b, buffer_u8);
			eventData.r2 = buffer_read(b, buffer_u8);
			eventData.l2 = buffer_read(b, buffer_u8);
			eventData.touch1Active = buffer_read(b, buffer_u8);
			eventData.touch1PacketId = buffer_read(b, buffer_u8);
			eventData.touch1X = buffer_read(b, buffer_u16);
			eventData.touch1Y = buffer_read(b, buffer_u16);
			eventData.touch2Active = buffer_read(b, buffer_u8);
			eventData.touch2PacketId = buffer_read(b, buffer_u8);
			eventData.touch2X = buffer_read(b, buffer_u16);
			eventData.touch2Y = buffer_read(b, buffer_u16);
			eventData.totalMicroSec = buffer_read(b, buffer_u64);
			eventData.accelXG = buffer_read(b, buffer_f32);
			eventData.accelYG = buffer_read(b, buffer_f32);
			eventData.accelZG = buffer_read(b, buffer_f32);
			eventData.angVelPitch = buffer_read(b, buffer_f32);
			eventData.angVelYaw = buffer_read(b, buffer_f32);
			eventData.angVelRoll = buffer_read(b, buffer_f32);
			// the rest of bytes should be 0 (if any)
		}
		else {
			// ?????? uh oh
			throw new Ds4UdpException("Unknown packet message id " + string(msgType));
		}
		
		if (!is_undefined(handlerFunction)) {
			handlerFunction(eventData);
		}
		
		return undefined;
	};
	
	/// @desc Sends a DSUC_VersionReq message to the server
	getVersionReq = function() {
		chkDisposed();
		beginPacket(0x100000); // DSUC_VersionReq
		// this packet has no data
		endPacket();
		return self;
	}
	
	/// @desc Sends a DSUC_ListPorts probing controller ports
	/// @arg {Array<Real>} [idsToProbe] An array of slots to probe, or undefined for all slots.
	getListPorts = function(idsToProbe = undefined) {
		chkDisposed();
		if (is_undefined(idsToProbe)) {
			// all of them
			idsToProbe = [ 0, 1, 2, 3 ];
		}
		
		var idsLen = array_length(idsToProbe);
		if (idsLen <= 0 || idsLen > 4) {
			throw new Ds4UdpException("Invalid idsToProbe length in getListPorts"); 
		}
		
		beginPacket(0x100001); // DSUC_ListPorts
		buffer_write(scratchBuff, buffer_s32, idsLen);
		var idsInd = 0; repeat (idsLen) {
			var slotId = idsToProbe[@ idsInd];
			buffer_write(scratchBuff, buffer_u8, slotId);
			++idsInd;
		}
		endPacket();
		return self;
	};
	
	/// @arg {Enum.Ds4UdpRegFlags} regFlags bitwise enum
	/// @arg {Real} [idToReg] slot to register, use if flags has IdIsValid
	/// @arg {Array<Real>} [macToReg] must contain 6 bytes, use if flags has MacIsValid
	/// @desc Sends a DSUC_PadDataReq asking for pad data
	getPadDataReq = function(regFlags, idToReg = 0, macToReg = undefined) {
		chkDisposed();
		beginPacket(0x100002);
		buffer_write(scratchBuff, buffer_u8, regFlags);
		buffer_write(scratchBuff, buffer_u8, idToReg);
		// loops in GML suck, so this should be actually faster lolz
		if (is_undefined(macToReg)) {
			// we must write something here no matter what, since it's still read
			buffer_write(scratchBuff, buffer_u8, 0);
			buffer_write(scratchBuff, buffer_u8, 0);
			buffer_write(scratchBuff, buffer_u8, 0);
			buffer_write(scratchBuff, buffer_u8, 0);
			buffer_write(scratchBuff, buffer_u8, 0);
			buffer_write(scratchBuff, buffer_u8, 0);
		}
		else {
			// use [@ for speed, also ensures the length and type
			buffer_write(scratchBuff, buffer_u8, macToReg[@ 0]);
			buffer_write(scratchBuff, buffer_u8, macToReg[@ 1]);
			buffer_write(scratchBuff, buffer_u8, macToReg[@ 2]);
			buffer_write(scratchBuff, buffer_u8, macToReg[@ 3]);
			buffer_write(scratchBuff, buffer_u8, macToReg[@ 4]);
			buffer_write(scratchBuff, buffer_u8, macToReg[@ 5]);
		}
		endPacket();
		return self;
	};
	
	/// @arg {Function} onEventFunction called when there is some reply to some packet
	setOnData = function(onEventFunction) {
		chkDisposed();
		handlerFunction = onEventFunction;
		return self;
	};
	
	/// @arg {Id.DsMap} [asyncLoadId] An id of async_load or nothing
	/// @desc Call in the 'Async - Networking' event like so: cl.performNetworkingEvent();
	performNetworkingEvent = function(asyncLoadId = undefined) {
		chkDisposed();
		clSck.performNetworkingEvent(asyncLoadId);
		return self;
	};
	
	/// @desc Disposes of this client, no methods can be called on an instance of this class after this one.
	dispose = function() {
		if (scratchBuff >= 0) {
			buffer_delete(scratchBuff);
			scratchBuff = -1;
		}
		
		if (!is_undefined(clSck)) {
			clSck = clSck.dispose();
		}
		
		return undefined;
	};
	
	// set the data handler for our socket
	clSck.setOnData(onSocketData);
}

/// @desc the .padState member of the data struct
enum Ds4UdpDsState {
	/// @desc Disconnected
	Disconnected = 0x00,
	/// @desc Reserved
	Reserved = 0x01,
	/// @desc Connected
	Connected = 0x02
};

/// @desc the .connectionType member of the data struct
enum Ds4UdpDsConnection {
	/// @desc None
	None = 0x00,
	/// @desc Usb
	Usb = 0x01,
	/// @desc Bluetooth
	Bluetooth = 0x02
};

/// @desc the .model member of the data struct
enum Ds4UdpDsModel {
	/// @desc None
	None = 0,
	/// @desc DualShock 3
	DS3 = 1,
	/// @desc DualShock 4
	DS4 = 2,
	/// @desc Generic Gamepad
	Generic = 3
};

/// @desc the .batteryStatus member of the data struct
enum Ds4UdpDsBattery {
	None = 0x00,
	Dying = 0x01,
	Low = 0x02,
	Medium = 0x03,
	High = 0x04,
	Full = 0x05,
	Charging = 0xEE,
	Charged = 0xEF
};

/// @desc Use in getPadDataReq only
enum Ds4UdpRegFlags {
	None = 0x0,
	IdIsValid = 0x1,
	MacIsValid = 0x2,
	BothIdAndMacAreValid = 0x1 | 0x2
};

show_debug_message("Do I really have to print my name here? As if... who cares? Okay fine, Ds4Udp by Nikita Krapivin.");

// Feather restore GM2017
