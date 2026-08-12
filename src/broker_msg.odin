package main

MessageType :: enum {
	EmptyMsg,
	LoadMsg,
	PlayMsg,
	PlayForwardMsg,
	PlayPrevMsg,
	StopMsg,
	PauseMsg,
	PlaylistClear,
	SeekMsg,
}

MessageData :: union {
	EmptyMsgData,
	LoadMsgData,
	SoundMsgData,
	SeekMsgData,
}

EmptyMsgData :: struct {}

LoadMsgData :: struct {
	path : string,
}

SoundMsgData :: struct {
	handle : Handle,
}

SeekMsgData :: struct {
	handle  : Handle,
	seconds : f64,
}

Message :: struct {
	type : MessageType,
	data : MessageData,
}
