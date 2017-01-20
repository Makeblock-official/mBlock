
// 蓝牙子进程，用于发现蓝牙和连接蓝牙

const SPP = require('bluetooth-serial-port');
var number = 0; // 已找到有通道的蓝牙多少个
//var arguments; // 主进程传过来的参数
var bluetoothDevicesFoundNumber = 0;	// 已找到多少个蓝牙设备
var bluetoothDevicesChannelProcessedNumber = 0;			// bluetoothDevicesChannelProcessed 已获取多少个蓝牙设备的频道

_btSerial = new SPP.BluetoothSerialPort();
_btSerial.on('found', function(address, name) { // 已找到蓝牙设备
	// name : 蓝牙名称； address ： 蓝牙物理地址
	console.log('已找到蓝牙:'+name+"("+address+")");
	bluetoothDevicesFoundNumber++;

	_btSerial.findSerialPortChannel(address, function(channel) { // 找到多少个蓝牙，就是循环多少次
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
_btSerial.on('finished', function () { // 已经找完，接下来会调用findSerialPortChannel  
	if (bluetoothDevicesFoundNumber == 0) { // 周围未找到任何蓝牙设备
        process.send({'method':'noBluetoothDevices', 'isAlertMessage':true});
	}
})
_btSerial.on('data', function(data) { // 接受数据
	process.send({'method':'receivedData', 'data': data});
});
_btSerial.on('closed', function() { // 当蓝牙主动断开时或蓝牙已拔出时，会调用此方法
    console.log('子进程的蓝牙串口已断开连接');
	
});
_btSerial.on('error',function(err){
	console.log('蓝牙设备发生错误了：');
	console.log(err);
})

	
process.on('message', function (message) {
    console.log(`from master message:`);
	console.log(message);
	if (message.method == 'inquire') {
        console.log('开始发现蓝牙...');
		number = 0;
		_btSerial.inquire(); // 异步发现蓝牙
	} else if (message.method == 'connect') { // 连接蓝牙
	    _btSerial.connect(message.device.address, message.device.channel, function() {
            process.send({'method':'onConnected', 'address':message.device.address, 'isConnected':true});
        }, function (error) {
            console.log('bluetooth child process open connect is error:');
			console.log(error);
			process.send({'method':'onConnected', 'isConnected':false});
        });	
	} else if (message.method == 'writeData') {
	    _btSerial.write(new Buffer(message.data), function(err, bytesWritten) {
            if (err) console.log(err);
        });	
	}
	
});

process.on('SIGTERM', function () {
	console.log('child process is exit!!!!');
	//process.exit(0);
});


/*arguments = process.argv.slice(2);
console.log('created child process and send arguments:');
console.log(arguments);*/

/*_btSerial.on('found', function(address, name) {
		console.log('已找到蓝牙:'+name+"("+address+")");
		_btSerial.findSerialPortChannel(address, function(channel) {
			if (address != '00:0D:19:02:07:94') { // 8C:C8:F4:10:2B:64
				return;
			}console.log(address);
			_btSerial.connect(address, channel, function() {
				console.log('connecte(已连接成功)，且已更新菜单');
	 
				_btSerial.write(new Buffer('my data', 'utf-8'), function(err, bytesWritten) {
					if (err) console.log(err);
				});
	 
				_btSerial.on('data', function(buffer) {
					console.log(buffer.toString('utf-8'));
				});
				
			}, function (error) {
				console.log('cannot connect:');
				console.log(error);
				console.log('连接失败，且已更新菜单');
			});
	 
			// close the connection when you're ready 

			setTimeout(function () {
				console.log('ready close ');
				_btSerial.close();console.log('is closed');
			}, 5000);
			
			
		}, function() {
			
			console.log('can\'t found channel');
		});
	});
	
	_btSerial.on('closed', function() { // 当蓝牙主动断开时或蓝牙已拔出时，会调用此方法
        console.log('已经关闭！！！');
	});*/