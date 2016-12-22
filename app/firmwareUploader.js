const spawn = require('child_process').spawn;
const utils = require('./utils');
var Boards = require('./boards.js');
var app = null;
var T = null;
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
    'me/mbot_uno': 'mbot_reset.hex',
};

var FirmwareUploader = {
    init: function(mBlock) {
        app = mBlock;
        T = app.getTranslator().map;
        return this;
    },

    allowResetDefaultProgram: function() {
        var boardName = app.getBoards().currentBoardName();
        if(boardName == 'me/mbot_uno') {
            return true;
        }
        return false;
    },

    upgradeFirmware: function() {
        var boardName = app.getBoards().currentBoardName();
        this.uploadWithAvrdude(boardFirmwareMap[boardName]);
    },

    resetDefaultProgram: function() {
        var boardName = app.getBoards().currentBoardName();
        this.uploadWithAvrdude(boardDefaultProgramMap[boardName]);
    },

    uploadWithAvrdude: function(hexFileName) {
        var serialPort = app.getSerial().currentSerialPort();
        var boardName = app.getBoards().currentBoardName();
        console.log('current connection: '+serialPort);
        console.log('current board name: '+boardName);

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
        app.alert(T('Uploading...'));
        var command = 'tools/arduino/hardware/tools/avr/bin/avrdude';
        var args = [
            '-C', 'tools/arduino/hardware/tools/avr/etc/avrdude.conf', '-v', '-v', '-v', '-v',
            '-patmega328p', '-carduino', '-P'+serialPort, '-b115200', '-D', '-V', '-U', 
            'flash:w:tools/hex/'+hexFileName+':i'
        ];
        var avrdude = spawn(command, args, {stdio: ['pipe', null, null, null, 'pipe']});
        avrdude.stdout.on('data', function(data){
        });
        avrdude.stderr.on('data', function(data){
            app.logToArduinoConsole(data.toString());
            app.alert(T('Uploading')+'...'+utils.getProgressCharacter());
        });
        avrdude.on('close', function(code){
            if(code == 0) {
                app.alert(T('Upload Succeeded'));
            }
            else {
                app.alert(T('Upload Failed'));
            }
        });

    },

}

module.exports = FirmwareUploader;