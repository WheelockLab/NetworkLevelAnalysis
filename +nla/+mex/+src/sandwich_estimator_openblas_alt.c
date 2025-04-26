#include "sandwich_estimator_openblas_alt.h"
#include <cblas.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Allocate a Matrix with the given dimensions
Matrix allocate_matrix(int rows, int cols) {
    Matrix m;
    m.rows = rows;
    m.cols = cols;

    // Allocate memory for rows*cols doubles, with proper alignment
    int ret = posix_memalign((void**)&(m.data), ALIGNMENT, rows * cols * sizeof(double));
    if (ret != 0 || m.data == NULL) {
        fprintf(stderr, "Memory allocation error.\n");
        exit(EXIT_FAILURE);
    }
    return m;
}

// Free the memory associated with a Matrix
void free_matrix(Matrix m) {
    free(m.data);
}

// Zero out all elements of a Matrix
void zero_matrix(Matrix m) {
    int total = m.rows * m.cols;
    for (int i = 0; i < total; i++) {
        m.data[i] = 0.0;
    }
}

// Computes the sandwich estimator using OpenBLAS
void sandwich_estimator_openblas_alt(const Matrix residuals,
                                     const Matrix X_pinv,
                                     const int *group_index,
                                     Matrix cov) {
    // Zero initialize the output covariance matrix
    zero_matrix(cov);

    // Find what is the maximum group number
    int max_label = 0;
    for (int i = 0; i < residuals.rows; i++) {
        if (group_index[i] > max_label)
            max_label = group_index[i];
    }

    // Initialize array to record if a group number exists
    char *group_exists;
    int mem_ge_check = posix_memalign((void **)&group_exists, ALIGNMENT, (max_label + 1) * sizeof(char));
    if (mem_ge_check != 0 || group_exists == NULL) {
        fprintf(stderr, "Memory allocation error for group_exists.\n");
        exit(EXIT_FAILURE);
    }
    // Use memset to zero it out
    memset(group_exists, 0, (max_label + 1) * sizeof(char));

    // Track if a group number exists
    for (int i = 0; i < residuals.rows; i++) {
        group_exists[group_index[i]] = 1;
    }
    
    // Count how many unique group numbers are there
    int num_groups = 0;
    for (int j = 0; j <= max_label; j++) {
        if (group_exists[j])
            num_groups++;
    }

    // Initialize array for unique group numbers
    int *unique_groups;
    int mem_ug_check = posix_memalign((void **)&unique_groups, ALIGNMENT, num_groups * sizeof(int)); 
    if (mem_ug_check != 0 || unique_groups == NULL) {
        fprintf(stderr, "Memory allocation error in unique_groups.\n");
        exit(EXIT_FAILURE);
    }
    // Use memset to zero it out
    memset(unique_groups, 0, (num_groups * sizeof(int)));

    // Find the indices for each unique group number
    int idx = 0;
    for (int j = 0; j <= max_label; j++) {
        if (group_exists[j])
            unique_groups[idx++] = j;
    }
    free(group_exists);

    // Allocate a temporary matrix Dg for accumulating each group's contribution
    Matrix Dg = allocate_matrix(X_pinv.rows, residuals.cols);

    // Now loop over the unique group labels
    for (int g = 0; g < num_groups; g++) {
        int current_group = unique_groups[g];
        zero_matrix(Dg);

        // For each subject in the current group, perform a rank-1 update
        for (int i = 0; i < residuals.rows; i++) {
            if (group_index[i] == current_group) {
                const double *x = X_pinv.data + i * X_pinv.rows;
                const double *y = residuals.data + i;
                cblas_dger(CblasColMajor,
                        X_pinv.rows,         // Number of rows in x (num_covariates)
                        residuals.cols,      // Number of columns in y (num_fc_edges)
                        1.0,                 // Scaling factor
                        x, 1,                // x vector (inc = 1 since column is contiguous)
                        y, residuals.rows,   // y vector (inc = number of subjects, since row elements are spaced by rows)
                        Dg.data, Dg.rows);   // Dg: accumulator matrix 
            }
            // A = A + alpha* x^T * y, or y^T * x
        }

        // Add Dg to the overall covariance matrix.
        int total = cov.rows * cov.cols;
        for (int i = 0; i < total; i++) {
            double temp = Dg.data[i];
            cov.data[i] += temp * temp;
        }
    }

    free(unique_groups);
    
    free_matrix(Dg);
}
