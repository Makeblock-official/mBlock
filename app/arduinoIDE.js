const path = require('path');
const fs = require('fs');
const spawn = require('child_process').spawn;
const utils = require('./utils');
const tmpDir = 'tmp';
const MeCommInoFile = 'tools/MeComm.ino';

var app = null;
var T = null;
var ArduinoIDE = {
    init: function(mBlock) {
        app = mBlock;
        T = app.getTranslator().map;
        return this;
    },

    getArduinoExecutable: function() {
        switch (process.platform) {
        case 'win32':
            return 'tools/Arduino.app';
            break
        case 'darwin':
            return 'tools/Arduino.app/Contents/MacOS/Arduino';
            break
        case 'linux':
            return 'tools/arduino/arduino';
        }
        return 'tools/arduino/arduino';
    },

    getValidProjectName: function() {
        var projectName = app.getProject().getProjectTitle();
        var now = new Date();
        projectName = projectName || '';
        projectName = projectName.replace(/[^A-z0-9]|^_/g, '_');

        var fullName = 'project_'+projectName+(now.getMonth()+'_'+now.getDay());
        if(fullName == 'project_'){
            fullName = 'project';
        }
        return fullName;
    },

    prepareProjectSketch: function(code) {
        var projectName = this.getValidProjectName()
        var projectPath = fs.mkdtempSync('tmp/'+projectName);
        projectPath = projectPath + '/' + projectName;
        fs.mkdirSync(projectPath);

        // write code to sketch file
        var sketchFileFullPath = projectPath + '/' + projectName + '.ino';
        fs.writeFileSync(sketchFileFullPath, code);

        // copy MeComm.ino if necessary
        if(code.indexOf('updateVar') > -1) {
            var innoCode = fs.readFileSync(MeCommInoFile, 'utf8');
            fs.writeFileSync(projectPath + '/MeComm.ino', innoCode);
        }

        // TODO: copy src files from extension

        return sketchFileFullPath;
    },

    openArduinoIDE: function(code) {
        var sketchFilePath = this.prepareProjectSketch(code);

        spawn(this.getArduinoExecutable(), [sketchFilePath]);
    },

    uploadCodeToBoard: function(code) {
        var lastLog = "";
        var appendToLastLog = function(msg) {
            lastLog += msg;
            if(lastLog.length > 2000) {
                lastLog = lastLog.substr(lastLog.length - 1000);
            }
        }

        var serialPort = app.getSerial().currentSerialPort();
        if(!serialPort) {
            app.alert('Please connect the serial port.');
            return;
        }
        var sketchFilePath = path.resolve(this.prepareProjectSketch(code));
        var arduinoCommandArguments = [
            '--upload',
            '--board', this.getUploadBoardParameter(),
            '--port', serialPort,
            '--verbose', '--preserve-temp-files',
            sketchFilePath
        ];

        app.alert(T('Uploading'));
        app.getSerial().close();
        var arduinoProcess = spawn(this.getArduinoExecutable(), arduinoCommandArguments);
        arduinoProcess.stdout.on('data', function(data) {
            app.logToArduinoConsole(data.toString());
        });
        arduinoProcess.stderr.on('data', function(data) {
            app.alert(T('Uploading')+'...'+utils.getProgressCharacter());
            app.logToArduinoConsole(data.toString());
        });
        arduinoProcess.on('close', function(code){
            if (code == 0) {
                app.alert(T('Upload Succeeded'));
            }
            else {
                app.alert(T('Upload Failed'));
            }
            app.getSerial().connect(serialPort);
        });
    },

    getUploadBoardParameter: function() {
        var board = app.getBoards().currentBoardName();
        if(board.indexOf("_uno") >= 0){
            return "arduino:avr:uno";
        }else if(board.indexOf("_leonardo") >= 0){
            return "arduino:avr:leonardo";
        }else if(board.indexOf("_mega2560") >= 0){
            return "arduino:avr:mega:cpu=atmega2560";
        }else if(board.indexOf("_mega1280") >= 0){
            return "arduino:avr:mega:cpu=atmega1280";
        }else if(board.indexOf("_nano328") >= 0){
            return "arduino:avr:nano:cpu=atmega328";
        }else if(board.indexOf("_nano168") >= 0){
            return "arduino:avr:nano:cpu=atmega168";
        }
        return "arduino:avr:uno";
    }
}

module.exports = ArduinoIDE;