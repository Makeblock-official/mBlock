package com.arduino.boards
{
	import com.arduino.BoardInfo;
	import com.arduino.BoardType;

	public class BoardInfoFactory
	{
		static public function GetBoardInfo(boardType:String):BoardInfo
		{
			switch(boardType)
			{
				case BoardType.uno:
					return new BoardUno();
				case BoardType.leonardo:
					return new BoardLeonardo();
				case BoardType.mega1280:
					return new BoardMega1280();
				case BoardType.mega2560:
					return new BoardMega2560();
				case BoardType.nano328:
					return new BoardNano328();
				case BoardType.nano168:
					return new BoardNano168();
			}
			return null;
		}
	}
}