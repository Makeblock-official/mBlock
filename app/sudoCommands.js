var sudo = require('sudo-prompt');

var SudoCommands = {
    enableSerialInLinux: function(callback) {
        this.spawn('usermod -a -G dialout `whoami`', [], callback);
    },
    spawn: function(command, args, callback) {
        var options = {
            name: 'mBlock'
        }
        sudo.exec(command, options, function(error, stdout, stderr){
            callback(error, stderr, stdout);
        });
    }
}

module.exports = SudoCommands;