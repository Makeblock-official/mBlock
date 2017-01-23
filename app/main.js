/**
 * Electron 程序入口：创建窗口、加载flashplayer插件、创建Express服务
 */
const path = require('path');
module.paths.push(path.resolve('node_modules'));
module.paths.push(path.resolve('../node_modules'));
module.paths.push(path.resolve('__dirname', '..', '..', '..', '..', 'resources', 'app', 'node_modules'));
module.paths.push(path.resolve('__dirname', '..', '..', '..', '..', 'resources', 'app.asar', 'node_modules'));
module.paths.push(path.resolve('node_modules'));

const {BrowserWindow,app,Menu} = require('electron');
const mBlock = require('./mBlock.js');
const express = require('express');
const httpPort = 7070
var http = express();
var mBlockObject;

// rootPath和__root_path是能找到外部工具（如tools/）到地方。
var rootPath = path.join(__dirname, "/..");
global.__is_packaged = false;
if(rootPath.indexOf('asar') > -1) {
  rootPath = path.join(__dirname, "/../..");
  global.__is_packaged = true;
}
global.__root_path = rootPath;
global.__webviewRootURL = 'http://localhost:7070';
        
console.log(path.join(rootPath,'/tools/arduino'));
//设置express静态资源目录
http.use(express.static(rootPath+'/web'));

http.listen(httpPort, function () {
  console.log('app listening on port '+httpPort+'!');
});

var appName = app.getName();
var pluginName;

//根据系统加载对应版本的flash player插件
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

app.commandLine.appendSwitch('ppapi-flash-path', path.join(rootPath, "/plugins/"+pluginName));
app.commandLine.appendSwitch('ppapi-flash-version', '23.0.0.207')

let mainWindow

//创建主窗口
function createWindow () {
  mainWindow = new BrowserWindow(
  {
  	width: 1280, 
  	height: 768,
    backgroundColor: '#666',
    'web-preferences': {
            'plugins': true
        }
  })
	mainWindow.loadURL(`file://${rootPath}/web/index.html`);

  if (!__is_packaged) {
    mainWindow.webContents.openDevTools()
  }

  mainWindow.on('closed', function () {
    mainWindow = null
  })
  Menu.setApplicationMenu(new Menu());
  mBlockObject = new mBlock();
}
app.on('ready', createWindow);
app.on('window-all-closed', function () {
    mBlockObject.quit();
    app.quit();
	process.kill(process.pid, 'SIGKILL');
})

app.on('activate', function () {
  if (mainWindow === null) {
    createWindow()
  }
})
