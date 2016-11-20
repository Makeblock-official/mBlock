### 环境配置

1. npm install -g cnpm --registry=https://registry.npm.taobao.org
2. cnpm install --save-dev electron-rebuild serialport electron-prebuilt
3. 编辑package.json
 **新增scripts** 
> "scripts": {
>   "rebuild" :"electron-rebuild -f -w serialport",
>   "start":"electron ."
> }

4. 为electron重新编译serialport
> cnpm run rebuild
5. 运行。
> cnpm start