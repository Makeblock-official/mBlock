package blockly.dict
{
	public function hasKey(dict:Object, key:Object):Boolean
	{
		return (dict != null) && (key in dict);
	}
}