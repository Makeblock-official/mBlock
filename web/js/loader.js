function loadScript(name, url, callback){
    removeScript(name);
    var script = document.createElement("script")
    script.id = name;
    script.type = "text/javascript";
    script.onload = function(){
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