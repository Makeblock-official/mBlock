
const electron = require('electron')
const {Menu,MenuItem,app} = require('electron');
var express = require('express');
var http = express();

http.use(express.static('web'));
var httpPort = 7070
http.listen(httpPort, function () {
  console.log('app listening on port '+httpPort+'!');
});

const BrowserWindow = electron.BrowserWindow
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

  initMenu();
}
app.on('ready', createWindow)
app.on('window-all-closed', function () {
  if (process.platform !== 'darwin') {
    app.quit()
  }
})

app.on('activate', function () {
  if (mainWindow === null) {
    createWindow()
  }
})
function initMenu(){
  var menu = require('./menu.js');
  var template = menu.template();
  if (process.platform === 'darwin') {
    template.unshift({
      label: app.getName(),
      submenu: [
        {
          role: 'about',
          label:'About mBlock'
        },
        {
          role: 'quit',
          label:'Quit'
        }
      ]
    })
  }
  var mainMenu = Menu.buildFromTemplate(template);
  Menu.setApplicationMenu(mainMenu)
}