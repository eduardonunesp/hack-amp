package main

import rt "base:runtime"
import "core:container/queue"

BrokerListenerKey :: string

BrokerError :: enum byte {
	None         = 0,
	FailedToPush = 1,
}

OnMessageFunc :: #type proc(data : MessageData)

Listener :: struct {
	listener   : BrokerListenerKey,
	on_message : OnMessageFunc,
}

Broker :: struct {
	listeners : map[MessageType][dynamic]Listener,
	messages  : queue.Queue(Message),
}

g_broker : Broker

broker_init :: proc() {
	g_broker.listeners = make(map[MessageType][dynamic]Listener)
}

broker_register :: proc(
	type : MessageType,
	listener : BrokerListenerKey,
	listener_func : OnMessageFunc,
) {
	l := g_broker.listeners[type]
	append(&l, Listener{listener, listener_func})
	g_broker.listeners[type] = l
}

// Reverse iteration: unordered_remove swaps the last element into the freed slot.
broker_unregister :: proc(listener : BrokerListenerKey) {
	for message_type in g_broker.listeners {
		l := g_broker.listeners[message_type]
		for i := len(l) - 1; i >= 0; i -= 1 {
			if l[i].listener == listener {
				unordered_remove(&l, i)
			}
		}
		g_broker.listeners[message_type] = l
	}
}

broker_process_messages :: proc() {
	for queue.len(g_broker.messages) > 0 {
		message := queue.pop_front(&g_broker.messages)
		message_listeners, ok := g_broker.listeners[message.type]
		if !ok { continue }
		for l in message_listeners {
			l.on_message(message.data)
		}
	}
}

broker_post :: proc(
	type : MessageType,
	data : MessageData = EmptyMsgData{},
) -> BrokerError {
	_, err := queue.push_back(&g_broker.messages, Message{type, data})
	if err != rt.Allocator_Error.None {
		return BrokerError.FailedToPush
	}
	return BrokerError.None
}

broker_destroy :: proc() {
	for message_type in g_broker.listeners {
		delete(g_broker.listeners[message_type])
	}
	delete(g_broker.listeners)
	queue.destroy(&g_broker.messages)
}
