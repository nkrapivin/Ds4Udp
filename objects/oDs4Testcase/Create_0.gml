/// @description Test start

lastthing = {};
lastdatathing = {};
lasttime = 0;
curtime = 0;
timediff = 0;

handler = function(e) {
	var em = e.messageTypeReal;
	if (em == 0x100000) {
		var prot = e.maxProtocolVersion;
		// ideally should be equal to our protocol hopefully...
		show_debug_message("DS4Win protocol is " + string(prot));
	}
	else if (em == 0x100001) {
		// see
		// https://github.com/Ryochan7/DS4Windows/blob/ef6f5b1d2f8337e48a3f2c00025b007175662094/DS4Windows/DS4Control/UdpServer.cs#L68
		// for fields
		// from Line 85 to Line 97
		// the names are exact same
		// except e.address will be `undefined` if it's all bits zero.
		// (so you don't have to compare it yourself!)
		client.getPadDataReq(
			Ds4UdpRegFlags.IdIsValid |
				(is_undefined(e.address)
					? Ds4UdpRegFlags.None
					: Ds4UdpRegFlags.MacIsValid
				),
			e.padId,
			e.address
		);
		//show_debug_message("Got pad id " + string (e.padId));
		lastthing = e;
	}
	else if (em == 0x100002) {
		// here all fields from the 0x100001 apply
		// plus some extra ones after "padBatteryStatus"
		// their names are exactly as in that structure.
		//show_debug_message("Got pad id data " + string (e.padId));
		lastdatathing = e; // do a ref assign
		
		lasttime = curtime;
		curtime = get_timer();
		timediff = curtime - lasttime;
		window_set_caption("Data event time " + string(timediff));
		
		// poll again for data:
		client.getPadDataReq(
			Ds4UdpRegFlags.IdIsValid |
				(is_undefined(e.address)
					? Ds4UdpRegFlags.None
					: Ds4UdpRegFlags.MacIsValid
				),
			e.padId,
			e.address
		);
		
	}
	
	return undefined; // place a breakpoint here
};

client = new Ds4UdpClient();
client.setOnData(handler);

