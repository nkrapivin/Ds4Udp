/// @description Poke.

if (serverId != -1) {
	if (tmpind == -1) {
		pollAllPorts();
	}
	
	if (get_timer() - lastGotTime > emergencyMargin) {
		window_set_caption("LOST CONNECTION TO SERVER! DID NOT RECEIVE ANY EVENTS FOR A LONG TIME");
	}
	else {
		window_set_caption("All is fine");
	}
}
