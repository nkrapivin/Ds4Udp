/// @description Test start.

// to keep Feather happy, it's set to undefined down below
slotdata = [
	new Ds4UdpEventPadDataRsp(),
	new Ds4UdpEventPadDataRsp(),
	new Ds4UdpEventPadDataRsp(),
	new Ds4UdpEventPadDataRsp()
];

timer = 0;
lastGotTime = 0;
connectionMargin = 3 * 1000000; // every 3 secs
emergencyMargin = 2 * 1000000; // every 2 secs
serverId = -1; // -1 means no server

resetSlots = function() {
	var slot = 0, slotslen = array_length(slotdata); repeat (slotslen) {
		slotdata[@ (slot++)] = undefined;
	}
};

pollAllData = function() {
	// poll for everything
	client.getVersionReq();
	// the server MUST reply to this
	// if we get no data but get version, then server is up
	// but no controllers are connected
	client.getListPorts();
};

/// @arg {Struct.Ds4UdpEventPadDataRsp} inData ...
setData = function(inData) {
	if (inData.padState == Ds4UdpDsState.Disconnected) {
		slotdata[@ inData.padId] = undefined;
	}
	else {
		slotdata[@ inData.padId] = inData;
		// append the gamemaker timer stamp into the data
		slotdata[@ inData.padId].gmTimer = get_timer();
	}
};

clobberSlots = function() {
	var slot = 0, slotslen = array_length(slotdata); repeat (slotslen) {
		if (!is_undefined(slotdata[@ slot]) && (timer - slotdata[@ slot].gmTimer > connectionMargin)) {
			show_debug_message("Did not update slot " + string(slot) + " in a long time, clobbering...");
			slotdata[@ slot] = undefined;
		}
		
		++slot;
	}
};

/// @arg {Struct.Ds4UdpEvent} e Event Data
function testcaseEventHandler(e) {
	if (serverId != -1 && serverId != e.serverId) {
		// not our server instance!
		show_debug_message("got packet for a different client wtf?!");
		exit;
	}
	
	// last time we got something valid to our side
	lastGotTime = get_timer();
	var em = e.messageType;
	if (em == Ds4UdpMessageType.VersionRsp) {
		if (serverId == -1) {
			var versionRsp = e.versionRsp;
			var myprot = client.getProtocolVersion();
			show_debug_message("DS4Win protocol is " + string(versionRsp.maxProtocolVersion));
			show_debug_message("Client protocol is " + string(myprot));
			show_debug_message("Server ID is " + string(e.serverId));
			// hehe
			serverId = e.serverId;
		}
	}
	else if (em == Ds4UdpMessageType.PortInfo) {
		var pI = e.portInfo;
		if (pI.padState == Ds4UdpDsState.Disconnected) {
			slotdata[@ pI.padId] = undefined;
		}
		else {
			client.getPadDataReq(Ds4UdpRegFlags.IdIsValid, pI.padId);
		}
	}
	else if (em == Ds4UdpMessageType.PadDataRsp) {
		var dataRsp = e.padDataRsp;
		setData(dataRsp);
	}
}

handler = method(self, testcaseEventHandler);
client = new Ds4UdpClient();
client.setOnData(handler);
resetSlots();
