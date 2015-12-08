package me.shunia.events
{
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
		 * 当EventInstance生命周期结束后,销毁其和原始对象间的关联.
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
				_delegate = new DelegateDispatcher(handle, _t);
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
				var i:int = -1, 
					h:Function, 
					n:Function = function (index:int):Boolean { 
						h = next(handlers, index); 
						return h != null; 
					};
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
			var fl:int = func.length, al:int = args.length, arr:Array = args.concat();
			if (fl != 0) {
//				// 复制参数数组
//				arr = args.concat();
				
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
			return _listeners.hasOwnProperty(event) ? _listeners[event] : null;
		}
		
		private function addListener(event:String, listener:Function):void {
			var listeners:Array = getListeners(event);
			if (!listeners) {
				listeners = [];
				_listeners[event] = listeners;
			}
			if (listeners.indexOf(listener) == -1) listeners.push(listener);
		}
		
		private function removeListener(event:String, listener:Function = null):void {
			var listeners:Array = getListeners(event);
			if (listener == null && listeners) listeners.splice(0, listeners.length);
			if (listener != null && listeners && listeners.indexOf(listener) != -1) listeners.splice(listeners.indexOf(listener), 1);
		}
		
		public function emit(event:String, ...args):IEvents {
			_delegate.fire(event, args);
			return _ins;
		}
		
		public function off(event:String, listener:Function):IEvents {
			removeListener(event, listener);
			var listeners:Array = getListeners(event);
			if (!listeners || listeners.length == 0) _delegate.remove(event);
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
	private var _checkOrignal:Boolean = false;
	private var _events:Array = null;
	
	public function DelegateDispatcher(handler:Function, dispatcher:* = null) {
		_handler = handler;
		_checkOrignal = dispatcher != null && dispatcher is EventDispatcher;
		_dispatcher = _checkOrignal ? dispatcher as EventDispatcher : new EventDispatcher();
		_events = [];
	}
	
	private function get name():String {
		return "__internal__::" + ID;
	}
	
	public function add(event:String):void {
		if (_events.indexOf(event) == -1) _events.push(event);
		if (_events.length && !_dispatcher.hasEventListener(name)) 
			_dispatcher.addEventListener(name, generalHandler);
		if (_checkOrignal) 
			_dispatcher.addEventListener(event, generalHandler);
	}
	
	public function remove(event:String):void {
		if (_events.indexOf(event) != -1) _events.splice(_events.indexOf(event), 1);
		if (_events.length == 0 && _dispatcher.hasEventListener(name)) 
			_dispatcher.removeEventListener(name, generalHandler);
		if (_checkOrignal && _events.length == 0 && _dispatcher.hasEventListener(event)) 
			_dispatcher.removeEventListener(event, generalHandler);
	}
	
	public function fire(event:String, args:Array):void {
		if (_checkOrignal && // 原始对象就是eventDispatcher
			args.length == 0 && // 参数只有一个
			args[0] is Event && // 是事件对象
			!(args[0] is DelegateEvent) && // 不是_e包内事件类型
			_dispatcher.hasEventListener(event)) // 有该事件的监听
			_dispatcher.dispatchEvent(args[0]); // 原始方式派发
		else if (_events.indexOf(event) != -1) 
			_dispatcher.dispatchEvent(createEvent(event, args));
	}
	
	private function generalHandler(event:Event):void {
		if (event is DelegateEvent) {
			if (event && _events.indexOf((event as DelegateEvent).event) != -1) 
				_handler.apply(event, [(event as DelegateEvent).event, (event as DelegateEvent).args]);
		} else {
			if (event && _events.indexOf(event.type) != -1) 
				_handler.apply(event, [event.type, [event]]);
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
