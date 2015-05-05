package me.shunia.events
{
	import flash.events.Event;
	import flash.utils.Dictionary;
	
	public class Events implements IEvents {
		
		public static const T:Object = {};
		private static var _dict:Dictionary = null;
		
		public static function g(t:*):IEvents {
			if (_dict == null) _dict = new Dictionary();
			if (_dict[t]) return _dict[t];
			else {
				var e:Events = new Events(t, clear);
				_dict[t] = e;
				return e;
			}
		}
		
		/**
		 * 当EventInstance生命周期结束后,销毁该Instance和原始对象间的关联.
		 *  
		 * @param t
		 */	
		private static function clear(t:*):void {
			if (_dict && _dict.hasOwnProperty(t)) delete _dict[t];
		}
		
		private var _t:* = null;
		private var _die:Function = null;
		private var _ins:IEvents = null;
		private var _listeners:Dictionary = null;
		private var _delegate:DelegateDispatcher = null;
		
		public function Events(t:*, die:Function) {
			_t = t;
			_die = die;
			if (_t) {
				_listeners = new Dictionary();
				_delegate = new DelegateDispatcher(_t, handle);
			}
			_ins = this;
		}
		
		/**
		 * 销毁EventInstance. 
		 */	
		public function destroy():void {
			die();
			_t = null;
			for (var k:String in _listeners) {
				offAll(k);
				delete _listeners[k];
			}
			_listeners = null;
			_delegate = null;
		}
		
		/**
		 * 销毁与target的关联. 
		 */	
		private function die():void {
			if (_die != null) _die.apply(this, [_t]);
			_die = null;
		}
		
		private function handle(event:String, args:Array):void {
			var handlers:Array = getListeners(event);
			if (handlers.length > 0) {
				var i:int = -1, h:Function, n:Function = function (index:int):Boolean { h = next(handlers, index); return h != null; };
				while (n(i)) {
					h.apply(_t, functionArguments(h, args));
					i ++;
				}
			}
		}
		
		private function next(array:Array, currentIndex:int = 0):* {
			if (array && array.length > currentIndex + 1) {
				return array[currentIndex + 1];
			}
			return null;
		}
		
		private function functionArguments(func:Function, args:Array):Array {
			var fl:int = func.length, al:int = args.length, arr:Array;
			if (fl != 0) {
				// 复制参数数组
				arr = args.concat();
				
				if (fl > al) {	// 需要的参数比提供的参数多,默认用null补齐
					while (fl > al) {
						arr.push(null);
						al ++;
					}
				} else if (fl < al) {	// 需要的参数比提供的参数少,从参数队尾去掉多余的
					while (fl < al) {
						arr.pop();
						al --;
					}
				}
			}
			return arr;
		}
		
		private function getListeners(event:String):Array {
			if (_listeners.hasOwnProperty(event)) {
				return _listeners[event];
			} else {
				var arr:Array = [];
				_listeners[event] = arr;
				return arr;
			}
		}
		
		private function addListener(event:String, listener:Function):void {
			var listeners:Array = getListeners(event);
			if (listeners.indexOf(listener) == -1) listeners.push(listener);
		}
		
		private function removeListener(event:String, listener:Function = null):void {
			var listeners:Array = getListeners(event);
			if (listener == null) 
				listeners.splice(0, listeners.length);
			if (listener != null && listeners.indexOf(listener) != -1) 
				listeners.splice(listeners.indexOf(listener), 1);
		}
		
		public function emit(event:String, ...args):IEvents {
			_delegate.fire(event, args);
			return _ins;
		}
		
		public function emitEvent(event:Event):IEvents {
			_delegate.fireEvent(event);
			return _ins;
		}
		
		public function off(event:String, listener:Function):IEvents {
			removeListener(event, listener);
			var listeners:Array = getListeners(event);
			if (listeners.length == 0) _delegate.remove(event);
			return _ins;
		}
		
		public function offAll(event:String):IEvents {
			removeListener(event);
			_delegate.remove(event);
			return _ins;
		}
		
		public function on(event:String, listener:Function):IEvents {
			addListener(event, listener);
			_delegate.add(event);
			return _ins;
		}
		
		public function once(event:String, listener:Function):IEvents {
			var func:Function = 
				function (event:String, ...args):void {
					listener.apply(this, []);
					off(event, func);
				};
			on(event, func);
			return _ins;
		}
		
		public function onMany(...args):IEvents {
			batchOp("on", args);
			return _ins;
		}
		
		public function offMany(...events):IEvents {
			batchOp("off", events);
			return _ins;
		}
		
		private function batchOp(action:String, args:Array):void {
			var func:Function = null;
			switch (action) {
				case "on" : 
					func = function (pair:Array):void {
						on(pair[0], pair[1]);
					}
					break;
				case "off" : 
					func = function (pair:Array):void {
						off(pair[0], pair[1]);
					}
					break;
			}
			if (func != null) {
				for each (var item:* in args) {
					func.apply(_ins, [item]);
				}
			}
		}
		
	}
	
}

import flash.events.Event;
import flash.events.EventDispatcher;

class DelegateDispatcher {
	
	private static const ID:String = "dispatcher::" + int(Math.random() * 10000);
	
	private var _handler:Function = null;
	private var _dispatcher:EventDispatcher = null;
	private var _original:Boolean = false;
	private var _events:Array = null;
	
	public function DelegateDispatcher(target:*, handler:Function) {
		_handler = handler;
		// 如果原始对象是eventDispatcher,则用它本身来作为事件派发对象.否则使用一个新的eventDispatcher作为代理派发对象.
		_dispatcher = (target && target is EventDispatcher) ? 
							target as EventDispatcher : new EventDispatcher();
		_original = _dispatcher === target;
		_events = [];
	}
	
	private function get name():String {
		return "__internal__::" + ID;
	}
	
	public function add(event:String):void {
		if (_events.indexOf(event) == -1) 
			_events.push(event);
		if (_events.length && !_dispatcher.hasEventListener(name)) 
			_dispatcher.addEventListener(name, generalHandler);
	}
	
	public function remove(event:String):void {
		if (_events.indexOf(event) != -1) 
			_events.splice(_events.indexOf(event), 1);
		if (_events.length == 0) 
			_dispatcher.removeEventListener(name, generalHandler);
	}
	
	public function fire(event:String, args:Array):void {
		if (_events.indexOf(event) != -1) 
			_dispatcher.dispatchEvent(createEvent(event, args));
	}
	
	public function fireEvent(event:Event):void {
		if (_dispatcher && _dispatcher.hasEventListener(event.type)) 
			_dispatcher.dispatchEvent(event);
	}
	
	private function generalHandler(event:DelegateEvent):void {
		if (event && _events.indexOf(event.event) != -1) {
			_handler.apply(event, [event.event, event.args]);
		}
	}
	
	private function createEvent(event:String, args:Array):DelegateEvent {
		var e:DelegateEvent = new DelegateEvent(name);
		e.event = event;
		e.args = args;
		return e;
	}
	
}

class DelegateEvent extends Event {
	
	public var args:Array = null;
	public var event:String = null;
	
	public function DelegateEvent(type:String) {
		super(type, false, false);
	}
	
}
