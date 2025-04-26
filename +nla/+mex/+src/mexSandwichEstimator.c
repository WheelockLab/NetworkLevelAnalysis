#include "mex.h"
#include "sandwich_estimator_openblas_alt.h"
#include <stdlib.h>

/* The gateway function */
void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[])
{
    /* Check for proper number of arguments: expect 3 inputs and 1 output */
    if (nrhs != 3) {
        mexErrMsgIdAndTxt("mexSandwichEstimator:invalidNumInputs",
                          "Three inputs required: residuals, X_pinv, and group_index.");
    }
    if (nlhs > 1) {
        mexErrMsgIdAndTxt("mexSandwichEstimator:invalidNumOutputs",
                          "Only one output allowed.");
    }
    
    /* Input 0: residuals matrix (double, noncomplex) */
    if (!mxIsDouble(prhs[0]) || mxIsComplex(prhs[0])) {
        mexErrMsgIdAndTxt("mexSandwichEstimator:invalidInput",
                          "Residuals must be a real double matrix.");
    }
    /* Input 1: X_pinv matrix (double, noncomplex) */
    if (!mxIsDouble(prhs[1]) || mxIsComplex(prhs[1])) {
        mexErrMsgIdAndTxt("mexSandwichEstimator:invalidInput",
                          "X_pinv must be a real double matrix.");
    }
    /* Input 2: group_index vector (either int32 or double) */
    if (!(mxIsInt32(prhs[2]) || mxIsDouble(prhs[2]))) {
        mexErrMsgIdAndTxt("mexSandwichEstimator:invalidInput",
                          "group_index must be of type int32 or double.");
    }
    
    /* Get dimensions for residuals and X_pinv */
    size_t res_rows = mxGetM(prhs[0]);  /* Number of rows in residuals (num_subjects) */
    size_t res_cols = mxGetN(prhs[0]);  /* Number of columns in residuals (num_fc_edges) */
    size_t pinv_rows = mxGetM(prhs[1]); /* Number of rows in X_pinv (num_covariates) */
    size_t pinv_cols = mxGetN(prhs[1]); /* Number of columns in X_pinv (num_subjects) */
    
    /* Check dimension consistency: number of subjects should match */
    if (res_rows != pinv_cols) {
        mexErrMsgIdAndTxt("mexSandwichEstimator:dimensionMismatch",
                          "The number of rows in residuals must equal the number of columns in X_pinv (num_subjects).");
    }
    
    /* Wrap input matrices into our Matrix structs */
    Matrix residuals;
    residuals.rows = (int)res_rows;
    residuals.cols = (int)res_cols;
    residuals.data = mxGetPr(prhs[0]);  // MATLAB stores doubles in column-major order
    
    Matrix X_pinv;
    X_pinv.rows = (int)pinv_rows;
    X_pinv.cols = (int)pinv_cols;
    X_pinv.data = mxGetPr(prhs[1]);
    
    /* Process group_index: length must equal number of subjects */
    size_t group_len = mxGetNumberOfElements(prhs[2]);
    if (group_len != res_rows) {
        mexErrMsgIdAndTxt("mexSandwichEstimator:dimensionMismatch",
                          "The length of group_index must equal the number of subjects.");
    }
    
    int *group_index_ptr = NULL;
    int i;
    if (mxIsInt32(prhs[2])) {
        /* If group_index is already int32, we can directly use it */
        group_index_ptr = (int *) mxGetData(prhs[2]);
    } else if (mxIsDouble(prhs[2])) {
        /* Convert the double vector to an int array */
        double *temp = mxGetPr(prhs[2]);
        group_index_ptr = (int *) mxMalloc(group_len * sizeof(int));
        for (i = 0; i < (int)group_len; i++) {
            group_index_ptr[i] = (int) temp[i];
        }
    }
    
    /* Create the output covariance matrix.
       Its dimensions are: [num_covariates x num_fc_edges] */
    plhs[0] = mxCreateDoubleMatrix(pinv_rows, res_cols, mxREAL);
    double *cov_data = mxGetPr(plhs[0]);
    
    Matrix cov;
    cov.rows = (int)pinv_rows;
    cov.cols = (int)res_cols;
    cov.data = cov_data;
    
    /* Call the sandwich estimator function */
    sandwich_estimator_openblas_alt(residuals, X_pinv, group_index_ptr, cov);
    
    /* Free temporary group_index memory if it was allocated */
    if (mxIsDouble(prhs[2])) {
        mxFree(group_index_ptr);
    }
}
