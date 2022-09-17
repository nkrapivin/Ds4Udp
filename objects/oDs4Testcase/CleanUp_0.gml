/// @description Clean up...

show_debug_message("Disposing DS4Win...");
client = client.dispose();
// dispose() always returns undefined so this will also unset the variable
// nifty!
