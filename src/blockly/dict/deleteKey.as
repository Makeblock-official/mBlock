package blockly.dict
{
	public function deleteKey(dict:Object, key:Object):*
	{
		var val:Object = dict[key];
		delete dict[key];
		return val;
	}
}