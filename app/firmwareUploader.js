const spawn = require('child_process').spawn;
var Boards = require('./boards.js');
var app = null;

var progressCharacters = ['\\', '|', '/', '-'];
var progressCharacterIndex = 0;

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

var FirmwareUploader = {
    init: function(mBlock) {
        app = mBlock;
        return this;
    },

    allowResetDefaultProgram: function() {
        return false;
    },

    upgradeFirmware: function() {
        var serialPort = app.getSerial().currentSerialPort();
        var boardName = app.getBoards().currentBoardName();
        console.log('current connection: '+serialPort);
        console.log('current board name: '+boardName);

        if(!boardFirmwareMap[boardName]) {
            this._displayMessage('No firmware available for this type of board');
            return;
        }
        if(!serialPort) {
            this._displayMessage('Please connect the serial port.');
            return;
        }
        return;
        
        var self = this;
        console.log('upgrade firmware');
        this._displayMessage('Uploading...');
        var command = 'tools/arduino/hardware/tools/avr/bin/avrdude';
        var args = [
            '-C', 'tools/arduino/hardware/tools/avr/etc/avrdude.conf', '-v', '-v', '-v', '-v',
            '-patmega328p', '-carduino', '-P'+serialPort, '-b115200', '-D', '-V', '-U', 
            'flash:w:tools/hex/'+boardFirmwareMap[boardName]+':i'
        ];
        var avrdude = spawn(command, args, {stdio: ['pipe', null, null, null, 'pipe']});
        avrdude.stdout.on('data', function(data){
        });
        avrdude.stderr.on('data', function(data){
            self._displayMessage('Uploading...'+self._getProgressCharacter());
        });
        avrdude.on('close', function(code){
            if(code == 0) {
                self._displayMessage('Upload Succeeded');
            }
            else {
                self._displayMessage('Upload Failed');
            }
        });

    },

    _displayMessage: function(msg) {
        app.getClient().send('alertBox', 'show', msg);
    },

    _getProgressCharacter: function() {
        progressCharacterIndex++;
        if(progressCharacterIndex > 3) progressCharacterIndex = 0;
        return progressCharacters[progressCharacterIndex];
    }


}

module.exports = FirmwareUploader;