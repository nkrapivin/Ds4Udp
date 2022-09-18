/// @description OpenRGB Step

if (get_timer() < 0) { // place a breakpoint on this line when needed
	throw "how";
}

// use this to cycle:
funnycol = make_color_hsv((get_timer() / 100000) mod 256, 255, 255);

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
	client.updateLeds(deviceIndex, [ funnycol ]);
}
