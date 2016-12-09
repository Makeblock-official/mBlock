const {BrowserWindow,app,Menu} = require('electron');
const mBlock = require('./mBlock.js');
var express = require('express');
var http = express();
const httpPort = 7070

http.use(express.static('web'));
http.listen(httpPort, function () {
  console.log('app listening on port '+httpPort+'!');
});

var appName = app.getName();
var path = require('path');
var pluginName;

switch (process.platform) {
  case 'win32':
    pluginName = 'pepflashplayer.dll'
    break
  case 'darwin':
    pluginName = 'PepperFlashPlayer.plugin'
    break
  case 'linux':
    pluginName = 'libpepflashplayer.so'
    break
}
var rootPath = __dirname+"/..";

app.commandLine.appendSwitch('ppapi-flash-path', path.join(rootPath, "/plugins/"+pluginName));
app.commandLine.appendSwitch('ppapi-flash-version', '23.0.0.207')

let mainWindow

function createWindow () {
  mainWindow = new BrowserWindow(
  {
  	width: 1280, 
  	height: 768,
    'web-preferences': {
            'plugins': true
        }
  })
	
	mainWindow.loadURL(`file://${rootPath}/web/index.html`)

  mainWindow.webContents.openDevTools()

  mainWindow.on('closed', function () {
    mainWindow = null
  })
  Menu.setApplicationMenu(new Menu())
}
app.on('ready', createWindow)
app.on('window-all-closed', function () {
    app.quit()
})

app.on('activate', function () {
  if (mainWindow === null) {
    createWindow()
  }
})
