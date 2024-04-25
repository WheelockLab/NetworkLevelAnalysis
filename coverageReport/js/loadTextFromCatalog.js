/* eslint-env browser */
/*  Copyright 2018 The MathWorks, Inc.*/
function loadTextFromCatalog(messageCatalogEntries) { 
    
    populateElementByAppending("CoverageReportTitle",messageCatalogEntries.CoverageReportTitle);
    populateElementByAddingInnerHTML("CoverageReportTitle_h2",messageCatalogEntries.CoverageReportHeader);
    populateElementByAppending("OverallCoverageSummary_p",messageCatalogEntries.OverallCoverageSummaryHeading);
    populateElementByAppending("OverallCoverageSummaryTableHead_totalFilesHeader",messageCatalogEntries.FileCountColumnHeader);
    populateElementByAppending("OverallCoverageSummaryTableHead_overallLineRate",messageCatalogEntries.LineRateColumnHeader);
    populateElementByAppending("OverallCoverageSummaryTableHead_executableLines",messageCatalogEntries.ExecutableLinesColumnHeader);
    populateElementByAppending("OverallCoverageSummaryTableHead_executedLines",messageCatalogEntries.ExecutedLinesColumnHeader);
    populateElementByAppending("OverallCoverageSummaryTableHead_missedLines",messageCatalogEntries.MissedLinesColumnHeader);
    populateElementByAppending("CoverageBySource_p",messageCatalogEntries.CoverageBySourceHeading);
    populateElementByAppending("CoverageListTableHead_fileName",messageCatalogEntries.FileNameColumnHeader);
    populateElementByAppending("CoverageListTableHead_lineRate",messageCatalogEntries.LineRateColumnHeader);
    populateElementByAppending("CoverageListTableHead_executableLines",messageCatalogEntries.ExecutableLinesColumnHeader);
    populateElementByAppending("CoverageListTableHead_executedLines",messageCatalogEntries.ExecutedLinesColumnHeader);
    populateElementByAppending("CoverageListTableHead_missedLines",messageCatalogEntries.MissedLinesColumnHeader);
    populateElementByAppending("SourceCoverage_p",messageCatalogEntries.CoverageMarkupPageTitle);
    populateElementByAppending("goToTopBtn",messageCatalogEntries.ReturnToTopText);
    populateElementByAppending("sourceFileNamePrefix",messageCatalogEntries.SourceFileNamePrefix);
    populateElementByAppending("RootLocationPrefix",messageCatalogEntries.RootLocationText);
}

function populateElementByAppending(elementID,msgStr) {
     document.getElementById(elementID).appendChild(document.createTextNode(msgStr));
}

function populateElementByAddingInnerHTML(elementID,msgStr) {
     document.getElementById(elementID).innerHTML = msgStr;
}

function bodyScrollCallback(floaterElement,floaterTopOffset) {
    
    if (window.pageYOffset >= floaterTopOffset) {
        floaterElement.classList.add("sticky");
        resizeStickyWidth(floaterElement);
    } else {
        floaterElement.classList.remove("sticky");
    }
    
    
    if (document.body.scrollTop > 20 || document.documentElement.scrollTop > 20) {
        document.getElementById("goToTopBtn").classList.add("showButton");   
    } else {
        document.getElementById("goToTopBtn").classList.remove("showButton");
    }
}

// When the user clicks on the button, scroll to the top of the document
function goToTopFunction() {
    document.body.scrollTop = 0;
    document.documentElement.scrollTop = 0;
} 

function resizeStickyWidth(stickyEl) {
    var parentEl = stickyEl.parentElement;
    stickyEl.style.width = parentEl.offsetWidth + "px";
}
            
            
            