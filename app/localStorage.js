/**
 * 本地数据存储
 */
const {session} = require("electron")
function LocalStorage(){
    this.getCookie = function(name,callback){
        session.defaultSession.cookies.get({url: 'http://mBlock.local',name:name}, (error, cookies) => {
            if(cookies[0]&&cookies[0].value){
                callback(JSON.parse(cookies[0].value));
            }
        })
    }
    this.setCookie = function(name,data){
        var s = JSON.stringify(data);
        const cookie = {url:'http://mBlock.local',expirationDate:19232424343,name:name,value:s};
        session.defaultSession.cookies.set(cookie, (error) => {
            if (error) console.error(error)
        })
    }
}
module.exports = LocalStorage;