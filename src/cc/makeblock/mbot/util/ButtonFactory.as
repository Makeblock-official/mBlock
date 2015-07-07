package cc.makeblock.mbot.util
{
	import org.aswing.AsWingConstants;
	import org.aswing.JButton;

	public class ButtonFactory
	{
		static public function createBtn(label:String):JButton
		{
			var btn:JButton = new JButton(label);
			btn.setHorizontalAlignment(AsWingConstants.LEFT);
			return btn;
		}
	}
}