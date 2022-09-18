/// @description OpenRGB testcase

tempind = -1; // -1 means we can update the device list, !=-1 means updating
devices = []; // `undefined` means not yet received...
profileNames = [];

updateDeviceList = function() {
	if (tempind == -1) {
		client.requestControllerCount();
		show_debug_message("OpenRGB updating device list...");
	}
};

updateProfileList = function() {
	client.requestProfileList();
	show_debug_message("OpenRGB updating profile list...");
};

/// @arg {Struct.Ds4UdpLedEvent} e event data
handler = function(e) {
	var em = e.messageType;
	if (em == Ds4UdpLedMessage.ClientStateChange) {
		// not an actual OpenRGB message,
		// only a part of this funny thing to report socket state changes
		var isokay = e.clientStateChange.isConnected;
		if (!isokay) {
			show_debug_message("OpenRGB Disconnected (or connection failed)!");
			// the client will automatically reset it's own socket
			// and we need to get rid of everything as well:
			array_resize(devices, 0);
			array_resize(profileNames, 0);
			tempind = -1;
			// then try to connect again:
			client.reconnect();
			exit;
		}
		
		show_debug_message("OpenRGB Connected!");
		client.requestProtocolVersion();
	}
	else if (em == Ds4UdpLedMessage.ProtocolVersion) {
		var protver = e.protocolVersion.protocolVersion;
		show_debug_message("OpenRGB protocol = " + string(protver));
		client.setClientName("http://www.hampsterdance.com/");
		updateDeviceList();
	}
	else if (em == Ds4UdpLedMessage.ControllerCount) {
		var numDevs = e.controllerCount.controllerCount;
		devices = array_create(numDevs, undefined);
		if (numDevs > 0) {
			// start from first device and move onwards
			tempind = 0;
			client.requestControllerData(tempind);
		}
	}
	else if (em == Ds4UdpLedMessage.ControllerData) {
		// just copy the data
		devices[@ tempind] = e.controllerData;
		show_debug_message("OpenRGB Got device " + string(tempind));
		
		// yes I hate this too, alynne, >:(
		++tempind;
		if (tempind == array_length(devices)) {
			tempind = -1;
			show_debug_message("OpenRGB finished device update!");
			updateProfileList();
		}
		else {
			// advance to next device:
			client.requestControllerData(tempind);
		}
	}
	else if (em == Ds4UdpLedMessage.DeviceListUpdated) {
		updateDeviceList();
	}
	else if (em == Ds4UdpLedMessage.RequestProfileList) {
		var profnamesarr = e.profileList.profileList;
		profileNames = profnamesarr;
		show_debug_message("OpenRGB Profile Names: " + string(profileNames));
	}
};


client = new Ds4UdpLedClient();
client.setOnData(handler);
//-- Since we're on a TCP connection, we need to wait for a connection first...

funnycol = c_white;
