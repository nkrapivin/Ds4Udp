// Feather disable GM2017
// that thing is so awful at naming suggestions that I gave up
// everything else? Sure, please!

/// @desc Event type
enum Ds4UdpLedMessage {
	ClientStateChange = -1024,
	ControllerCount = 0,
	ControllerData = 1,
	ProtocolVersion = 40,
	SetClientName = 50,
	DeviceListUpdated = 100,
	RequestProfileList = 150,
	SaveProfile = 151,
	LoadProfile = 152,
	DeleteProfile = 153,
	RgbControllerResizeZone = 1000,
	RgbControllerUpdateLeds = 1050,
	RgbControllerUpdateZoneLeds = 1051,
	RgbControllerUpdateSingleLed = 1052,
	RgbControllerSetCustomMode = 1100,
	RgbControllerUpdateMode = 1101,
	RgbControllerSaveMode = 1102
};

/*------------------------------------------------------------------*\
| Mode Flags                                                         |
\*------------------------------------------------------------------*/
enum Ds4UdpLedModeFlag {
    HasSpeed                 = (1 << 0), /* Mode has speed parameter         */
    HasDirectionLR           = (1 << 1), /* Mode has left/right parameter    */
    HasDirectionUD           = (1 << 2), /* Mode has up/down parameter       */
    HasDirectionHV           = (1 << 3), /* Mode has horiz/vert parameter    */
    HasBrightness            = (1 << 4), /* Mode has brightness parameter    */
    HasPerLedColor           = (1 << 5), /* Mode has per-LED colors          */
    HasModeSpecificColor     = (1 << 6), /* Mode has mode specific colors    */
    HasRandomColor           = (1 << 7), /* Mode has random color option     */
    ManualSave               = (1 << 8), /* Mode can manually be saved       */
    AutomaticSave            = (1 << 9), /* Mode automatically saves         */
};

/*------------------------------------------------------------------*\
| Mode Directions                                                    |
\*------------------------------------------------------------------*/
enum Ds4UdpLedModeDirection {
    Left         = 0,        /* Mode direction left              */
    Right        = 1,        /* Mode direction right             */
    Up           = 2,        /* Mode direction up                */
    Down         = 3,        /* Mode direction down              */
    Horizontal   = 4,        /* Mode direction horizontal        */
    Vertical     = 5,        /* Mode direction vertical          */
};

/*------------------------------------------------------------------*\
| Mode Color Types                                                   |
\*------------------------------------------------------------------*/
enum Ds4UdpLedModeColors {
    None            = 0,        /* Mode has no colors               */
    PerLed          = 1,        /* Mode has per LED colors selected */
    ModeSpecific    = 2,        /* Mode specific colors selected    */
    Random          = 3,        /* Mode has random colors selected  */
};

enum Ds4UdpLedZoneType {
    Single,
    Linear,
    Matrix
};

enum Ds4UdpLedDeviceType {
    Motherboard,
    Dram,
    Gpu,
    Cooler,
    LedStrip,
    Keyboard,
    Mouse,
    MouseMat,
    Headset,
    HeadsetStand,
    Gamepad, // my beloved
    Light,
    Speaker,
    Virtual,
    Storage,
    Case,
    Microphone,
    Accessory,
    Unknown,
};



/// @arg {Array<String>} [hintA] profileList
function Ds4UdpProfileListEvent(hintA = []) constructor {
	profileList = hintA;
}

function Ds4UdpLedBlock() constructor {
	ledName = "";
	ledValue = 0;
}

/// @arg {Array<Array<Real>>} [hintA] zoneMatrixData
/// @arg {Enum.Ds4UdpLedZoneType} [hintB] zoneType
function Ds4UdpLedZone(hintA = [], hintB = Ds4UdpLedZoneType.Single) constructor {
	zoneName = "";
	zoneType = hintB;
	zoneLedsMin = 0;
	zoneLedsMax = 0;
	zoneLedsCount = 0;
	zoneMatrixData = hintA;
}

/// @arg {Array<Constant.Color>} [hintA] colors
/// @arg {Enum.Ds4UdpLedModeFlag} [hintB] modeFlags
/// @arg {Enum.Ds4UdpLedModeDirection} [hintC] modeDirection
/// @arg {Enum.Ds4UdpLedModeColors} [hintD] modeColorMode
function Ds4UdpLedMode(hintA = [], hintB = Ds4UdpLedModeFlag.HasBrightness, hintC = Ds4UdpLedModeDirection.Down, hintD = Ds4UdpLedModeColors.None) constructor {
	modeName = "";
	modeValue = 0;
	modeFlags = hintB;
	modeSpeedMin = 0;
	modeSpeedMax = 0;
	modeBrightnessMin = undefined; // protocol 3+ only
	modeBrightnessMax = undefined; // protocol 3+ only
	modeColorsMin = 0;
	modeColorsMax = 0;
	modeSpeed = 0;
	modeBrightness = undefined; // protocol 3+ only
	modeDirection = hintC;
	modeColorMode = hintD;
	modeColors = hintA;
}

/// @arg {Array<Struct.Ds4UdpLedMode>} [hintA] modes
/// @arg {Array<Struct.Ds4UdpLedZone>} [hintB] zones
/// @arg {Array<Struct.Ds4UdpLedBlock>} [hintC] leds
/// @arg {Array<Constant.Color>} [hintD] colors
/// @arg {Enum.Ds4UdpLedDeviceType} [hintE] type
function Ds4UdpLedControllerDataEvent(hintA = [], hintB = [], hintC = [], hintD = [], hintE = Ds4UdpLedDeviceType.Unknown) constructor {
	type = hintE;
	name = "";
	vendor = undefined; // protocol >0 only!
	description = "";
	version = "";
	serial = "";
	location = "";
	activeMode = 0;
	modes = hintA;
	zones = hintB;
	leds = hintC;
	colors = hintD;
}

function Ds4UdpLedControllerCountEvent() constructor {
	controllerCount = 0;
}

function Ds4UdpLedDeviceListUpdatedEvent() constructor {
	// no data...	
}

function Ds4UdpLedProtocolVersionEvent() constructor {
	protocolVersion = 0;
}

function Ds4UdpLedClientStateChangeEvent() constructor {
	isConnected = false;
}

/// @arg {Enum.Ds4UdpLedMessage} messageTypeIn incoming message type
/// @arg {Struct.Ds4UdpLedClient} senderIn sender of the event
/// @arg {Struct.Ds4UdpLedClientStateChangeEvent} [hintA] clientStateChange
/// @arg {Struct.Ds4UdpLedProtocolVersionEvent} [hintB] protocolVersion
/// @arg {Struct.Ds4UdpLedDeviceListUpdatedEvent} [hintC] deviceListUpdated
/// @arg {Struct.Ds4UdpLedControllerCountEvent} [hintD] controllerCount
/// @arg {Struct.Ds4UdpLedControllerDataEvent} [hintE] controllerData
/// @arg {Struct.Ds4UdpProfileListEvent} [hintF] profileList
/// @desc Ds4UdpLed Event class, messageType determines which fields are available
function Ds4UdpLedEvent(messageTypeIn, senderIn, hintA = undefined, hintB = undefined, hintC = undefined, hintD = undefined, hintE = undefined, hintF = undefined) constructor {
	messageType = messageTypeIn;
	sender = senderIn;
	
	clientStateChange = hintA;
	protocolVersion = hintB;
	deviceListUpdated = hintC;
	controllerCount = hintD;
	controllerData = hintE;
	profileList = hintF;
}

/// @desc OpenRGB client implementation
/// @arg {String} [ipString] IP address of the server as a string, defaults to 127.0.0.1
/// @arg {Real} [portReal] Port of the server, optional
function Ds4UdpLedClient(ipString = undefined, portReal = undefined) constructor {
	srvIp = (is_undefined(ipString)) ? "127.0.0.1" : ipString;
	srvPort = (is_undefined(portReal) || portReal <= 0) ? 6742 : portReal;
	clSck = new Ds4UdpSocket(network_socket_tcp);
	handlerFunction = undefined;
	isConnected = false;
	scratchBuff = new Ds4UdpBuffer(64, buffer_grow, 1);
	scratchSizePos = 0;
	scratchBeginPos = 0;
	protocolVersionReal = 3;
	srvProtocol = 0;
	
	/// @desc !DO NOT CALL THIS METHOD FROM PUBLIC CODE!
	/// @ignore
	chkDisposed = function() {
		if (is_undefined(clSck) || is_undefined(scratchBuff)) {
			throw new Ds4UdpException("Ds4UdpLedClient is disposed");
		}
	};
	
	/// @desc Returns the client's max protocol version, use when comparing to server
	/// @returns {Real} protocol version supported by this client
	getProtocolVersion = function() {
		return protocolVersionReal;
	};
	
	/// @desc !DO NOT CALL THIS METHOD FROM PUBLIC CODE!
	/// @ignore
	beginPacket = function(messageId, deviceIndex = 0) {
		var b = scratchBuff;
		b.fillAndReset();
		b.writeU8(0x4F);
		b.writeU8(0x52);
		b.writeU8(0x47);
		b.writeU8(0x42);
		b.writeU32(deviceIndex);
		b.writeU32(messageId);
		scratchSizePos = b.tell();
		b.writeU32(0x00000000); // packet size: to be filled in later
		scratchBeginPos = b.tell();
	};
	
	/// @desc !DO NOT CALL THIS METHOD FROM PUBLIC CODE!
	/// @ignore
	endPacket = function() {
		var b = scratchBuff;
		var wholeLength = b.tell();
		var pktLength = wholeLength - scratchBeginPos;
		b.pokeU32(scratchSizePos, pktLength);
		b.seek();
		try {
			clSck.sendToTcp(b, wholeLength);
		} catch (socketException) {
			if (!is_undefined(handlerFunction)) {
				var e = new Ds4UdpLedEvent(Ds4UdpLedMessage.ClientStateChange, self);
				var evd = new Ds4UdpLedClientStateChangeEvent();
				evd.isConnected = false;
				e.clientStateChange = evd;
				handlerFunction(e);
			}
		}
		// wait for an async event...
		return undefined;
	};
	
	/// @arg {Struct.Ds4UdpBuffer} b buffer
	/// @arg {Struct.Ds4UdpLedMode} modeStruct mode data block
	/// @returns {Real} wrote size
	/// @desc !DO NOT CALL THIS METHOD FROM PUBLIC CODE!
	/// @ignore
	writeModeStruct = function(b, modeStruct) {
		var now = b.tell();
		b.writeU16(string_byte_length(modeStruct.modeName) + 1);
		b.writeCString(modeStruct.modeName);
		b.writeS32(modeStruct.modeValue);
		b.writeU32(modeStruct.modeFlags);
		b.writeU32(modeStruct.modeSpeedMin);
		b.writeU32(modeStruct.modeSpeedMax);
		if (srvProtocol > 2) {
			b.writeU32(modeStruct.modeBrightnessMin);
			b.writeU32(modeStruct.modeBrightnessMax);
		}
		b.writeU32(modeStruct.modeColorsMin);
		b.writeU32(modeStruct.modeColorsMax);
		b.writeU32(modeStruct.modeSpeed);
		if (srvProtocol > 2) {
			b.writeU32(modeStruct.modeBrightness);
		}
		b.writeU32(modeStruct.modeDirection);
		b.writeU32(modeStruct.modeColorMode);
		var numColors = array_length(modeStruct.modeColors);
		b.writeU16(numColors);
		for (var c = 0; c < numColors; ++c) {
			b.writeU32(modeStruct.modeColors[@ c]);
		}
		return b.tell() - now;
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
		var h1 = b.readU8();
		var h2 = b.readU8();
		var h3 = b.readU8();
		var h4 = b.readU8();
		if (h1 != 0x4F || h2 != 0x52 || h3 != 0x47 || h4 != 0x42) {
			throw new Ds4UdpException("Invalid packet header, expected 'ORGB' as raw bytes.");
		}
		
		var deviceIndex = b.readU32();
		var packetId = b.readU32();
		var packetSize = b.readU32();
		packetSize += 16; // size of header
		if (inDataSize < packetSize) {
			throw new Ds4UdpException("Not enough bytes for packet, expected " + string(srvPktLen) + " got " + string(inDataSize));
		}
		
		var ev = new Ds4UdpLedEvent(packetId, self);
		
		if (packetId == Ds4UdpLedMessage.ProtocolVersion) {
			var pvev = new Ds4UdpLedProtocolVersionEvent();
			// only read if we actually have the data in the packet
			if (packetSize >= 16 + buffer_sizeof(buffer_u32)) {
				pvev.protocolVersion = b.readU32();
			}
			// sneaky sneaky us... :3
			srvProtocol = pvev.protocolVersion;
			ev.protocolVersion = pvev;
		}
		else if (packetId == Ds4UdpLedMessage.DeviceListUpdated) {
			var dluev = new Ds4UdpLedDeviceListUpdatedEvent();
			// no data... just update the list please
			ev.deviceListUpdated = dluev;
		}
		else if (packetId == Ds4UdpLedMessage.ControllerCount) {
			var ccev = new Ds4UdpLedControllerCountEvent();
			ccev.controllerCount = b.readU32();
			ev.controllerCount = ccev;
		}
		else if (packetId == Ds4UdpLedMessage.ControllerData) {
			var cdev = new Ds4UdpLedControllerDataEvent();
			b.readU32();
			cdev.type = b.readS32();
			b.readU16();
			cdev.name = b.readCString();
			if (srvProtocol > 0) {
				b.readU16();
				cdev.vendor = b.readCString();
			}
			b.readU16();
			cdev.description = b.readCString();
			b.readU16();
			cdev.version = b.readCString();
			b.readU16();
			cdev.serial = b.readCString();
			b.readU16();
			cdev.location = b.readCString();
			var numModes = b.readU16();
			cdev.activeMode = b.readS32();
			for (var m = 0; m < numModes; ++m) {
				var mb = new Ds4UdpLedMode();
				b.readU16();
				mb.modeName = b.readCString();
				mb.modeValue = b.readS32();
				mb.modeFlags = b.readU32();
				mb.modeSpeedMin = b.readU32();
				mb.modeSpeedMax = b.readU32();
				if (srvProtocol > 2) {
					mb.modeBrightnessMin = b.readU32();
					mb.modeBrightnessMax = b.readU32();
				}
				mb.modeColorsMin = b.readU32();
				mb.modeColorsMax = b.readU32();
				mb.modeSpeed = b.readU32();
				if (srvProtocol > 2) {
					mb.modeBrightness = b.readU32();
				}
				mb.modeDirection = b.readU32();
				mb.modeColorMode = b.readU32();
				var numColors = b.readU16();
				for (var c = 0; c < numColors; ++c) {
					mb.modeColors[@ c] = b.readU32();
				}
				cdev.modes[@ m] = mb;
			}
			var numZones = b.readU16();
			for (var z = 0; z < numZones; ++z) {
				var zb = new Ds4UdpLedZone();
				b.readU16();
				zb.zoneName = b.readCString();
				zb.zoneType = b.readS32();
				zb.zoneLedsMin = b.readU32();
				zb.zoneLedsMax = b.readU32();
				zb.zoneLedsCount = b.readU32();
				var zml = b.readU16();
				if (zml > 0) {
					var zmh = b.readU32();
					var zmw = b.readU32();
					for (var zmx = 0; zmx < zmw; ++zmx) {
						zb.zoneMatrixData[@ zmx] = array_create(zmh);
						for (var zmy = 0; zmy < zmh; ++zmy) {
							zb.zoneMatrixData[@ zmx][@ zmy] = b.readU32();
						}
					}
				}
				cdev.zones[@ z] = zb;
			}
			var numLeds = b.readU16();
			for (var l = 0; l < numLeds; ++l) {
				var lb = new Ds4UdpLedBlock();
				b.readU16();
				lb.ledName = b.readCString();
				lb.ledValue = b.readU32();
				cdev.leds[@ l] = lb;
			}
			var numColors = b.readU16();
			for (var c = 0; c < numColors; ++c) {
				var col = b.readU32();
				cdev.colors[@ c] = col;
			}
			ev.controllerData = cdev;
		}
		else if (packetId == Ds4UdpLedMessage.RequestProfileList) {
			var rplev = new Ds4UdpProfileListEvent();
			b.readU32();
			var numProfiles = b.readU16();
			for (var p = 0; p < numProfiles; ++p) {
				b.readU16();
				rplev.profileList[@ p] = b.readCString();
			}
			ev.profileList = rplev;
		}
		else {
			throw new Ds4UdpException("Unexpected OpenRGB Packet ID: " + string(packetId));
		}
		
		if (!is_undefined(handlerFunction)) {
			handlerFunction(ev);
		}
		
		return undefined;
	};
	
	/// @desc !DO NOT CALL THIS METHOD FROM PUBLIC CODE!
	/// @ignore
	/// @arg {Constant.NetworkType} stateResult Only network_type_connect or network_type_disconnect
	onSocketState = function(stateResult) {
		chkDisposed();
		isConnected = stateResult == network_type_connect;
		srvProtocol = 0;
		if (!is_undefined(handlerFunction)) {
			var e = new Ds4UdpLedEvent(Ds4UdpLedMessage.ClientStateChange, self);
			var evd = new Ds4UdpLedClientStateChangeEvent();
			evd.isConnected = isConnected;
			e.clientStateChange = evd;
			handlerFunction(e);
		}
		return undefined;
	};
	
	/// @desc Requests the protocol version from the server
	requestProtocolVersion = function() {
		beginPacket(Ds4UdpLedMessage.ProtocolVersion);
		var b = scratchBuff;
		b.writeU32(protocolVersionReal);
		endPacket();
		return self;
	};
	
	/// @desc Requests controller count
	requestControllerCount = function() {
		beginPacket(Ds4UdpLedMessage.ControllerCount);
		endPacket();
		return self;
	};
	
	/// @arg {Real} deviceIndexReal the device index, must be positive
	/// @desc Requests controller data for deviceIndexReal
	requestControllerData = function(deviceIndexReal) {
		beginPacket(Ds4UdpLedMessage.ControllerData, deviceIndexReal);
		var b = scratchBuff;
		if (srvProtocol > 0) {
			// write the protocol we got from the server, not ours
			b.writeU32(srvProtocol);
		}
		endPacket();
		return self;
	};
	
	/// @desc Requests a profile list, the server will reply later
	requestProfileList = function() {
		beginPacket(Ds4UdpLedMessage.RequestProfileList);
		endPacket();
		return self;
	};
	
	/// @arg {String} profileNameString name of the profile to target
	/// @desc saves a profile to storage
	saveProfile = function(profileNameString) {
		beginPacket(Ds4UdpLedMessage.SaveProfile);
		var b = scratchBuff;
		b.writeCString(profileNameString);
		endPacket();
		return self;
	};
	
	/// @arg {String} profileNameString name of the profile to target
	/// @desc loads a profile to be applied later
	loadProfile = function(profileNameString) {
		beginPacket(Ds4UdpLedMessage.LoadProfile);
		var b = scratchBuff;
		b.writeCString(profileNameString);
		endPacket();
		return self;
	};
	
	/// @arg {String} profileNameString name of the profile to target
	/// @desc deletes a profile
	deleteProfile = function(profileNameString) {
		beginPacket(Ds4UdpLedMessage.DeleteProfile);
		var b = scratchBuff;
		b.writeCString(profileNameString);
		endPacket();
		return self;
	};
	
	/// @arg {Real} deviceIndexReal the device index, must be positive
	/// @arg {Real} zoneIndexReal zone index, must be positive
	/// @arg {Real} newZoneSizeReal new zone size, must be positive
	/// @desc Calls ResizeZone()
	resizeZone = function(deviceIndexReal, zoneIndexReal, newZoneSizeReal) {
		beginPacket(Ds4UdpLedMessage.RgbControllerResizeZone, deviceIndexReal);
		var b = scratchBuff;
		b.writeS32(zoneIndexReal);
		b.writeS32(newZoneSizeReal);
		endPacket();
		return self;
	};
	
	/// @arg {Real} deviceIndexReal the device index, must be positive
	/// @arg {Array<Constant.Color>} colorValues array of GameMaker color values
	/// @desc Calls UpdateLEDs()
	updateLeds = function(deviceIndexReal, colorValues) {
		beginPacket(Ds4UdpLedMessage.RgbControllerUpdateLeds, deviceIndexReal);
		var b = scratchBuff;
		var colorLen = array_length(colorValues);
		// no idea why
		b.writeU32(buffer_sizeof(buffer_u32) + buffer_sizeof(buffer_u16) + colorLen * buffer_sizeof(buffer_u32));
		// the actual color data:
		b.writeU16(colorLen);
		for (var c = 0; c < colorLen; ++c) {
			b.writeU32(colorValues[@ c]);
		}
		endPacket();
		return self;
	};
	
	/// @arg {Real} deviceIndexReal the device index, must be positive
	/// @arg {Real} zoneIndexReal index of the led zone, must be positive
	/// @arg {Array<Constant.Color>} colorValues array of GameMaker color values
	/// @desc Calls UpdateZoneLEDs() with color values
	updateZoneLeds = function(deviceIndexReal, zoneIndexReal, colorValues) {
		beginPacket(Ds4UdpLedMessage.RgbControllerUpdateZoneLeds, deviceIndexReal);
		var b = scratchBuff;
		var colorLen = array_length(colorValues);
		// no idea why
		b.writeU32(buffer_sizeof(buffer_u32) + buffer_sizeof(buffer_u32) + buffer_sizeof(buffer_u16) + colorLen * buffer_sizeof(buffer_u32));
		// the actual color data:
		b.writeU32(zoneIndexReal);
		b.writeU16(colorLen);
		for (var c = 0; c < colorLen; ++c) {
			b.writeU32(colorValues[@ c]);
		}
		endPacket();
		return self;
	};
	
	/// @arg {Real} deviceIndexReal the device index, must be positive
	/// @arg {Real} ledIndexReal index of the led, must be positive
	/// @arg {Constant.Color} color new color of the led to set
	/// @desc Calls UpdateSingleLED() with color
	updateSingleLed = function(deviceIndexReal, ledIndexReal, color) {
		beginPacket(Ds4UdpLedMessage.RgbControllerUpdateSingleLed, deviceIndexReal);
		var b = scratchBuff;
		b.writeS32(ledIndexReal);
		b.writeU32(color);
		endPacket();
		return self;
	};
	
	/// @arg {Real} deviceIndexReal the device index, must be positive
	/// @desc Calls SetCustomMode()
	setCustomMode = function(deviceIndexReal) {
		beginPacket(Ds4UdpLedMessage.RgbControllerSetCustomMode, deviceIndexReal);
		// no data...
		endPacket();
		return self;
	};
	
	/// @arg {String} clientNameString client name as a string, must not be empty
	/// @desc Sets the name of this client
	setClientName = function(clientNameString) {
		beginPacket(Ds4UdpLedMessage.SetClientName);
		var b = scratchBuff;
		b.writeCString(clientNameString);
		endPacket();
		return self;
	};
	
	/// @arg {Real} deviceIndexReal the device index, must be positive
	/// @arg {Real} modeIndexReal the device mode index, must be positive
	/// @arg {Struct.Ds4UdpLedMode} modeStruct devide mode struct
	/// @desc Calls UpdateMode() on the device
	updateMode = function(deviceIndexReal, modeIndexReal, modeStruct) {
		beginPacket(Ds4UdpLedMessage.RgbControllerUpdateMode);
		var b = scratchBuff;
		var spos = b.tell();
		b.writeU32(0x00000000); // to be patched later
		b.writeS32(modeIndexReal);
		var allSize = buffer_sizeof(buffer_u32) + buffer_sizeof(buffer_s32) + writeModeStruct(b, modeStruct);
		b.pokeU32(spos, allSize);
		endPacket();
		return self;
	};
	
	/// @arg {Real} deviceIndexReal the device index, must be positive
	/// @arg {Real} modeIndexReal the device mode index, must be positive
	/// @arg {Struct.Ds4UdpLedMode} modeStruct devide mode struct
	/// @desc Calls UpdateMode() on the device
	saveMode = function(deviceIndexReal, modeIndexReal, modeStruct) {
		beginPacket(Ds4UdpLedMessage.RgbControllerSaveMode);
		var b = scratchBuff;
		var spos = b.tell();
		b.writeU32(0x00000000); // to be patched later
		b.writeS32(modeIndexReal);
		var allSize = buffer_sizeof(buffer_u32) + buffer_sizeof(buffer_s32) + writeModeStruct(b, modeStruct);
		b.pokeU32(spos, allSize);
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
	
	/// @desc Attempts to reconnect the socket if not connected.
	reconnect = function() {
		chkDisposed();
		if (isConnected) {
			reset();
		}
		
		clSck.connectToTcp(srvIp, srvPort);
		return self;
	};
	
	/// @desc Attempts to set timeout for the owned socket
	/// @arg {Real} readTimeoutReal Read/Receive timeout in miliseconds
	/// @arg {Real} writeTimeoutReal Write/Send timeout in miliseconds
	setTimeouts = function(readTimeoutReal, writeTimeoutReal) {
		chkDisposed();
		clSck.setTimeouts(readTimeoutReal, writeTimeoutReal);
		return self;
	};
	
	/// @desc Resets the underlying socket, use this only if you have to.
	reset = function() {
		chkDisposed();
		clSck.reset();
		isConnected = false;
		srvProtocol = 0;
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
		
		isConnected = false;
		srvProtocol = 0;
		return undefined;
	};
	
	// set the data handler for our socket
	clSck.setOnState(onSocketState);
	clSck.setOnData(onSocketData);
}

// Feather restore GM2017
