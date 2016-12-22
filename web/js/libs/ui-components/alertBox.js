var dom = document.getElementById('alert-box');
const {ipcRenderer} = require('electron');

var closeButtonDom = document.querySelector('#alert-box-close');
var contentTextDom = document.querySelector('#alert-box-content');

var AlertBox = {
    init: function() {
        var self = this;
        closeButtonDom.addEventListener('click', function() {
            ipcRenderer.send('alertBoxClosed');
            self.close();
        });
        ipcRenderer.on('alertBox', function(event, arg) {
            var remainingArgs = Array.prototype.slice.call(arguments, 2);
            self[arguments[1]].apply(self, remainingArgs);
        });
        return self;
    },
    show: function(content) {
        this.setContent(content);
        if(!dom.open) {
            dom.showModal();
        }
    },

    close: function() {
        dom.close();
    },

    setContent: function(content) {
        contentTextDom.innerText = content;
    },

    setButtonText: function(content) {
        closeButtonDom.innerText = content;
    }
}

module.exports = AlertBox;