const ipcRenderer = require('electron').ipcRenderer
const webview = document.getElementById('webview');

webview.addEventListener('console-message', (e) => {
    console.log("line "+e.line+" from "+e.sourceId+" : "+e.message)
})
/*webview.addEventListener('ipc-message', (evt) => {
    if(evt.channel=="save"){
        ipcRenderer.send("save",evt.args[0]);
    }else if(evt.channel=="fullscreen"){
        ipcRenderer.send("fullscreen",evt.args[0]);
    }else if(evt.channel=="command"){
        ipcRenderer.send("command",evt.args[0]);
    }else if(evt.channel=="flashReady"){
        ipcRenderer.send("flashReady");
    }
})*/
webview.addEventListener('dom-ready', () => {
    /*ipcRenderer.send('menu_connected', 'index');
    ipcRenderer.on('data', function (event, arg) {
        webview.send('webview',arg);
    })*/
})