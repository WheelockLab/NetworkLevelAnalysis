/* eslint-env browser */
/*  Copyright 2018 The MathWorks, Inc.*/
function displayCodeMarkup(sourceFileObj,messageCatalog){
    var i;
    
    //clear the table body before displaying the new contents
    var sourceDispTableEl = document.getElementById("SourceCodeDispTable");
    var sourceDispTableBodyEl = document.getElementById("SourceCodeDispTableBody");
    sourceDispTableEl.removeChild(sourceDispTableBodyEl);    
    sourceDispTableBodyEl = document.createElement("tbody");
    sourceDispTableBodyEl.setAttribute("id","SourceCodeDispTableBody");
    sourceDispTableEl.appendChild(sourceDispTableBodyEl);
    
    var coveredLines = sourceFileObj.CoverageData.CoveredLineNumbers;
    var missedLines =  sourceFileObj.CoverageData.UnhitLineNumbers;
    var hitCountArray =  convertToArray(sourceFileObj.CoverageData.HitCount);
    var sourceContentLines = convertToArray(sourceFileObj.FileContents); 

    for (i = 0; i < (sourceContentLines.length); i++) {
        var newRowEl = document.createElement("tr");
        var newLineNoDataEl = document.createElement("td");
        var newHitCountDataEl = document.createElement("td");
        var newCodeDataEl = document.createElement("td");



        var hitCount = " ";
        if (isInArray((i+1),coveredLines)){   // use i+1 for indexing through the list of covered/missed lines to account for zero-indexing in js
            var className = "hitLine";
            hitCount = hitCountArray[i];
        } else if(isInArray((i+1),missedLines)){
            className = "missedLine";
            hitCount = hitCountArray[i];
        }else {
            className = "codeLine";
        }

        var preLineNumEl = document.createElement("pre");
        preLineNumEl.appendChild(document.createTextNode(String(i+1)));
        preLineNumEl.className = className;
        preLineNumEl.setAttribute('title', messageCatalog.LineNumberText);
        newLineNoDataEl.appendChild(preLineNumEl);

        var preHitCountEl = document.createElement("pre");
        preHitCountEl.appendChild(document.createTextNode(" "+hitCount+" "));                    
        preHitCountEl.className = className;        
        preHitCountEl.setAttribute('title',messageCatalog.HitCountText);
        newHitCountDataEl.appendChild(preHitCountEl);

        var preCodeEl = document.createElement("pre");
        preCodeEl.appendChild(document.createTextNode(sourceContentLines[i]+ " ")); // put a space - empty string does not give the right background color to pre element
        preCodeEl.className = className;
        newCodeDataEl.appendChild(preCodeEl);                 

        newRowEl.appendChild(newLineNoDataEl);
        newRowEl.appendChild(newHitCountDataEl);
        newRowEl.appendChild(newCodeDataEl);
        sourceDispTableBodyEl.appendChild(newRowEl);
    }                
}

function isInArray(value, array) {
// array is a scalar in case of single line missed or hit.
return Array.isArray(array) ? array.indexOf(value) > -1 : value === array;
}

function convertToArray(val) {
        return [].concat(val);
}
