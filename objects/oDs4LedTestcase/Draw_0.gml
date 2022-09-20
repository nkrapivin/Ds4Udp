/// @description OpenRGB device info

if (tempind != -1) {
	// refreshing the device list... do not interrupt...
	exit;
}

var numDevs = array_length(devices);
for (var d = 0; d < numDevs; ++d) {
	var deviceData = devices[@ d];
	if (is_undefined(deviceData)) {
		// have not received this device yet...
		continue;
	}
	
	var deviceIndex = d;
	// can now use deviceData in conjunction with deviceIndex


	// TODO: your code here...
	draw_text(64, room_height/2 + deviceIndex * 64,
		string(deviceData)
	);
}

