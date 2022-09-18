/// @description Test start

function SlotData(inI = -1, inA = undefined, inD = new Ds4UdpEventPadDataRsp()) constructor {
	padId = inI;
	padMac = inA;
	data = inD;
	
	reset = function() {
		padId = -1;
		padMac = undefined;
		data = new Ds4UdpEventPadDataRsp();
	};
}

slotdata = [
	new SlotData(),
	new SlotData(),
	new SlotData(),
	new SlotData()
];
tmpind = -1; // packets arrive in order

serverId = -1;

pollAllData = function() {
	var slot = 0; repeat (array_length(slotdata)) {
		var data = slotdata[@ slot];
		//{
		if (data.padId > -1) {
			client.getPadDataReq(
				Ds4UdpRegFlags.IdIsValid | (is_undefined(data.padMac) ? Ds4UdpRegFlags.None : Ds4UdpRegFlags.MacIsValid),
				data.padId,
				data.padMac
			);
		}
		else {
			// disconnected!
			slotdata[@ slot].data = undefined;
		}
		//}
		++slot;
	}
};

pollAllPorts = function() {
	tmpind = 0; client.getListPorts();
};

/// @arg {Struct.Ds4UdpEventPadDataRsp} inData ...
setData = function(inData) {
	var slot = 0; repeat (array_length(slotdata)) {
		var data = slotdata[@ slot];
		//{
		if (data.padId == inData.padId) {
			if (inData.padState == Ds4UdpDsState.Disconnected) {
				slotdata[@ slot].reset();
			}
			else {
				slotdata[@ slot].data = inData;
			}
			exit;
		}
		//}
		++slot;
	}
};

lastGotTime = 0;
emergencyMargin = 5 * 1000000;

/// @arg {Struct.Ds4UdpEvent} e Event Data
function testcaseEventHandler(e) {
	if (serverId != -1 && serverId != e.serverId) {
		// not our server instance!
		show_debug_message("got packet for a different client wtf?!");
		exit;
	}
	
	lastGotTime = get_timer();
	var em = e.messageType;
	if (em == Ds4UdpMessageType.VersionRsp) {
		var versionRsp = e.versionRsp;
		var myprot = client.getProtocolVersion();
		show_debug_message("DS4Win protocol is " + string(versionRsp.maxProtocolVersion));
		show_debug_message("Client protocol is " + string(myprot));
		// hehe
		serverId = e.serverId;
		// now start polling for controllers:
		pollAllPorts();
	}
	else if (em == Ds4UdpMessageType.PortInfo) {
		var portinfo = e.portInfo;
		if (portinfo.padState == Ds4UdpDsState.Disconnected) {
			slotdata[@ tmpind].reset();
		}
		else {
			slotdata[@ tmpind].padId = portinfo.padId;
			slotdata[@ tmpind].address = portinfo.address;
			slotdata[@ tmpind].data = undefined;
		}
		
		++tmpind;
		
		if (tmpind == array_length(slotdata)) {
			tmpind = -1; // idle.
			// only poll for data when we received all info about slots
			pollAllData();
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
client.getVersionReq();

