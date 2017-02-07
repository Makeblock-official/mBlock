/**
 * 蓝牙子进程，用于发现蓝牙和连接蓝牙
 * @author Bear
 */
const bluetoothSerialPort = new (require('bluetooth-serial-port')).BluetoothSerialPort();
var number = 0; // 已找到有通道的蓝牙多少个
//var arguments; // 主进程传过来的参数
var bluetoothDevicesFoundNumber = 0;	// 已找到多少个蓝牙设备
var bluetoothDevicesChannelProcessedNumber = 0;			// bluetoothDevicesChannelProcessed 已获取多少个蓝牙设备的频道

bluetoothSerialPort.on('found', function(address, name) { // 已找到蓝牙设备
	// name : 蓝牙名称； address ： 蓝牙物理地址
	console.log('已找到蓝牙:'+name+"("+address+")");
	bluetoothDevicesFoundNumber++;

	bluetoothSerialPort.findSerialPortChannel(address, function(channel) { // 找到多少个蓝牙，就是循环多少次
		name = name + "(" + address + ")";
		// 找到一个通知主进程
		var device = {
			'label'   : name,
			'address' : address,
			'channel' : channel
		};
        process.send({'method':'foundBluetooth', 'device':device});
		bluetoothDevicesChannelProcessedNumber++;
		if (bluetoothDevicesChannelProcessedNumber == bluetoothDevicesFoundNumber) {
			bluetoothDevicesFoundNumber = 0;
			bluetoothDevicesChannelProcessedNumber = 0;
			process.send({'method':'finishedBluetooth'});
		}
		number = number+1;
	}, function() {
		bluetoothDevicesChannelProcessedNumber++;
		if (bluetoothDevicesChannelProcessedNumber == bluetoothDevicesFoundNumber) {
			bluetoothDevicesFoundNumber = 0;
			bluetoothDevicesChannelProcessedNumber = 0;
			var isAlertMessage = false;
			if (number == 0) {
				isAlertMessage = true; // 需弹框提示用户
			}
			process.send({'method':'noBluetoothDevices', 'isAlertMessage':isAlertMessage});
		}
		console.log('can\'t found channel');
	});
});
bluetoothSerialPort.on('finished', function () { // 已经找完，接下来会调用findSerialPortChannel  
	if (bluetoothDevicesFoundNumber == 0) { // 周围未找到任何蓝牙设备
        process.send({'method':'noBluetoothDevices', 'isAlertMessage':true});
	}
})
bluetoothSerialPort.on('data', function(data) { // 接受数据
	process.send({'method':'receivedData', 'data': data});
});
bluetoothSerialPort.on('closed', function() { // 当蓝牙主动断开时或蓝牙已拔出时，会调用此方法
    console.log('子进程的蓝牙串口已断开连接');
	process.send({'method':'onConnected', 'isConnected':false});
});
bluetoothSerialPort.on('error',function(err){
})


process.on('message', function (message) { // 主进程传过来的消息
	if (message.method == 'inquire') {
		number = 0;
		bluetoothSerialPort.inquire(); // 异步发现蓝牙
	} else if (message.method == 'connect') { // 连接蓝牙
	    bluetoothSerialPort.connect(message.device.address, message.device.channel, function() {
            process.send({'method':'onConnected', 'address':message.device.address, 'isConnected':true});
        }, function (error) {
            console.log('bluetooth child process open connect is error:');
			console.log(error);
			process.send({'method':'onConnected', 'isConnected':false});
        });	
	} else if (message.method == 'writeData') {
	    bluetoothSerialPort.write(new Buffer(message.data), function(err, bytesWritten) {
            if (err) {
				console.log('蓝牙写数据出错了：');
				console.log(err);
			}
        });	
	}
	
});

process.on('SIGTERM', function () {
});

/*arguments = process.argv.slice(2);
console.log('created child process and send arguments:');
console.log(arguments);*/