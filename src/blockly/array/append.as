package blockly.array
{
	/**  @return list */
	public function append(list:Array, items:Array):Array
	{
		list.push.apply(null, items);
		return list;
	}
}