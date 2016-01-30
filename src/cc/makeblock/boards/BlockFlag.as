package cc.makeblock.boards
{
	public class BlockFlag
	{
		static public const PORT_RED:uint = 1;
		static public const PORT_YELLOW:uint = 1 << 1;
		static public const PORT_BLUE:uint = 1 << 2;
		static public const PORT_GRAY:uint = 1 << 3;
		static public const PORT_BLACK:uint = 1 << 4;
		static public const PORT_WHITE:uint = 1 << 5;
		
		static public const MOTOR_DC_MOTOR:uint = 1 << 6;
		static public const MOTOR_ENCODER_MOTOR:uint = 1 << 7;
		static public const MOTOR_STEPPER_MOTOR:uint = 1 << 8;
		static public const MOTOR_SERVO_MOTOR:uint = 1 << 9;
		
		static public const ADAPTER:uint = PORT_YELLOW | PORT_BLUE | PORT_BLACK;
	}
}