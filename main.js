const electron = require('electron')
const app = electron.app
const BrowserWindow = electron.BrowserWindow
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
app.commandLine.appendSwitch('ppapi-flash-path', path.join(__dirname, "/plugins/"+pluginName));
app.commandLine.appendSwitch('ppapi-flash-version', '23.0.0.207')

let mainWindow

function createWindow () {
  mainWindow = new BrowserWindow(
  {
  	width: 800, 
  	height: 600,
    'web-preferences': {
            'plugins': true
        }
  })
	
	mainWindow.loadURL(`file://${__dirname}/index.html`)

//  mainWindow.webContents.openDevTools()

  mainWindow.on('closed', function () {
    mainWindow = null
  })
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