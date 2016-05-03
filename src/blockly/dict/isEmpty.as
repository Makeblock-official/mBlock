package blockly.dict
{
	public function isEmpty(dict:Object):Boolean
	{
		for(var key:* in dict){
			return false;
		}
		return true;
	}
}