var dom = document.getElementById('alert-box');

var closeButtonDom = document.querySelector('#alert-box-close');
var contentTextDom = document.querySelector('#alert-box-content');

var AlertBox = {
    show: function(content) {

        dom.showModal();
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