package cc.makeblock.boards
{
	public class BoardDefineFactory
	{
		static public function GetMBot():BoardDefine
		{
			var board:BoardDefine = new BoardDefine();
			board.addPortDefine(1, "Port1", BlockFlag.PORT_YELLOW | BlockFlag.PORT_BLUE | BlockFlag.PORT_WHITE);
			board.addPortDefine(2, "Port2", BlockFlag.PORT_YELLOW | BlockFlag.PORT_BLUE | BlockFlag.PORT_WHITE);
			board.addPortDefine(3, "Port3", BlockFlag.PORT_YELLOW | BlockFlag.PORT_BLUE | BlockFlag.PORT_WHITE | BlockFlag.PORT_BLACK);
			board.addPortDefine(4, "Port4", BlockFlag.PORT_YELLOW | BlockFlag.PORT_BLUE | BlockFlag.PORT_WHITE | BlockFlag.PORT_BLACK);
			board.addPortDefine(9,  "M1", BlockFlag.PORT_RED);
			board.addPortDefine(10, "M2", BlockFlag.PORT_RED);
			return board;
		}
		
		static public function GetOrion():BoardDefine
		{
			var board:BoardDefine = new BoardDefine();
			board.addPortDefine(1, "Port1", BlockFlag.PORT_RED);
			board.addPortDefine(2, "Port2", BlockFlag.PORT_RED);
			board.addPortDefine(3, "Port3", BlockFlag.PORT_YELLOW | BlockFlag.PORT_BLUE | BlockFlag.PORT_WHITE);
			board.addPortDefine(4, "Port4", BlockFlag.PORT_YELLOW | BlockFlag.PORT_BLUE | BlockFlag.PORT_WHITE);
			board.addPortDefine(5, "Port5", BlockFlag.PORT_YELLOW | BlockFlag.PORT_BLUE | BlockFlag.PORT_GRAY);
			board.addPortDefine(6, "Port6", BlockFlag.PORT_YELLOW | BlockFlag.PORT_BLUE | BlockFlag.PORT_WHITE | BlockFlag.PORT_BLACK);
			board.addPortDefine(7, "Port7", BlockFlag.PORT_YELLOW | BlockFlag.PORT_BLACK | BlockFlag.PORT_WHITE);
			board.addPortDefine(8, "Port8", BlockFlag.PORT_YELLOW | BlockFlag.PORT_BLACK | BlockFlag.PORT_WHITE);
			board.addPortDefine(9,  "M1", BlockFlag.PORT_RED);
			board.addPortDefine(10, "M2", BlockFlag.PORT_RED);
			return board;
		}
		
		static public function GetBaseBoard():BoardDefine
		{
			var board:BoardDefine = new BoardDefine();
			board.addPortDefine(1, "Port1", BlockFlag.PORT_RED);
			board.addPortDefine(2, "Port2", BlockFlag.PORT_RED);
			board.addPortDefine(3, "Port3", BlockFlag.PORT_YELLOW | BlockFlag.PORT_BLUE | BlockFlag.PORT_WHITE | BlockFlag.PORT_BLACK);
			board.addPortDefine(4, "Port4", BlockFlag.PORT_YELLOW | BlockFlag.PORT_BLUE | BlockFlag.PORT_WHITE | BlockFlag.PORT_GRAY);
			board.addPortDefine(5, "Port5", BlockFlag.PORT_YELLOW | BlockFlag.PORT_BLUE);
			board.addPortDefine(6, "Port6", BlockFlag.PORT_YELLOW | BlockFlag.PORT_BLUE | BlockFlag.PORT_WHITE | BlockFlag.PORT_BLACK);
			board.addPortDefine(7, "Port7", BlockFlag.PORT_YELLOW | BlockFlag.PORT_BLUE | BlockFlag.PORT_WHITE | BlockFlag.PORT_BLACK);
			board.addPortDefine(8, "Port8", BlockFlag.PORT_YELLOW | BlockFlag.PORT_BLUE | BlockFlag.PORT_WHITE | BlockFlag.PORT_BLACK);
			board.addPortDefine(9,  "M1", BlockFlag.PORT_RED);
			board.addPortDefine(10, "M2", BlockFlag.PORT_RED);
			return board;
		}
		
		static public function GetShield():BoardDefine
		{
			var board:BoardDefine = new BoardDefine();
			board.addPortDefine(1, "Port1", BlockFlag.PORT_RED);
			board.addPortDefine(2, "Port2", BlockFlag.PORT_RED);
			board.addPortDefine(9, "Port9", BlockFlag.PORT_RED);
			board.addPortDefine(10,"Port10",BlockFlag.PORT_RED);
			board.addPortDefine(3, "Port3", BlockFlag.PORT_YELLOW | BlockFlag.PORT_WHITE | BlockFlag.PORT_BLUE);
			board.addPortDefine(4, "Port4", BlockFlag.PORT_YELLOW | BlockFlag.PORT_WHITE);
			board.addPortDefine(5, "Port5", BlockFlag.PORT_GRAY);
			board.addPortDefine(6, "Port6", BlockFlag.PORT_YELLOW | BlockFlag.PORT_WHITE);
			board.addPortDefine(7, "Port7", BlockFlag.PORT_YELLOW | BlockFlag.PORT_BLUE | BlockFlag.PORT_WHITE | BlockFlag.PORT_BLACK);
			board.addPortDefine(8, "Port8", BlockFlag.PORT_YELLOW | BlockFlag.PORT_BLUE | BlockFlag.PORT_WHITE | BlockFlag.PORT_BLACK);
			return board;
		}
	}
}