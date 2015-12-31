package cc.makeblock.util
{
	import flash.net.IPVersion;
	import flash.net.InterfaceAddress;
	import flash.net.NetworkInfo;
	import flash.net.NetworkInterface;

	public function getLocalAddress():InterfaceAddress
	{
		var interfaceList:Vector.<NetworkInterface> = NetworkInfo.networkInfo.findInterfaces();
		for each(var netInterface:NetworkInterface in interfaceList){
			if(!(netInterface.active && netInterface.mtu > 0)){
				continue;
			}
			if(netInterface.displayName.indexOf("Adapter") >= 0){
				continue;
			}
			for each(var netAddress:InterfaceAddress in netInterface.addresses){
				if(netAddress.ipVersion == IPVersion.IPV6){
					continue;
				}
				if(Boolean(netAddress.broadcast)){
					return netAddress;
				}
			}
		}
		return null;
	}
}