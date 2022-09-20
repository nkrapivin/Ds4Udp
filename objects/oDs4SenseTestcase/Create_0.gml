/// @description DualSense-X testcase

/// @arg {Struct.Ds4UdpSenseEvent} e Incoming server response or an error
/// @desc DSX Server Response handler, only for Version 2??? Or maybe not??? Idk...
handler = function(e) {
	if (e.isSuccess) {
		show_debug_message("DSX OKAY Response: " + json_stringify(e.serverResponse));
	}
	else {
		// will be a GML exception struct!
		// .longMessage, .line, .script, you get the idea
		show_debug_message("DSX ERR Exception: " + json_stringify(e.serverResponse));
		// rethrow the error into the runner
		// throw e.serverResponse;
	}
	
	return undefined; // place a breakpoint here for debugging
};

/// @desc Called on every time source tick
onTick = function() {
	show_debug_message("DSX tick...");
	var controllerIndex = 0;
	client.sendInstructions([ // an array of Ds4UdpSenseInstruction structs
		// TriggerUpdate
		new Ds4UdpSenseInstruction(
			Ds4UdpSenseInstructionType.TriggerUpdate,
			controllerIndex, // Real: controllerIndex
			Ds4UdpSenseTrigger.Left, // Ds4UdpSenseTrigger: which trigger to target
			Ds4UdpSenseTriggerMode.VerySoft // Ds4UdpSenseTriggerMode: which trigger mode to engage
			// Any...: additional trigger data parameters, depends on the mode
			// see the DSX example for more info (commented out code)
		),
		new Ds4UdpSenseInstruction(
			Ds4UdpSenseInstructionType.TriggerUpdate,
			controllerIndex, // Real: controllerIndex
			Ds4UdpSenseTrigger.Right, // Ds4UdpSenseTrigger: which trigger to target
			Ds4UdpSenseTriggerMode.VerySoft // Ds4UdpSenseTriggerMode: which trigger mode to engage
			// Any...: additional trigger data parameters, depends on the mode
			// see the DSX example for more info (commented out code)
		),
		// TriggerThreshold
		new Ds4UdpSenseInstruction(
			Ds4UdpSenseInstructionType.TriggerThreshold,
			controllerIndex, // Real: controllerIndex
			Ds4UdpSenseTrigger.Left, // Ds4UdpSenseTrigger: which trigger to target
			128 // Real: Threshold from 0 to 255
		),
		new Ds4UdpSenseInstruction(
			Ds4UdpSenseInstructionType.TriggerThreshold,
			controllerIndex, // Real: controllerIndex
			Ds4UdpSenseTrigger.Right, // Ds4UdpSenseTrigger: which trigger to target
			128 // Real: Threshold from 0 to 255
		),
		// RGBUpdate
		new Ds4UdpSenseInstruction(
			Ds4UdpSenseInstructionType.RGBUpdate,
			controllerIndex, // Real: controllerIndex
			255, // Real: Red [0;255]
			174, // Real: Green [0;255]
			201  // Real: Blue [0;255]
		),
		// PlayerLED: DEPRECATED LEGACY, VERSIONS 1.X ONLY!!!!!
		new Ds4UdpSenseInstruction(
			Ds4UdpSenseInstructionType.PlayerLED,
			controllerIndex, // Real: controllerIndex
			false, // Bool: Flag 1
			false, // Bool: Flag 2
			false, // Bool: Flag 3
			false, // Bool: Flag 4
			false  // Bool: Flag 5
		),
		// PlayerLEDNewRevision
		new Ds4UdpSenseInstruction(
			Ds4UdpSenseInstructionType.PlayerLEDNewRevision,
			controllerIndex, // Real: controllerIndex
			Ds4UdpSensePlayerLEDNewRevision.Two // Ds4UdpSensePlayerLEDNewRevision: Player LED mode
		),
		// MicLED
		new Ds4UdpSenseInstruction(
			Ds4UdpSenseInstructionType.MicLED,
			controllerIndex, // Real: controllerIndex
			Ds4UdpSenseMicLEDMode.On // Ds4UdpSenseMicLEDMode: Microphone LED mode
		)
	]);
};

client = new Ds4UdpSenseClient();
client.setOnData(handler);

// woah! holy shit! Nik is actually using time sources this time!
// mom get the camera! Nik is not being a retrograd!
ts = time_source_create(time_source_game, 4, time_source_units_seconds, onTick, [], -1);
time_source_start(ts);
