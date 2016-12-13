const webview = document.getElementById('webview');
webview.addEventListener('console-message', (e) => {
    console.log("line "+e.line+" from "+e.sourceId+" : "+e.message)
})