package blockly
{
	import blockly.array.prepend;

	/**
	 * func_apply([funcRef, 1, 2], [3, 4]) -> funcRef(3, 4, 1, 2)
	 */
	public function apply(funcData:*, args:Array=null):*
	{
		if (funcData is Function)	return funcData.apply(null, args);
		if (funcData is Array == false)	return funcData;
		return apply(funcData[0], prepend(funcData.slice(1), args));
	}
}