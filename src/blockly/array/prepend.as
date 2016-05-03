package blockly.array
{
	/**  @return list */
	public function prepend(list:Array, items:Array):Array
	{
		list.unshift.apply(null, items);
		return list;
	}
}