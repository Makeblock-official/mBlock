/**
 * 目的：在前端显示一个可以更新内容到提示框
 * 用法：（前端：alertBox.show(内容)）
 * 后端：app.send('alertBox', 'show', msg);
 */
var dom = document.getElementById('alert-box');
const {ipcRenderer} = require('electron');

var closeButtonDom = document.querySelector('#alert-box-close');
var contentTextDom = document.querySelector('#alert-box-content');
var receiveData; // 后台或前台传过来的数据

var AlertBox = {
    init: function() {
        var self = this;
		// 当用户点击了“取消”按钮
        closeButtonDom.addEventListener('click', function() {
            ipcRenderer.send('alertBoxClosed');

			if (typeof(receiveData.cancelCallback) == 'string') { // 取消按钮回调函数
				eval('window["' + receiveData.cancelCallback + '"]()');
			}
            self.close();
        });
        /**
         * 这段的意思是，当收到app.send('alertBox', [functionName], ...)的时候
         * 调用该对象到相应函数
         */
        ipcRenderer.on('alertBox', function(event, arg) {
            var remainingArgs = Array.prototype.slice.call(arguments, 2);
            self[arguments[1]].apply(self, remainingArgs);
        });
        return self;
    },
	/**
	 * 显示弹框
	 * @param {string} | {object} content 需要显示的内容，如果为对象，则: {'message':'提示消息，支持html','hasCancel':'是否有取消按钮，默认true:需要“取消”按钮，false：不要“取消”按钮','cancelCallback':'取消按钮回调函数',...}
	 */
    show: function(content) {
	    var message = '';
		receiveData = content;
		if (typeof(content) == 'object') { // 传对象
		    if (typeof(content.hasCancel) != 'undefined') {
				if (!content.hasCancel) { // 不要取消按钮 
				    closeButtonDom.style.display = 'none';
			    } else {
					closeButtonDom.style.display = 'inline';
				}
			} else {
				closeButtonDom.style.display = 'inline';
			}
			message = content.message
		} else { // 兼容之前的直接传字符串
			message = content;
		}
        this.setContent(message);
        if(!dom.open) {
            dom.showModal();
        }
    },

    close: function() {
        dom.close();
    },

    setContent: function(content) {
        contentTextDom.innerHTML = content;
    },

    setButtonText: function(content) {
        closeButtonDom.innerText = content;
    }
}

module.exports = AlertBox;