/**
 * web 入口
 * core.js
 *      |----libs/application.js    //IPC通讯、flash通讯
 *      |----libs/extension.js      //Scratch js接口
 *      |----
 */
module.paths.push(__dirname.split('node_modules')[0]+"node_modules/");
module.paths.push(__dirname.split('node_modules')[0]+"web/js/libs/");

const Application = require('application');
const Extension = require('extension');

const flashCore = document.getElementById("mblock");
const _app = new Application(flashCore);
const _ext = new Extension(_app);

