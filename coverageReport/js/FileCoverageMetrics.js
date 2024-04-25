/* eslint-env browser */
/*  Copyright 2018-2020 The MathWorks, Inc. */
function FileCoverageMetrics (fullCoverageData, tableDomElement, messageCatalog) {
  var coverageArray = fullCoverageData.FileCoverageArray;
  var TableDom = tableDomElement;
  var SortedBy = 'none'; // no sorting by default.

  var FileCoverageMetricsObj = {

    CommonRootPath: fullCoverageData.CommonRootPath,
    MessageCatalogEntries: messageCatalog,
    RelativePathArray: convertToArray(coverageArray.RelativePath),
    ExecutableLineCountArray: convertToArray(coverageArray.ExecutableLineCount),
    ExecutedLineCountArray: convertToArray(coverageArray.ExecutedLineCount),
    LineRateArray: convertToArray(coverageArray.LineRate),
    MissedLineCountArray: convertToArray(coverageArray.MissedLineCount),
    CoverageElementCount: convertToArray(coverageArray.RelativePath).length,
    CurrentSelectedFile: fullCoverageData.CommonRootPath + convertToArray(coverageArray.RelativePath)[0],
    DisplayOrderIndex: Array.apply(null, { length: (convertToArray(coverageArray.RelativePath).length) }).map(Function.call, Number), // The DisplayOrderIndex is an array of sequential numbers [1,2,3,..N], N being the number of data rows in the table. This order is later used for sorting the table rows. Default order rows (i.e.files) is as exported from MATLAB.

    // public methods
    displayRootPath: function () {
      // Modify the filename header in coverage header to reflect common root path for files
      if (this.CommonRootPath.length > 0) {
        var rootLocationDiv = document.getElementById('DivForRootLocation');
        var rootLocationSpan = document.getElementById('RootLocationSpan');
        rootLocationSpan.innerHTML = ' - ' + this.CommonRootPath;
        rootLocationDiv.style.display = 'block';
      }
    },

    displayCoverageMetrics: function () {
      var rowNode, displayIdx, fullFileName, fileNameDataNode;
      var bodyElement = createFreshBody();
      for (var i = 0; i < this.CoverageElementCount; i++) {
        rowNode = document.createElement('tr');
        displayIdx = this.DisplayOrderIndex[i];
        fullFileName = this.CommonRootPath + this.RelativePathArray[displayIdx];

        rowNode.onclick = function (displayIdx, fullFileName, rowNode) {
          loadNewFileAndReact('coverageData/sourceData' + displayIdx, displayCodeMarkup, coverageObj.MessageCatalogEntries, fullFileName, rowNode, coverageObj.CurrentSelectedFile);
          coverageObj.CurrentSelectedFile = fullFileName;
        }.bind(undefined, displayIdx, fullFileName, rowNode);

        fileNameDataNode = getTableDataNode(document.createTextNode(this.RelativePathArray[displayIdx], displayIdx));
        fileNameDataNode.className = 'leftAlign';
        addTableData(rowNode, fileNameDataNode);

        addTableData(rowNode, getTableDataNode(document.createTextNode(truncate(this.LineRateArray[displayIdx], this.MessageCatalogEntries.InvalidLineRateText))));
        addTableData(rowNode, getTableDataNode(document.createTextNode(this.ExecutableLineCountArray[displayIdx])));
        addTableData(rowNode, getTableDataNode(document.createTextNode(this.ExecutedLineCountArray[displayIdx])));
        addTableData(rowNode, getTableDataNode(document.createTextNode(this.MissedLineCountArray[displayIdx])));

        if (fullFileName === this.CurrentSelectedFile) {
          rowNode.classList.add('selectedRow');
        }

        bodyElement.appendChild(rowNode);
      }
    },

    sortTableByColumn: function (columnName) {
      // check if the column is already sorted. If it is, just reverse the order
      if (SortedBy == columnName) {
        this.DisplayOrderIndex.reverse();
      } else {
        if (SortedBy != 'none') {
          // reset the sort icon to "unsorted" for the previously sorted column
          resetSortIcon(SortedBy);
        }
        this.DisplayOrderIndex = sortAndReturnIndices(this[columnName]);
        SortedBy = columnName;
      }
      this.displayCoverageMetrics();

      // change the sort icon for the new column
      modifySortIcon(columnName);
    }
  };

  // helper functions
  function addTableData (rowNode, dataNode) {
    rowNode.appendChild(dataNode);
    return rowNode;
  }

  function getTableDataNode (data) {
    var dataNode = document.createElement('td');
    dataNode.appendChild(data);
    return dataNode;
  }

  function createFreshBody () {
    var currentBodyEl, newBodyEl;
    currentBodyEl = TableDom.getElementsByTagName('TBODY')[0];
    TableDom.removeChild(currentBodyEl);
    newBodyEl = document.createElement('TBODY');
    TableDom.appendChild(newBodyEl);
    return newBodyEl;
  }

  function sortAndReturnIndices (arrayToSort) {
    // this function returns sorts an array A and returns the indices of elements in A in the sorted order. for example -
    // if array A = [1,5,2,3];
    // this function returns indices [0,2,3,1].
    var sortingContainer = []; var sortIndices = [];
    for (var i = 0; i < arrayToSort.length; i++) {
      sortingContainer[i] = [arrayToSort[i], i];
    }
    sortingContainer.sort(function (left, right) {
      if (left[0] === null) {
        return 1;
      } else if (right[0] === null) {
        return -1;
      } else {
        return left[0] < right[0] ? -1 : 1;
      }
    });

    for (var j = 0; j < sortingContainer.length; j++) {
      sortIndices.push(sortingContainer[j][1]);
    }
    return sortIndices;
  }

  function modifySortIcon (columnName) {
    // change the sort icon when the column is sorted.
    var imageSpan = document.getElementById(columnName + '_SortSpan');
    imageSpan.classList.remove('img_unsorted');

    if (imageSpan.classList.contains('img_ascendingsorted')) {
      imageSpan.classList.remove('img_ascendingsorted');
      imageSpan.classList.add('img_descendingsorted');
    } else {
      imageSpan.classList.add('img_ascendingsorted');
      imageSpan.classList.remove('img_descendingsorted');
    }
  }

  function resetSortIcon (columnName) {
    // reset the sort icon to unsorted, and hide it.
    var imageSpan = document.getElementById(columnName + '_SortSpan');
    imageSpan.classList.remove('img_ascendingsorted', 'img_descendingsorted');
    imageSpan.classList.add('img_unsorted');
  }

  return FileCoverageMetricsObj;
}

function fixTableHeaderOnScroll (divContainingTable) {
  divContainingTable.addEventListener('scroll', function () {
    var translate = 'translate(0,' + divContainingTable.scrollTop + 'px)';
    var headEl = divContainingTable.getElementsByTagName('THEAD')[0];
    headEl.style.transform = translate;
  });
}

function convertToArray (val) {
  return [].concat(val);
}

function truncate (val, invalidLineRateText) {
  var rate;
  if (val === null) {
    rate = invalidLineRateText;
  } else {
    rate = (Math.floor(100 * val) / 100).toString() + '%';
  }
  return (rate);
}
