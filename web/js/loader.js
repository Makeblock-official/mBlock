function loadScript(name, url, callback){
    removeScript(name);
    console.log("load script")
    var script = document.createElement("script")
    console.log("load script")
    script.id = name;
    script.type = "text/javascript";
    console.log("load script")
    script.onload = function(){
        console.log("load script")
        callback();
    };
    script.src = url;
    document.body.appendChild(script);
}
function removeScript(name){
    if(document.getElementById(name)){
        document.getElementById(name).remove();
    }
}