package me.shunia.events
{
	public interface IEvents {
		
		/**
		 * 监听
		 *  
		 * @param event 事件的类型/名称,以字符串表示
		 * @param listener 监听的回调函数
		 * @return 
		 */	
		function on(event:String, listener:Function):IEvents;
		/**
		 * 一次监听多个.
		 *  
		 * @param args 参数形式应该为一个个的数组,每个数组里第一位是事件类型,第二位是监听函数
		 * @return 
		 */	
		function onMany(...args):IEvents;
		/**
		 * 取消监听
		 *  
		 * @param event
		 * @param listener
		 * @return 
		 */	
		function off(event:String, listener:Function):IEvents;
		/**
		 * 对多个事件取消监听
		 *  
		 * @param events 参数形式应该为一个个的数组,每个数组里第一位是事件类型,第二位是监听函数
		 * @return 
		 * 
		 */	
		function offMany(...events):IEvents;
		/**
		 * 取消指定事件的所有监听
		 *  
		 * @param event
		 * @return 
		 */	
		function offAll(event:String):IEvents;
		/**
		 * 派发事件,可以指定任意参数用于接收
		 *  
		 * @param event 
		 * @param args
		 * @return 
		 */	
		function emit(event:String, ...args):IEvents;
		/**
		 * 监听一次后销毁
		 *  
		 * @param event
		 * @param args
		 * @return 
		 */	
		function once(event:String, listener:Function):IEvents;
		/**
		 * 销毁所有连接 
		 */	
		function destroy():void;
		
	}
}