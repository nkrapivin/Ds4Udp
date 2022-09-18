/// @description Insert description here
// You can write your code in this editor

if (serverId == -1) {
	draw_text(64, 64, "no server bound yet...");
	exit;
}

var slot = 0; repeat (array_length(slotdata)) {
	var data = slotdata[@ slot];
	//{
	if (!is_undefined(data)) {
		var str = "";
		var gmslot = 4 + slot; // BAD BAD BAD ASSUMPTION!
	
		str += "UDP Slot " + string(slot) + ": ";
		str += "gmSlotAssume=" + string(gmslot) + ",";
		str += "gmguid=" + gamepad_get_guid(gmslot) + ",";
		str += "velocity={" + string(data.angVelYaw) + ";" + string(data.angVelPitch) + ";" + string(data.angVelRoll) + "},";
		str += "accel={" + string(data.accelXG) + ";" + string(data.accelYG) + ";" + string(data.accelZG) + "},";
	
		draw_text(64, 64 + slot * 64, str);
	}
	//}
	++slot;
}
