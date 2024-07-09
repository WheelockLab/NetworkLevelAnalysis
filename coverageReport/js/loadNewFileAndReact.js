/* eslint-env browser */
/*  Copyright 2018 The MathWorks, Inc.*/
function loadNewFileAndReact(sourceFile,callback, messageCatalog,fullFilename,rowNode, currentFullfilename,testHook) {
    
    // set up testHook to a no-op if its not provided
    testHook = testHook || function(){};
    
    if (typeof rowNode !== "undefined"){
        var tableBodyNode = rowNode.parentElement; 
        resetAllTableRows(tableBodyNode);
        rowNode.classList.add("selectedRow")
    }
    if (currentFullfilename !== fullFilename){
        document.getElementById("sourceFileNameSpan").innerHTML = " - " + fullFilename;
        var fileparts = sourceFile.split("/");
        if (!isScriptLoaded(fileparts[1])){
            var script = document.createElement('script');
            script.setAttribute("type","text/javascript");
            script.setAttribute("src", sourceFile + ".js"); 
            script.setAttribute("id", "loaded_"+fileparts[1]);
            script.onload = function() { 
                callback(eval(fileparts[1]),messageCatalog);
                testHook();
            };
            document.body.appendChild(script); 
        }
        else{
            callback(eval(fileparts[1]),messageCatalog);
        } 
    }
 }

function isScriptLoaded(id){
    var scriptNodes,idx, result;    
    scriptNodes = document.body.getElementsByTagName("script");
    result = false;
    for (idx=0;idx<scriptNodes.length;idx++){
        if (scriptNodes[idx].getAttribute("id") == "loaded_"+id){
            result = true;
            break;
        }
    }
    return result;
}
function resetAllTableRows(tBodyEl){
    var allRows = tBodyEl.getElementsByTagName("tr");
    
    for (var idx = 0; idx<allRows.length; idx++) {
        allRows[idx].classList.remove("selectedRow");
        
    } 
    
}