var progressCharacters = ['\\', '|', '/', '-'];
var progressCharacterIndex = 0;


var utils = {
    getProgressCharacter: function() {
        progressCharacterIndex++;
        if(progressCharacterIndex > 3) progressCharacterIndex = 0;
        return progressCharacters[progressCharacterIndex];
    }
}

module.exports = utils;