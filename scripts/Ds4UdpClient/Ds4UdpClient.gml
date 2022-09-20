// Feather disable GM2017
// that thing is so awful at naming suggestions that I gave up
// everything else? Sure, please!

/// @desc VersionRsp event
function Ds4UdpEventVersionRsp() constructor {
	maxProtocolVersion = 0;
}

/// @desc PortInfo event
function Ds4UdpEventPortInfo() constructor {
	padId = 0;
	padState = Ds4UdpDsState.Disconnected;
	model = Ds4UdpDsModel.None;
	connectionType = Ds4UdpDsConnection.None;
	address = undefined; // {Array<Real>}
	batteryStatus = Ds4UdpDsBattery.None;
}

/// @desc PadData event, contains fields from Ds4UdpEventPortInfo plus the data
function Ds4UdpEventPadDataRsp() : Ds4UdpEventPortInfo() constructor {
	isActive = false;
	packetCounter = 0;
	buttons1 = 0;
	buttons2 = 0;
	psButton = false;
	touchButton = false;
	lx = 0;
	ly = 0;
	rx = 0;
	ry = 0;
	dpadLeft = 0;
	dpadDown = 0;
	dpadRight = 0;
	dpadUp = 0;
	square = 0;
	cross = 0;
	circle = 0;
	triangle = 0;
	r1 = 0;
	l1 = 0;
	r2 = 0;
	l2 = 0;
	touch1Active = false;
	touch1PacketId = 0;
	touch1X = 0;
	touch1Y = 0;
	touch2Active = false;
	touch2PacketId = 0;
	touch2X = 0;
	touch2Y = 0;
	totalMicroSec = int64(0);
	// specifically floats:
	accelXG = 0.0;
	accelYG = 0.0;
	accelZG = 0.0;
	angVelPitch = 0.0;
	angVelYaw = 0.0;
	angVelRoll = 0.0;
}

/// @arg {Enum.Ds4UdpMessageType} msgTypeIn type of this message
/// @arg {Real} serverIdIn id of the server that sent the packet
/// @arg {Struct.Ds4UdpClient} senderIn client struct
/// @arg {Struct.Ds4UdpEventVersionRsp} versionRspIn server max protocol version info
/// @arg {Struct.Ds4UdpEventPortInfo} portInfoIn pad slots port info
/// @arg {Struct.Ds4UdpEventPadDataRsp} padDataRspIn pad slots data info
/// @desc A Ds4Udp event class
function Ds4UdpEvent(msgTypeIn, serverIdIn, senderIn,
	versionRspIn = undefined,
	portInfoIn = undefined,
	padDataRspIn = undefined) constructor {
	
	messageType	= msgTypeIn; // use this to check if other fields are present:
	
	serverId = serverIdIn;
	
	sender = senderIn;
	
	// data fields:
	
	versionRsp = versionRspIn; // set if messageType is VersionRsp
	
	portInfo = portInfoIn; // set if messageType is PortInfo
	
	padDataRsp = padDataRspIn; // set if messageType is PadDataRsp
}

/// @arg {String} [ipString] IP of the server, optional
/// @arg {Real} [portReal] Port of the server, optional
/// @desc This class communicates with the DS4Windows built-in UDP server, it must be enabled.
///       Will use the default address of 127.0.0.1:26760 if none is provided.
function Ds4UdpClient(ipString = undefined, portReal = undefined) constructor {
	srvIp = (is_undefined(ipString)) ? "127.0.0.1" : ipString;
	srvPort = (is_undefined(portReal) || portReal <= 0) ? 26760 : portReal;
	clSck = new Ds4UdpSocket(network_socket_udp);
	handlerFunction = undefined;
	
	// send out buffer area:
	scratchDataPos = 0;
	scratchPacketSizePos = 0;
	scratchBuff = new Ds4UdpBuffer(64, buffer_fixed, 1);
	
	// constants:
	protocolVersionReal = 1001;
	// the time when we reach this line cannot be predicated normally
	// since we allocate some stuff, set some variables, this takes microseconds.
	// so it's fiiine
	clientIdReal = (pi * get_timer()) & 0xFFFFFFFF; // must be random and u32, only if I cared
	
	/// @desc !DO NOT CALL THIS METHOD FROM PUBLIC CODE!
	/// @ignore
	chkDisposed = function() {
		if (is_undefined(clSck) || is_undefined(scratchBuff)) {
			throw new Ds4UdpException("Ds4UdpClient is disposed");
		}
	};
	
	/// @desc !DO NOT CALL THIS METHOD FROM PUBLIC CODE!
	/// @ignore
	beginPacket = function(messageIdReal) {
		chkDisposed();
		var b = scratchBuff;
		// prepare the buffer:
		b.fillAndReset();
		// -- header:
		//      magic:
		b.writeU8(0x44); // 'D'
		b.writeU8(0x53); // 'S'
		b.writeU8(0x55); // 'U'
		b.writeU8(0x43); // 'C'
		//      protocol version:
		b.writeU16(protocolVersionReal);
		//      packet size: (will need this later, stub for now)
		scratchPacketSizePos = b.tell();
		b.writeU16(0x0000);
		//      packet crc32: (will need this later, stub for now)
		scratchDataPos = b.tell();
		b.writeU32(0x00000000);
		//      client id:
		b.writeU32(clientIdReal);
		//      message id:
		b.writeU32(messageIdReal);
		return undefined;
	};
	
	/// @desc !DO NOT CALL THIS METHOD FROM PUBLIC CODE!
	/// @ignore
	endPacket = function() {
		chkDisposed();
		var b = scratchBuff;
		var posEnd = b.tell();
		// calculate packet size to fill in:
		// i have NO IDEA how is that supposed to work???
		// it always adds 16 to packet size when recieving
		// and it's commented "//packet size"
		// so... I just decrement 16 from final buffer????? wtf????
		b.pokeU16(scratchPacketSizePos, posEnd - 16);
		// calculate crc32 of the packet:
		var pktCrc32 = b.correctCrc32(0, posEnd);
		b.pokeU32(scratchDataPos, pktCrc32);
		// prepare for network send:
		b.seek();
		// do it:
		clSck.sendToUdp(srvIp, srvPort, b, posEnd);
		// await for an async event now:
		return undefined;
	};
	
	/// @desc !DO NOT CALL THIS METHOD FROM PUBLIC CODE!
	/// @ignore
	/// @arg {Struct.Ds4UdpBuffer} bufferStruct managed by socket, no need to call .dispose()
	/// @arg {String} inIpString IP of the client that sent data
	/// @arg {Real} inPortReal Port of the client
	/// @arg {Real} inDataSize actual size of the data received
	onSocketData = function(bufferStruct, inIpString, inPortReal, inDataSize) {
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
		
		var b = bufferStruct;
		// actually parse the thing:
		var h1 = b.readU8();
		var h2 = b.readU8();
		var h3 = b.readU8();
		var h4 = b.readU8();
		if (h1 != 0x44 || h2 != 0x53 || h3 != 0x55 || h4 != 0x53) {
			throw new Ds4UdpException("Invalid packet header, expected 'DSUS' as raw bytes.");
		}
		
		var srvProtocol = b.readU16();
		if (srvProtocol > protocolVersionReal) {
			throw new Ds4UdpException("Server protocol is higher than us, it is " + string(srvProtocol));
		}
		
		var srvPktLen = b.readU16(); // who cares about the length?
		srvPktLen += 16; // I hate this idea, this makes no sense! Just send the size of the entire pkt!
		if (inDataSize < srvPktLen) {
			throw new Ds4UdpException("Not enough bytes for packet, expected " + string(srvPktLen) + " got " + string(inDataSize));
		}
		
		// le crc stuff
		var srvCrc32Pos = b.tell(); // where it starts
		var srvPktCrc32 = b.readU32(); // read it
		b.pokeU32(srvCrc32Pos, 0x00000000); // dummy out the crc32 for calculation
		var srvActualCrc32 = b.correctCrc32(0, srvPktLen);
		if (srvActualCrc32 != srvPktCrc32) {
			throw new Ds4UdpException("Invalid CRC32 checksum of the packet, expected " + string(srvPktCrc32) + " got " + string(srvActualCrc32)); 
		}
		
		var srvId = b.readU32(); // will be pseudo-random, will not match our Client ID
		var msgType = b.readU32(); // ideally should be >0
		
		var ee = undefined;
		
		if (msgType == 0x100000) {
			// DSUC_VersionReq
			var eventDatap = new Ds4UdpEventVersionRsp();
			eventDatap.maxProtocolVersion = b.readU16();
			ee = new Ds4UdpEvent(Ds4UdpMessageType.VersionRsp, srvId, self, eventDatap, undefined, undefined);
			// and also 2 bytes padding for alignment which we can ignore
			// they should ideally be set to 0
		}
		else if (msgType == 0x100001) {
			// DSUC_ListPorts
			var eventDatai = new Ds4UdpEventPortInfo();
			eventDatai.padId = b.readU8();
			eventDatai.padState = b.readU8();
			eventDatai.model = b.readU8();
			eventDatai.connectionType = b.readU8();
			var m1 = b.readU8();
			var m2 = b.readU8();
			var m3 = b.readU8();
			var m4 = b.readU8();
			var m5 = b.readU8();
			var m6 = b.readU8();
			if (!(m1 == 0 && m2 == 0 && m3 == 0 && m4 == 0 && m5 == 0 && m6 == 0)) {
				// the order of the [] literal is undefined and is different between VM and YYC
				eventDatai.address = [ m1, m2, m3, m4, m5, m6 ];
			}
			eventDatai.batteryStatus = b.readU8();
			// and then there's a 1 byte of padding for alignment which we can ignore
			// ideally that byte should always be 0
			ee = new Ds4UdpEvent(Ds4UdpMessageType.PortInfo, srvId, self, undefined, eventDatai, undefined);
		}
		else if (msgType == 0x100002) {
			// DSUC_PadDataReq
			var eventDatad = new Ds4UdpEventPadDataRsp();
			eventDatad.padId = b.readU8();
			eventDatad.padState = b.readU8();
			eventDatad.model = b.readU8();
			eventDatad.connectionType = b.readU8();
			var m1 = b.readU8();
			var m2 = b.readU8();
			var m3 = b.readU8();
			var m4 = b.readU8();
			var m5 = b.readU8();
			var m6 = b.readU8();
			if (!(m1 == 0 && m2 == 0 && m3 == 0 && m4 == 0 && m5 == 0 && m6 == 0)) {
				// the order of the [] literal is undefined and is different between VM and YYC
				eventDatad.address = [ m1, m2, m3, m4, m5, m6 ];
			}
			eventDatad.batteryStatus = b.readU8();
			// here instead of the 0 padding byte we have extra fields:
			eventDatad.isActive = b.readU8();
			eventDatad.packetCounter = b.readU32();
			eventDatad.buttons1 = b.readU8();
			eventDatad.buttons2 = b.readU8();
			eventDatad.psButton = b.readU8();
			eventDatad.touchButton = b.readU8();
			eventDatad.lx = b.readU8();
			eventDatad.ly = b.readU8();
			eventDatad.rx = b.readU8();
			eventDatad.ry = b.readU8();
			eventDatad.dpadLeft = b.readU8();
			eventDatad.dpadDown = b.readU8();
			eventDatad.dpadRight = b.readU8();
			eventDatad.dpadUp = b.readU8();
			eventDatad.square = b.readU8();
			eventDatad.cross = b.readU8();
			eventDatad.circle = b.readU8();
			eventDatad.triangle = b.readU8();
			eventDatad.r1 = b.readU8();
			eventDatad.l1 = b.readU8();
			eventDatad.r2 = b.readU8();
			eventDatad.l2 = b.readU8();
			eventDatad.touch1Active = b.readU8();
			eventDatad.touch1PacketId = b.readU8();
			eventDatad.touch1X = b.readU16();
			eventDatad.touch1Y = b.readU16();
			eventDatad.touch2Active = b.readU8();
			eventDatad.touch2PacketId = b.readU8();
			eventDatad.touch2X = b.readU16();
			eventDatad.touch2Y = b.readU16();
			eventDatad.totalMicroSec = b.readU64();
			eventDatad.accelXG = b.readF32();
			eventDatad.accelYG = b.readF32();
			eventDatad.accelZG = b.readF32();
			eventDatad.angVelPitch = b.readF32();
			eventDatad.angVelYaw = b.readF32();
			eventDatad.angVelRoll = b.readF32();
			// the rest of bytes should be 0 (if any)
			ee = new Ds4UdpEvent(Ds4UdpMessageType.PadDataRsp, srvId, self, undefined, undefined, eventDatad);
		}
		else {
			// ?????? uh oh
			throw new Ds4UdpException("Unknown packet message id " + string(msgType) + " from server id " + string(srvId));
		}
		
		// call the handler if it's defined
		if (!is_undefined(handlerFunction)) {
			handlerFunction(ee);
		}
		
		return undefined;
	};
	
	/// @desc Returns the client's max protocol version, use when comparing to server
	/// @returns {Real} protocol version supported by this client
	getProtocolVersion = function() {
		return protocolVersionReal;
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
		var b = scratchBuff;
		b.writeU32(idsLen);
		var idsInd = 0; repeat (idsLen) {
			var slotId = idsToProbe[@ idsInd];
			b.writeU8(slotId);
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
		var b = scratchBuff;
		b.writeU8(regFlags);
		b.writeU8(idToReg);
		// loops in GML suck, so this should be actually faster lolz
		if (is_undefined(macToReg)) {
			// we must write something here no matter what, since it's still read
			b.writeU8(0);
			b.writeU8(0);
			b.writeU8(0);
			b.writeU8(0);
			b.writeU8(0);
			b.writeU8(0);
		}
		else {
			// use [@ for speed, also ensures the length and type
			b.writeU8(macToReg[@ 0]);
			b.writeU8(macToReg[@ 1]);
			b.writeU8(macToReg[@ 2]);
			b.writeU8(macToReg[@ 3]);
			b.writeU8(macToReg[@ 4]);
			b.writeU8(macToReg[@ 5]);
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
	
	/// @desc Resets the underlying socket, use this only if you are reconnecting.
	reset = function() {
		chkDisposed();
		clSck.reset();
		return self;
	};
	
	/// @desc Disposes of this client, no methods can be called on an instance of this class after this one.
	dispose = function() {
		if (!is_undefined(scratchBuff)) {
			scratchBuff = scratchBuff.dispose();
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

/// @desc the .messageType member of the data struct
enum Ds4UdpMessageType {
	VersionRsp = 0x100000,
	PortInfo   = 0x100001,
	PadDataRsp = 0x100002
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
