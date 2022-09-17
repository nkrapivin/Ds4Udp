/// @desc A DS4WinUDPClient exception class which mimics the built-in GameMaker exception struct.
/// @arg {Any} errMsg error message variable, will be stringified if not a string
function Ds4UdpException(errMsg) constructor {
	message = string(errMsg);
	longMessage = "An exception in DS4WinUDPClient had occurred:\n" + message + "\nInspect the stacktrace";
	// will contain script's own entry (gml_Script_Ds4UdpException:7)
	stacktrace = debug_get_callstack();
	// for compatibility reasons, I'm too lazy to implement that
	line = -1;
	script = "<unknown>";
	
	// will be thrown
}