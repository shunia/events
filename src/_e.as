package
{
	import me.shunia.events.Events;
	import me.shunia.events.IEvents;

	public function _e(target:Object = null):IEvents
	{
		var o:* = target;
		// global listening and dispathing
		if (!o) o = Events.T;
		// get EventInstance from manager
		return Events.g(o);
	}
}