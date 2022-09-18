/// @description Poke.

timer = get_timer();

if (serverId != -1) {
	// not polling for any ports rn, can poll for them
	// (then it will poll for data)
	if (tmpind == -1) {
		pollAllPorts();
	}
	
	// check if we had no network events in a long time
	if (timer - lastGotTime > emergencyMargin) {
		window_set_caption("LOST CONNECTION TO SERVER! DID NOT RECEIVE ANY EVENTS FOR A LONG TIME");
		serverId = -1; resetSlots();
		//uncomment this if you also wish to reset the underlying socket:
		//client.reset();
		//this is usually not needed
		// enter a reconnection state...
	}
	else {
		window_set_caption("All is fine");
	}
}
else {
	if (timer - lastConnTime > connectionMargin) {
		lastConnTime = timer;
		client.getVersionReq();
		show_debug_message("Attempting reconnection...");
	}
}
