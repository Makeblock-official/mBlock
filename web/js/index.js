/**
 * Created by lingqing.yang on 2016/12/24.
 */

require('./js/renderer.js');

jQuery = require("./js/external/jquery.js");
(function ($) {
    var percent = 0;
    var loadCheckInterval = setInterval(function () {
        percent += 10;
        var $loader = $('#loadingFlash');
        $loader.find('.progress').css('width', percent + '%');
        if (percent >= 100) {
            //Execute function
            setTimeout(function () {
                $loader.remove();
            }, 200);
            //Clear timer
            clearInterval(loadCheckInterval);
        }
    }, 200);

    var title = document.querySelector('title');
    var isSaved = "未保存";
    var isConnected = " - 没有连接串口 - ";
    title.innerHTML = "mblock"+ isConnected + isSaved;

    const webview = document.getElementById('webview')
    webview.addEventListener('ipc-message', (event) => {
        if (event.channel == 'setSaveStatus'){
            isConnected = event.args.isConnected ? " - 已经连接串口 - ":" - 没有连接串口 - ";
            isSaved = event.args.isSaved ? "已保存":"未保存";
            title.innerHTML = "mblock"+ isConnected + isSaved;
        }
    })

})(jQuery);
