### 导出翻译脚本

> 将老版本翻译文件(src/locale/locale.xlsx)导出成4.0翻译文件(i18n/locales/*.json)

- 安装依赖库

```
MAC 及 Linux:
sudo pip install xlrd
```

- 运行

```
cd i18n
python excelToJson.py
```