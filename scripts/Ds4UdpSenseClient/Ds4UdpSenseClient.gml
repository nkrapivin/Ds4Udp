// Feather disable GM2017
// that thing is so awful at naming suggestions that I gave up
// everything else? Sure, please!

#macro DUALSENSE_X_PRINT_THE_TRUTH false

enum Ds4UdpSenseTriggerMode {
    Normal = 0,
    GameCube = 1,
    VerySoft = 2,
    Soft = 3,
    Hard = 4,
    VeryHard = 5,
    Hardest = 6,
    Rigid = 7,
    VibrateTrigger = 8,
    Choppy = 9,
    Medium = 10,
    VibrateTriggerPulse = 11,
    CustomTriggerValue = 12,
    Resistance = 13,
    Bow = 14,
    Galloping = 15,
    SemiAutomaticGun = 16,
    AutomaticGun = 17,
    Machine = 18
};

enum Ds4UdpSenseCustomTriggerValueMode {
    OFF = 0,
    Rigid = 1,
    RigidA = 2,
    RigidB = 3,
    RigidAB = 4,
    Pulse = 5,
    PulseA = 6,
    PulseB = 7,
    PulseAB = 8,
    VibrateResistance = 9,
    VibrateResistanceA = 10,
    VibrateResistanceB = 11,
    VibrateResistanceAB = 12,
    VibratePulse = 13,
    VibratePulseA = 14,
    VibratePulsB = 15,
    VibratePulseAB = 16
};

enum Ds4UdpSensePlayerLEDNewRevision {
    One = 0,
    Two = 1,
    Three = 2,
    Four = 3,
    Five = 4, // Five is Also All On
    AllOff = 5
};

enum Ds4UdpSenseMicLEDMode {
    On = 0,
    Pulse = 1,
    Off = 2
};

enum Ds4UdpSenseTrigger {
    Invalid,
    Left,
    Right
};

enum Ds4UdpSenseInstructionType {
    Invalid,
    TriggerUpdate,
    RGBUpdate,
    PlayerLED,
    TriggerThreshold,
    MicLED,
    PlayerLEDNewRevision
};

/// @desc This struct is only used for Feather type checks,
///       Do not actually call instanceof() on this,
///       the struct in the events will come from json_parse()!
function Ds4UdpSenseServerResponse() constructor {
	Status = "";
	TimeReceived = "";
	isControllerConnected = false;
	BatteryLevel = 0;
}

/// @arg {Bool} isSuccessBool whether the response was parsed successfully or not
/// @arg {Struct.Ds4UdpSenseServerResponse} responseOrExceptionStruct server reply if isSuccess is true, a gml exception or undefined otherwise
function Ds4UdpSenseEvent(isSuccessBool, responseOrExceptionStruct) constructor {
	isSuccess = isSuccessBool;
	serverResponse = responseOrExceptionStruct;
}

/// @arg {Enum.Ds4UdpSenseInstructionType} instructionType type of this instruction
/// @desc The rest are instruction parameters, see code examples
function Ds4UdpSenseInstruction(instructionType /* ... */) constructor {
	type = instructionType; // must be passed, or else it will crash
	
	var paramLen = argument_count - 1, paramInd = 0;
	parameters = array_create(paramLen, undefined); // the array itself must not be undefined
	
	repeat (paramLen) {
		var paramArg = argument[1 + paramInd];
		if (is_bool(paramArg)) {
			// cast into an explicit bool
			paramArg = bool(paramArg);
		}
		else {
			// floor for good measure
			paramArg = floor(paramArg);
		}
		
		parameters[@ paramInd] = paramArg;
		++paramInd;
	}
}

/// @arg {String} [ipString] IP of the server, optional
/// @arg {Real} [portReal] Port of the server, optional
/// @desc DualSense-X UDP client implementation, god help us.
function Ds4UdpSenseClient(ipString = undefined, portReal = undefined) constructor {
	srvIp = (is_undefined(ipString)) ? "127.0.0.1" : ipString;
	srvPort = (is_undefined(portReal) || portReal <= 0) ? 6969 : portReal;
	clSck = new Ds4UdpSocket(network_socket_udp);
	handlerFunction = undefined;
	scratchBuff = new Ds4UdpBuffer(1, buffer_grow, 1);
	static justThisOnce = false;
	
	/// @desc !DO NOT CALL THIS METHOD FROM PUBLIC CODE!
	/// @ignore
	fillBufferWithStringAndSend = function(contentsString) {
		var b = scratchBuff;
		b.fillAndReset();
		b.writeString(contentsString);
		var posEnd = b.tell(); // raw length of the string without nullbytes
		b.seek();
		clSck.sendToUdp(srvIp, srvPort, b, posEnd);
	};
	
	/// @desc !DO NOT CALL THIS METHOD FROM PUBLIC CODE!
	/// @ignore
	chkDisposed = function() {
		if (is_undefined(clSck) || is_undefined(scratchBuff)) {
			throw new Ds4UdpException("Ds4UdpSenseClient is disposed");
		}
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
		
		if (DUALSENSE_X_PRINT_THE_TRUTH) {
			// to make sure it's optimized out when not true
			if (!justThisOnce /* static */) {
				justThisOnce = true;
				show_debug_message("DualSense-X is such an awful, bloated, poorly coded app, that I added support for this purely out of spite. Seriously, trigger usage leaderboards?! Are you fucking stupid or something? Who in the right mind needs this? Go get a life! -Nikita");
			}
		}
		
		var isOkay = false;
		var structData = undefined;
		
		try {
			var b = bufferStruct;
			var jsonString = b.readCString(); // read until we hit a nullbyte or buffer ends
			var testJsonParse = json_parse(jsonString);
			structData = testJsonParse;
			isOkay = true; // only set isOkay if assignment was successful and we didn't crash
		} catch (jsonParseException) {
			structData = jsonParseException;
		}
		
		var evt = new Ds4UdpSenseEvent(isOkay, structData);
		if (!is_undefined(handlerFunction)) {
			handlerFunction(evt);
		}
	};
	
	/// @arg {Function} onEventFunction called when there is some reply to some packet
	setOnData = function(onEventFunction) {
		chkDisposed();
		handlerFunction = onEventFunction;
		return self;
	};
	
	/// @arg {Array<Struct.Ds4UdpSenseInstruction>} instructionsArray a list of instruction structs to be sent over network
	/// @desc Sends a list of instructions to the UDP server in DualSense-X.
	sendInstructions = function(instructionsArray) {
		var instructionsStruct = { instructions: instructionsArray };
		var instructionsJson = json_stringify(instructionsStruct);
		fillBufferWithStringAndSend(instructionsJson);
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

// Feather restore GM2017

