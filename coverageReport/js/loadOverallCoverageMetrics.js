/* eslint-env browser */
/*  Copyright 2018-2020 The MathWorks, Inc. */
function loadOverallCoverageMetrics (overallCoverageData, messageCatalog) {
  // populate the overall coverage data
  document.getElementById('OverallCoverageSummaryTableBody_totalFiles').innerHTML = overallCoverageData.FileCount;
  document.getElementById('OverallCoverageSummaryTableBody_overallLineRate').innerHTML = truncate(overallCoverageData.LineRate, messageCatalog.InvalidLineRateText);
  document.getElementById('OverallCoverageSummaryTableBody_executableLines').innerHTML = overallCoverageData.ExecutableLineCount;
  document.getElementById('OverallCoverageSummaryTableBody_executedLines').innerHTML = overallCoverageData.ExecutedLineCount;
  document.getElementById('OverallCoverageSummaryTableBody_missedLines').innerHTML = overallCoverageData.MissedLineCount;
}
