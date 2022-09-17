/// @description Poke.

if (keyboard_check_pressed(ord("1"))) {
	// actually start the thing:
	client.getVersionReq();
	client.getListPorts(); // poll every controller (up to 4)
	show_debug_message("Sent! Waiting for async events...");
}
