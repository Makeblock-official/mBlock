### 环境配置

1、 安装cnpm加速

> npm install -g cnpm --registry=https://registry.npm.taobao.org

（electron加速：修改node_modules\electron-download\build\index.js->baseUrl->https://npm.taobao.org/mirrors/electron/ ，或者export ELECTRON_MIRROR=https://npm.taobao.org/mirrors/electron/ ）

2、 安装electron环境和serialport
> ```cnpm install -g node-gyp```

On Unix:
> python (v2.7 recommended, v3.x.x is not supported)
> make
> A proper C/C++ compiler toolchain, like GCC

On Mac OS X:
> python (v2.7 recommended, v3.x.x is not supported) (already installed on Mac OS X)
> Xcode

On Windows( [Windows Vista / 7 only] requires .NET Framework 4.5.1):
> ```cnpm install -g --production windows-build-tools``` 此处安装比较耗时，也可能因为网络原因安装失败，必须确保此步安装成功
> ```cnpm install --save-dev electron-rebuild serialport node-hid bluetooth-serial-port electron-prebuilt```(为确保不受网络影响，可以使用代理服务器，如果有shadowsocks，可以设置```cnpm config set proxy=http://127.0.0.1:1080```)

3、 编辑package.json， **新增scripts**
 
> "scripts": {
>   "rebuild-serialport" :"electron-rebuild -f -w serialport",
>   "rebuild-hid" :"electron-rebuild -f -w node-hid",
>   "rebuild-bluetooth" :"electron-rebuild -f -w bluetooth-serial-port",
>   "start":"electron ."
> }

4、 为electron重新编译serialport,node-hid,bluetooth-serial-port(只需要编译一次)

> ```cnpm run rebuild-serialport```
> ```cnpm run rebuild-hid```
> ```cnpm run rebuild-bluetooth```

On Linux
> ```sudo apt-get install libbluetooth-dev```
> ```npm install```
> ```./node_modules/.bin/electron-rebuild```

5、 运行

> ```cnpm start```

6、 打包(linux)

> ```npm run dist-linux```



### Arduino

在云盘192.168.2.20/常用软件/mblock_tools里面，
- Linux: 把arduino.tar.gz解压成为/tools/arduino
- Mac: 把Arduino.app.zip解压成为/tools/Arduino.app
- Windows: 

### 编写代码注意事项

如需读取未打包的目录中的文件时，获取文件绝对路径，需用__root_path来拼接，不能直接用node的文件路径，如下：
需要在web/tmp目录下写入文件project.sb2，假如运行脚本在app目录下，
正确：var filename = "./tmp/project.sb2";
var filePath = path.resolve(__root_path, './web', filename);
fs.writeFileSync(filePath, data);
错误：
var filename = "./tmp/project.sb2";
var filePath = path.resolve(__dirname, '../web', filename);
fs.writeFileSync(filePath, data);