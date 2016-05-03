package blockly.dict
{
	public function clear(dict:Object):void
	{
		for(var key:* in dict){
			delete dict[key];
		}
	}
}