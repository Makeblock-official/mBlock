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
> ```cnpm install --save-dev electron-rebuild serialport electron-prebuilt```

3、 编辑package.json， **新增scripts**
 
> "scripts": {
>   "rebuild" :"electron-rebuild -f -w serialport",
>   "start":"electron ."
> }

4、 为electron重新编译serialport(只需要编译一次)

> ```cnpm run rebuild```

5、 运行

> ```cnpm start```