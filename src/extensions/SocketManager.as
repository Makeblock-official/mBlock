package extensions
{
	import flash.desktop.NativeApplication;
	import flash.events.DatagramSocketDataEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.ServerSocketConnectEvent;
	import flash.net.DatagramSocket;
	import flash.net.InterfaceAddress;
	import flash.net.NetworkInfo;
	import flash.net.NetworkInterface;
	import flash.net.ServerSocket;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	import flash.utils.setTimeout;
	
	import translation.Translator;
	
	import uiwidgets.DialogBox;
	
	import util.ApplicationManager;
	import util.LogManager;
	
	public class SocketManager extends EventDispatcher
	{
		private var datagramSocket:DatagramSocket;
		public var isConnected:Boolean;
		
		private static var _instance:SocketManager;
		
		//The IP and port for this computer 
		private var localIP:String = "0.0.0.0"; 
		private var localPort:int = 55555; 
		
		//The IP and port for the target computer 
		private var broadCastIp:String = "192.168.1.255";
		private var targetIP:String = "192.168.1.1"; 
		private var targetPort:int = 333; 
		
		private var _clientPort:int = 54321;
		private var _server:ServerSocket;
		//wifi module list
		private var _list:Array = [];
		
		private var _sockets:Array = [];
		
		private var _currentIp:String ;
		public static function sharedManager():SocketManager{
			if(_instance==null){
				_instance = new SocketManager;
			}
			return _instance;
		}
		
		public function SocketManager()
		{
			//get lan ip, and construct broadcast ip
			var networkInfo:NetworkInfo = NetworkInfo.networkInfo;
			
			var interfaces:Vector.<NetworkInterface> = networkInfo.findInterfaces();
			var address:InterfaceAddress;
			for each(var n:NetworkInterface in interfaces){
				address = n.addresses[0];
				broadCastIp = address.broadcast as String;
				if(address.address.indexOf("169.254")==-1){
					_currentIp = address.address ;
				}
				if(broadCastIp.indexOf("169.254")==-1&&broadCastIp!=""){
					break;
				}
			}
			//Create the socket 
			datagramSocket = new DatagramSocket(); 
			datagramSocket.addEventListener( DatagramSocketDataEvent.DATA, dataReceived );
			//Bind the socket to the local network interface and port 
			try{
				datagramSocket.bind(_clientPort); 
				//Listen for incoming datagrams 
				datagramSocket.receive();
			}catch(e:*){
				
			}
			
			NativeApplication.nativeApplication.addEventListener(Event.EXITING,onExiting);
			_server = new ServerSocket();
			try{
				_server.bind(_clientPort);
				_server.listen();
			}catch(e:*){
				trace(e);
			}
			_server.addEventListener(ServerSocketConnectEvent.CONNECT,onConnected);
		}
		private function onExiting(evt:Event):void{
			close();
		}
		public function get list():Array{
			this.probe();
			return _list;
		}
		
		private function broadcastIP(message:String):void
		{
			if(broadCastIp){
				var data:ByteArray = new ByteArray();
				data.writeUTFBytes(message);
				var ips:Array = broadCastIp.split(".");
				for(var i:int = 2; i <= 254; i++){
					var tempIp:String = ips[0]+"."+ips[1]+"."+ips[2]+"."+i;
					if(tempIp==_currentIp)continue;
					try{
						datagramSocket.send(data, 0, 0, tempIp, _clientPort);//Send the message(it's IP) to all ip-adresses on the current network.
					}catch(err:Error){
						trace("probe:",err,tempIp,_clientPort);
					}
				}
			}
		}
		public function probe(host:String=null):void{
			//Create a message in a ByteArray
			if(host==null){
				if(ApplicationManager.sharedManager().system==ApplicationManager.WINDOWS){
					var data:ByteArray = new ByteArray();
					data.writeUTFBytes("mBlock");
					//Send the datagram message
					if(broadCastIp!=""){
						try{
							datagramSocket.send( data, 0, 0, broadCastIp, _clientPort);
						}catch(e:Error){
							trace(e);
						}
					}
				}else{
					broadcastIP("mBlock");
				}
			}else{
				if(host=="custom"){
					function connectNow():void{
						connect(dialog.fields["IP Address"].text+":"+dialog.fields["Port"].text);
						dialog.cancel();
					}
					function cancelNow():void{
						dialog.cancel();
					}
					var dialog:DialogBox = new DialogBox;
					dialog.addTitle(Translator.map("Custom Connect"));
					dialog.addField("IP Address",100,broadCastIp.substr(0,broadCastIp.length-3),true);
					dialog.addField("Port",100,_clientPort,true);
					dialog.addButton(Translator.map("Cancel"),cancelNow);
					dialog.addButton(Translator.map("Connect"),connectNow);
					dialog.showOnStage(MBlock.app.stage);
				}else{
					if(!this.connected(host.split(":")[0])){
						this.connect(host.split(":")[0]+":"+host.split(":")[1]);
					}else{
						this.disconnect();
					}
				}
			}
		}
		public function connect(host:String):int{
			if(SerialDevice.sharedDevice().port==host&&isConnected){
				ConnectionManager.sharedManager().onClose();
				close();
			}else{
				if(isConnected){
					close();
				}
				setTimeout(ConnectionManager.sharedManager().onOpen,200,host);
			}
			return 0
		}
		public function open(host:String):Boolean{
			if(host.length>6){
				var temp:Array = host.split(".");
				if(temp.length>3){
					temp = host.split(":");
					if(_sockets.length==0){
						var socket:Socket = new Socket()
						configureListeners(socket);
						socket.connect(temp[0], temp[1]);
						_sockets.push(socket);
					}
					LogManager.sharedManager().log("socket connecting:"+host);
				}
			}
			return true;
		}
		private function disconnect():void{
			for each(var socket:Socket in _sockets){
				if(socket.connected)
					socket.close();
			}
			_sockets = [];
			isConnected = false;
			ConnectionManager.sharedManager().onClose();
			update();
		}
		public function connected(host:String=null):Boolean{
			for each(var socket:Socket in _sockets){
				if(socket){
					if(socket.connected){
						if(socket.remoteAddress==host||host==null){
							return true;
						}
					}
				}
			}
			return false;
		}
		private function onConnected(evt:ServerSocketConnectEvent):void{
			trace("remote connected - "+evt.socket.remoteAddress+":"+evt.socket.remotePort);
			isConnected = true;
			configureListeners(evt.socket);
			_sockets.push(evt.socket);
			ConnectionManager.sharedManager().onOpen(evt.socket.remoteAddress+":"+evt.socket.remotePort);
			update();
		}
		public function update():void{
			if(connected()){
				MBlock.app.topBarPart.setConnectedTitle(Translator.map("Network")+" "+Translator.map("Connected"));
			}
		}
		public function close():int{
			disconnect();
			datagramSocket.close();
			update();
			return 0;
		}
		
		public function sendBytes(bytes:ByteArray):int{
			for each(var socket:Socket in _sockets){
				if(socket){
					if(socket.connected){
						socket.writeBytes(bytes);
						socket.flush();
					}
				}
			}
			return 0
		}
		
		private function configureListeners(socket:Socket):void {
			socket.addEventListener(Event.CLOSE, closeHandler);
			socket.addEventListener(Event.CONNECT, connectHandler);
			socket.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			socket.addEventListener(ProgressEvent.SOCKET_DATA, socketDataHandler);
		}
		
		private function closeHandler(evt:Event):void {
			trace("closeHandler: " + evt);
			dispatchEvent(new Event(Event.CLOSE));
			var index:int = _sockets.indexOf(evt.target);
			if(index>-1){
				_sockets.splice(index,1);
			}
			close();
			update();
		}
		
		private function connectHandler(evt:Event):void {
			trace("connectHandler: " + evt);
			isConnected = true;
			update();
			dispatchEvent(new Event(Event.CONNECT));
		}
		
		private function ioErrorHandler(evt:IOErrorEvent):void {
			trace("ioErrorHandler: " + evt);
			update();
		}
		
		private function securityErrorHandler(event:SecurityErrorEvent):void {
			trace("securityErrorHandler: " + event);
		}
		
		private function socketDataHandler(evt:ProgressEvent):void {
			dispatchEvent(new Event(Event.CHANGE));
			var bytes:ByteArray = new ByteArray();
			var socket:Socket = evt.target as Socket;
			socket.readBytes(bytes);
			ConnectionManager.sharedManager().onReceived(bytes);
//			ParseManager.sharedManager().parseBuffer(bytes);
			trace("socketDataHandler: " + evt);
		}
		
		private function dataReceived( evt:DatagramSocketDataEvent ):void 
		{
			var srcName:String = evt.data.readUTFBytes( evt.data.bytesAvailable );
			//Read the data from the datagram
			if(evt.srcAddress!=_currentIp){
				//				trace("Received from " + evt.srcAddress + ":" + evt.srcPort + "> " + srcName );
				var wifiModule:String = evt.srcAddress+":"+evt.srcPort+":"+srcName;
				if(_list.toString().indexOf(evt.srcAddress)==-1)
				{
					if(srcName.length>1){
						//ConnectionManager.sharedManager().onOpen(evt.srcAddress+":"+evt.srcPort);
						_list.push(wifiModule);
						var data:ByteArray = new ByteArray();
						data.writeUTFBytes(MBlock.app.projectName());
						//Send the datagram message
						datagramSocket.send( data, 0, data.length, evt.srcAddress, evt.srcPort);
					}
				}
			}
		}
	}
}