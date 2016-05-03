package blockly.signals
{
	public interface ISignal
	{
		function add(handler:Function, once:Boolean=false):void;
		function del(handler:Function):void;
		function has(handler:Function):Boolean;
	}
}