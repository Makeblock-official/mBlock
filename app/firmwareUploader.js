/**
 * 安装固件
 */
const spawn = require('child_process').spawn;
const path = require('path');
const utils = require('./utils');
var Boards = require('./boards.js');
var app = null;
var T = null;
var checkUSB, errorStatus;
const boardFirmwareMap = {
    'arduino_uno': 'uno.hex',
    'arduino_leonardo': 'leonardo.hex',
    'arduino_nano328': 'nano328.hex',
    'arduino_mega1280': 'mega1280.hex',
    'arduino_mega2560': 'mega2560.hex',
    'me/uno_shield_uno': 'shield.hex',
    'me/orion_uno': 'uno.hex',
    'me/auriga_mega2560': 'auriga.hex',
    'me/mbot_uno': 'mbot.hex',
    'me/mega_pi_mega2560': 'mega_pi.hex'
};

const boardDefaultProgramMap = {
    'me/mbot_uno'  : 'mbot_reset.hex',
	'me/orion_uno' : 'starter_factory_firmware.hex'
};

var FirmwareUploader = {
    init: function(mBlock) {
        app = mBlock;
        T = app.getTranslator().map;
        return this;
    },

    getAvrdudeParameter: function(serialPort, hexFileName) {
        const boardName =  app.getBoards().currentBoardName();
        const self = this;
        var commonParam = ['-C', self.getArduinoPath() + '/hardware/tools/avr/etc/avrdude.conf', '-v', '-v', '-v', '-v'];
        switch(boardName) {
            case 'arduino_uno':
            case 'me/uno_shield_uno':
            case 'me/orion_uno':
            case 'me/mbot_uno':
                return commonParam.concat([
                    '-patmega328p', '-carduino', '-P'+serialPort, '-b115200', '-D', '-V', '-U', 
                    'flash:w:tools/hex/'+hexFileName+':i'
                ]);
            case 'arduino_nano328':
                return commonParam.concat([
                    '-patmega328p', '-carduino', '-P'+serialPort, '-b57600', '-D', '-U', 
                    'flash:w:tools/hex/'+hexFileName+':i'
                ]);
            case 'arduino_leonardo':
                return commonParam.concat([
                    '-patmega32u4', '-cavr109', '-P'+serialPort, '-b57600', '-D', '-U', 
                    'flash:w:tools/hex/'+hexFileName+':i'
                ]);
            case 'arduino_mega1280':
                return commonParam.concat([
                    '-patmega1280', '-cwiring', '-P'+serialPort, '-b57600', '-D', '-U', 
                    'flash:w:tools/hex/'+hexFileName+':i'
                ]);
            case 'arduino_mega2560':
            case 'me/auriga_mega2560':
            case 'me/mega_pi_mega2560':
                return commonParam.concat([
                    '-patmega2560', '-cwiring', '-P'+serialPort, '-b115200', '-D', '-U', 
                    'flash:w:tools/hex/'+hexFileName+':i'
                ]);
        }
    },

    getArduinoPath: function() {
        switch (process.platform) {
        case 'win32':
            pluginName = 'pepflashplayer.dll'
            break
        case 'darwin':
            return 'tools/Arduino.app/Contents/Java';
            break
        case 'linux':
            return path.join(__root_path, 'tools/arduino');
        }
        return path.join(__root_path, 'tools/arduino');
    },

    allowResetDefaultProgram: function() {
        var boardName = app.getBoards().currentBoardName();
        if(boardName == 'me/mbot_uno' || boardName == 'me/orion_uno') {
            return true;
        }
        return false;
    },

    upgradeFirmware: function() {
        var boardName = app.getBoards().currentBoardName();
        this.uploadWithAvrdude(boardFirmwareMap[boardName]);
    },

    resetDefaultProgram: function() {
        var boardName = app.getBoards().currentBoardName();console.log('版：');console.log(boardName);
        this.uploadWithAvrdude(boardDefaultProgramMap[boardName]);
    },

    /**
     * 通过小内存机多次测试刷新固件经验得出超时时间，range最多2分钟，mbot最多20秒
     * @param on
     * @param callback
     */
    uploadingWatchDog: function (on, callback) {
        if (!on) return;
        // mbot : me/mbot_uno , ranger : me/auriga_mega2560
        var boardName = app.getBoards().currentBoardName();
        var timeout = ('me/mbot_uno' === boardName) ? 20000 : 120000;
        checkUSB = setInterval(function() {
            callback();
        }, timeout);
    },

    uploadWithAvrdude: function(hexFileName) {
        var serialPort = app.getSerial().currentSerialPort();
        var boardName = app.getBoards().currentBoardName();

        if(!hexFileName) {
            app.alert(T('No firmware available for this type of board'));
            return;
        }
        if(!serialPort) {
            app.alert(T('Please connect the serial port.'));
            return;
        }
        
        var self = this;
        console.log('upgrade firmware');
        app.alert({'message':T('Uploading') + '...', 'hasCancel':false});
        var command = self.getArduinoPath() + '/hardware/tools/avr/bin/avrdude';
        var args = self.getAvrdudeParameter(serialPort, hexFileName); 
        app.getSerial().close();
        var uploading = false, uploaderSuccess = false;
        var avrdude = spawn(command, args, {cwd: __root_path});
        avrdude.stdout.on('data', function(data){
        });
        avrdude.stderr.on('data', function(data){
            app.logToArduinoConsole(data.toString());
            if(data.toString().indexOf('programmer is not responding')>=0){
                avrdude.kill('SIGKILL');
            }
            app.alert({'message':T('Uploading')+'...'+utils.getProgressCharacter(), 'hasCancel':false});
            // 第一次进入上传状态，看门狗启动，超时未完成上传即kill进程
            self.uploadingWatchDog(!uploading, function () {
                avrdude.kill('SIGKILL');
                errorStatus = 'TIMEOUT';
                app.alert({'message':T('Hardware communication timeout, please confirm whether the serial connection'), 'hasCancel':true});
                clearInterval(checkUSB);
            });

            uploading = true;
        });
        avrdude.on('close', function(code){
            clearInterval(checkUSB);
            if ('TIMEOUT' === errorStatus) {
                errorStatus = '';
                return;
            }
            if(code == 0) {
				app.alert({'message':T('Upload Finish'), 'hasCancel':true});
            } else {
                app.alert({'message':T('Upload Failed'), 'hasCancel':true});
            }
            avrdude.kill('SIGKILL');
            app.getSerial().connect(serialPort);
        });
        avrdude.on('exit', function (code) {
        });
    },

}

module.exports = FirmwareUploader;