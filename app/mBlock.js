const {ipcMain,dialog,BrowserWindow,MenuItem,Menu,app} = require('electron')

const i18n = require('i18n');
var Serial = require("./usbserial.js")
var Boards = require("./boards.js");
var fs = require("fs");
var mBlock = this;
const host = "http://localhost:7070"

var client,saveAs=false,currentProjectPath = "",mainMenu,currentLocale;

i18n.configure({
    locales:['en', 'zh-CN', 'zh-TW'],
    directory: __dirname + '/../locales'
});
ipcMain.on('menu_connected', function (event, arg) {
	console.log("client connected");
  	client = event.sender;
	
})
ipcMain.on('flashReady',function(event,arg){
	Boards.init(client);
  	mBlock.initMenu();
})
ipcMain.on('save',function(event,arg){
	if(saveAs||currentProjectPath==""){
		dialog.showSaveDialog({title:arg.title},function(path){
			if(path){
				currentProjectPath = path;
				fs.writeFileSync(path, new Buffer(arg.data, 'base64'));
			}
		})
	}else{
		fs.writeFileSync(currentProjectPath, new Buffer(arg.data, 'base64'));
	}
});
ipcMain.on('fullscreen',function(event,arg){
	var win = BrowserWindow.getFocusedWindow();
	win.setFullScreen(arg);
})
ipcMain.on('command',function(event,arg){
	if(arg.buffer){
		Serial.send(arg.buffer);
	}
})
function openProject(path){
	currentProjectPath = path
	var data = fs.readFileSync(path);
	var tmp = path.split(".");
	var filename = "/tmp/project."+tmp[tmp.length-1];
	fs.writeFileSync("./web"+filename, data);
	client.send("data",{method:"openProject",url:filename})
}
function newProject(){
	currentProjectPath = ""
	client.send("data",{method:"newProject",title:"new-project"})
}
function saveProject(){
	saveAs = false;
    client.send("data",{method:"saveProject"})
}
function saveProjectAs(){
	saveAs = true;
    client.send("data",{method:"saveProject"})
}
function openURL(url){
	require('electron').shell.openExternal(url)
}
function onSelectBoard(item){
	Boards.selectBoard(item.name);
	generalMenu();
	updateMenu();
}
function updateSerialPort(){
	generalMenu();
	Serial.list(function(err,ports){
		for(var i=0;i<ports.length;i++){
			var item = new MenuItem({
				name:ports[i].comName,
				label:ports[i].comName,
				checked:Serial.isConnected(ports[i].comName),
				type:'checkbox',
				click:function(item,focusedWindow){
					Serial.connect(item.label,updateSerialPort,onSerialReceived,onSerialDisconnect);
				}
			})
			mainMenu.items[process.platform === 'darwin'?3:2].submenu.items[0].submenu.insert(0,item)
		}
		updateMenu();
	})
	if(client){
		client.send("data",{method:"connected",connected:Serial.isConnected()})
	}
}
function setLanguage(lang){
	i18n.setLocale(lang);
	generalMenu();
	updateMenu();
}

function initLanguagesMenu(){
	var languages = [
			{name:"en",label:"English"},
			{name:"zh-CN",label:"简体中文"},
			{name:"zh-TW",label:"繁体中文"}
			];
	for(var i=languages.length-1;i>=0;i--){
		var item = new MenuItem({
			name:languages[i].name,
			label:languages[i].label,
			checked:languages[i].name==i18n.getLocale(),
			type:'checkbox',
			click:function(item,focusedWindow){
				setLanguage(item.name);
			}
		})
		mainMenu.items[process.platform === 'darwin'?6:5].submenu.insert(0,item);
	}
}
function onSerialDisconnect(){
	client.send("data",{method:"connected",connected:false})
}
function onSerialReceived(data){
	client.send("data",{method:"command",buffer:data})
}
function updateMenu(){
  	Menu.setApplicationMenu(mainMenu)
}
function generalMenu(){
	const _menu = [
		{
			name:'File',
			label: i18n.__("File"),
			submenu: [
				{
					name:'New',
					label: i18n.__('New Project'),
					accelerator: 'CmdOrCtrl+N',
					click: function (item, focusedWindow) {
						client.send("data",{method:"newProject",title:"new-project"})
					}
				},
				{
					type: 'separator'
				},
				{
					name:'Load Project',
					label: i18n.__('Load Project'),
					accelerator: 'CmdOrCtrl+O',
					click: function (item, focusedWindow) {
						dialog.showOpenDialog({title:"打开项目",properties: ['openFile'],filters: [{ name: 'Scratch', extensions: ['sb2'] }  ]},function(path){
							if(path&&path.length>0){
								openProject(path[0])
							}
						})
					}
				},
				{
					name:'Save Project',
					label: i18n.__('Save Project'),
					accelerator: 'CmdOrCtrl+S',
					click: function (item, focusedWindow) {
						saveProject();
					}
				},
				{
					name:'Save Project As',
					label: i18n.__('Save Project As'),
					accelerator: 'CmdOrCtrl+Alt+S',
					click: function (item, focusedWindow) {
						saveProjectAs();
					}
				},
				{
					type: 'separator'
				},
				{
					name:'Import Image',
					label: i18n.__('Import Image')
				},
				{
					name:'Export Image',
					label: i18n.__('Export Image')
				},
				{
					type: 'separator'
				},
				{
					name:'Undo Revert',
					label: i18n.__('Undo Revert')
				},
				{
					name:'Revert',
					label: i18n.__('Revert')
				}
			]
		},{
			name:'Edit',
			label: '编辑',
			submenu: [
				{
					name:'Undelete',
					label: '撤销删除',
					click: function (item, focusedWindow) {
						client.send("data",{method:"newProject",title:"new-project"})
					}
				},
				{
					type: 'separator'
				},
				{
					name:'Hide Stage',
					label: '隐藏舞台',
					click: function (item, focusedWindow) {
						client.send("data",{method:"newProject",title:"new-project"})
					}
				},
				{
					name:'Small stage layout',
					label: '小舞台布局模式',
					click: function (item, focusedWindow) {
						client.send("data",{method:"newProject",title:"new-project"})
					}
				},
				{
					name:'Turbo mode',
					label: '加速模式',
					click: function (item, focusedWindow) {
						client.send("data",{method:"newProject",title:"new-project"})
					}
				},
				{
					name:'Arduino mode',
					label: 'Arduino模式',
					click: function (item, focusedWindow) {
						client.send("data",{method:"newProject",title:"new-project"})
					}
				}
			]
		},{
			name:'Connect',
			label: '连接',
			submenu: [
				{
					name:'Serial Port',
					label: '串口',
					submenu: [
						{
							type: 'separator'
						},{
						name:'Refresh',
						label: '刷新串口',
						click:function (item, focusedWindow) {
							updateSerialPort();
						}
					}]
				},
				{
					name:'Bluetooth',
					label: '蓝牙',
					submenu: [
						{
							name:"Discover",
							label:"发现"
						},
						{
							type:"separator"
						},
						{
							name:"Clear Bluetooth",
							label:"清除记录"
						}
					]
				},
				{
					name:'2.4G Serial',
					label: '2.4G无线串口',
					submenu: [
						{
							name:"Connect",
							label:"连接",
							type:"checkbox",
							checked:false
						}
					]
				},
				{
					name:'View Source',
					label: '查看源码'
				},
				{
					name:'Install Arduino Driver',
					label: '安装Arduino驱动'
				}
			]
		},{
			name:'Boards',
			label: '控制板',
			submenu: [
				{
					name:"Arduino",
					label:"Arduino",
					enabled:false
				},
				{
					name:"arduino_uno",
					label:"Arduino Uno",
					type:"checkbox",
					checked:Boards.selected("arduino_uno"),
					click:onSelectBoard
				},
				{
					name:"arduino_leonardo",
					label:"Arduino Leonardo",
					type:"checkbox",
					checked:Boards.selected("arduino_leonardo"),
					click:onSelectBoard
				},
				{
					name:"arduino_nano328",
					label:"Arduino Nano ( mega328 )",
					type:"checkbox",
					checked:Boards.selected("arduino_nano328"),
					click:onSelectBoard
				},
				{
					name:"arduino_mega1280",
					label:"Arduino Mega 1280",
					type:"checkbox",
					checked:Boards.selected("arduino_mega1280"),
					click:onSelectBoard
				},
				{
					name:"arduino_mega2560",
					label:"Arduino Mega 2560",
					type:"checkbox",
					checked:Boards.selected("arduino_mega2560"),
					click:onSelectBoard
				},
				{
					type:"separator"
				},
				{
					name:"Makeblock",
					label:"Makeblock",
					enabled:false
				},
				{
					name:"me/orion_uno",
					label:"Starter/Ultimate (Orion)",
					type:"checkbox",
					checked:Boards.selected("me/orion_uno"),
					click:onSelectBoard
				},
				{
					name:"me/uno_shield_uno",
					label:"Me Uno Shield",
					type:"checkbox",
					checked:Boards.selected("me/uno_shield_uno"),
					click:onSelectBoard
				},
				{
					name:"me/mbot_uno",
					label:"mBot (mCore)",
					type:"checkbox",
					checked:Boards.selected("me/mbot_uno"),
					click:onSelectBoard
				},
				{
					name:"me/auriga_mega2560",
					label:"mBot Ranger (Auriga)",
					type:"checkbox",
					checked:Boards.selected("me/auriga_mega2560"),
					click:onSelectBoard
				},
				{
					name:"me/mega_pi_mega2560",
					label:"Ultimate 2.0 (Mega Pi)",
					type:"checkbox",
					checked:Boards.selected("me/mega_pi_mega2560"),
					click:onSelectBoard
				},
				{
					type:"separator"
				},
				{
					name:"Others",
					label:"Others",
					enabled:false
				},
				{
					name:"picoboard_unknown",
					label:"PicoBoard",
					type:"checkbox",
					checked:Boards.selected("picoboard_unknown"),
					click:onSelectBoard
				}
			]
		},{
			name:'Extensions',
			label: '扩展',
			submenu: [
				{
					name:'Manage Extensions',
					label: '管理扩展',
					click: function (item, focusedWindow) {
						client.send("data",{method:"newProject",title:"new-project"})
					}
				},
				{
					name:'Restore Extensions',
					label: '检查最新扩展',
					click: function (item, focusedWindow) {
						client.send("data",{method:"newProject",title:"new-project"})
					}
				},
				{
					name:'Clear Cache',
					label: '清空缓存',
					click: function (item, focusedWindow) {
						client.send("data",{method:"newProject",title:"new-project"})
					}
				},
				{
					type:"separator"
				},
				{
					name:'Microsoft Cognitive Service Setting',
					label: 'Microsoft Cognitive Service Setting',
					click: function (item, focusedWindow) {
						client.send("data",{method:"newProject",title:"new-project"})
					}
				},
				{
					type:"separator"
				}
			]
		},{
			name:'Language',
			label: '语言',
			submenu: [
				{
					name:'set font size',
					label: '设置字体大小',
					submenu:[
						{
							name:"setFontSize",
							label:"8",
						},
						{
							name:"setFontSize",
							label:"10",
						},
						{
							name:"setFontSize",
							label:"11",
						},
						{
							name:"setFontSize",
							label:"12",
						},
						{
							name:"setFontSize",
							label:"14",
						},
						{
							name:"setFontSize",
							label:"16",
						},
						{
							name:"setFontSize",
							label:"18",
						},
						{
							name:"setFontSize",
							label:"20",
						},
						{
							name:"setFontSize",
							label:"24",
						}
					]
				}
			]
		},{
			name:'Help',
			label: '帮助',
			submenu: [
				{
					name:'Exploring Robotic World',
					label: '探索机器人世界',
					click: function (item, focusedWindow) {
						openURL("http://www.makeblock.com/?utm_source=software&utm_medium=mblock&utm_campaign=mblocktomakeblock");
					}
				},
				{
					type:"separator"
				},
				{
					name:'Getting Started Rapidly',
					label: '快速入门',
					click: function (item, focusedWindow) {
						openURL("http://learn.makeblock.com/getting-started-programming-with-mblock?utm_source=software&utm_medium=mblock&utm_campaign=mblocktorumeng");
					}
				},
				{
					name:'Finding Answers Online',
					label: '在线问答',
					click: function (item, focusedWindow) {
						openURL(currentLocale=="zh-CN"?"http://bbs.makeblock.cc/forum-39-1.html?utm_source=software&utm_medium=mblock&utm_campaign=mblocktobbs":"http://forum.makeblock.cc/c/makeblock-products/mblock?utm_source=software&utm_medium=mblock&utm_campaign=mblocktoforum#scratch");
					}
				},
				{
					name:'Learn More Tutorials',
					label: '浏览更多教程',
					click: function (item, focusedWindow) {
						openURL("http://learn.makeblock.com/?utm_source=software&utm_medium=mblock&utm_campaign=mblocktolearn");
					}
				},
				{
					type:"separator"
				},
				{
					name:'Check For Update',
					label: '检查应用更新',
					click: function (item, focusedWindow) {
					}
				},
				{
					name:'Feedback',
					label: '报告错误',
					click: function (item, focusedWindow) {
					}
				}
			]
		}
	];
	var template = _menu.concat([]);
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
	mainMenu = Menu.buildFromTemplate(template);
	initLanguagesMenu();
}
exports.initMenu = function() {
	Boards.selectBoard("me/auriga_mega2560")
  	currentLocale = app.getLocale();
	i18n.setLocale(currentLocale);
	updateSerialPort();
}
/*
	<subMenu name="Connect" label="连接">
		<subMenu name="Network" label="网络" keyEquivalent="" >
			<item name="Custom Connect" label="自定义连接" action="connect_network" />
		</subMenu>
		<item isSeparator="true" />
		<item name="Upgrade Firmware" label="安装固件" action="upgrade_firmware" />
		<subMenu name="Reset Default Program" label="恢复出厂程序">
			<item name="mBot" label="mbot" />
			<item name="Starter IR" label="Starter IR" />
			<item name="Starter Bluetooth" label="Starter Bluetooth" />
			<item name="mBot Ranger" label="mBot Ranger" />
		</subMenu>
		<subMenu name="Set FirmWare Mode" label="设置固件模式" >
			<item name="bluetooth mode" label="蓝牙模式" />
		</subMenu>
	</subMenu>
	<subMenu name="Boards" label="控制板">
	</subMenu>
	<subMenu name="Extensions" label="扩展">
		
	</subMenu>
	<subMenu name="Language" label="语言">
	</subMenu>
	<subMenu name="Help" label="帮助">
	</subMenu>
</menu>*/
