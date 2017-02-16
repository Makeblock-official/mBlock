/**
 * 串口连接进程
 * Created by zhangkun on 2/14/17.
 */
const SerialPort = require("serialport");
var _port;

process.on('message', function(port) {
    // function
    if (!port.port) {
        return;
    }
    console.log('串口：' + port.port);
    if (port.func && 'isOpen()' === port.func) {
        console.log('call serial isOpen()');
        if (_port) {
            process.send({isopen: _port.isOpen()});
        }
        return;
    }
    if (port.func && 'write()' === port.func) {
        console.log('call serial write()');
        console.log(port.data);
        if (_port&&_port.isOpen()) {
            _port.write(new Buffer(port.data), function () {});
        }
        return;
    }
    if (_port)  return;
    _port = new SerialPort(port.port,{ baudRate:115200 });

    // Listen
    _port.on('open',function(){ // 串口连接，进行连接
        console.log('serial is open');
        process.send({ method: 'open', portchannel: _port});
    });
    _port.on('error',function(err){
        if (err.message.indexOf('cannot open') > -1) { // cannot open XXX : 无权限
            process.send({ method: 'error', portchannel:_port});
        } else if (err.message.indexOf('Cannot lock port') > -1) { // Cannot lock port : 端口被锁
            console.log('port is locked:' + port.port);
            process.send({ method: 'locked', portchannel:_port});
        }
        console.log(err);
    });
    _port.on('data',function(data){
        console.log('serial is data ing...');
        process.send({ method: 'data', data: data, portchannel:_port});
    });
    _port.on('close', function() { // 主动点击取消连接
        console.log('serial is close');
        process.send({ method: 'close', portchannel:_port});
    });
    _port.on('disconnect', function(){ // 拔出
        console.log('serial is disconnect');
        process.send({ method: 'disconnect', portchannel:_port});
    });
    console.log('Serial Child: Into');
});