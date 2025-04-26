#ifndef SANDWICH_ESTIMATOR_OPENBLAS_ALT_H
#define SANDWICH_ESTIMATOR_OPENBLAS_ALT_H

// Matrix struct for a column-major matrix
typedef struct {
    int rows;
    int cols;
    double *data;
} Matrix;

// Macro to compute the column-major index
#define MAT_IDX(m, i, j) ((i) + (j) * ((m).rows))
#define ALIGNMENT 64

// Function prototypes
Matrix allocate_matrix(int rows, int cols);
void free_matrix(Matrix m);
void zero_matrix(Matrix m);

void sandwich_estimator_openblas_alt(const Matrix residuals,
                                     const Matrix X_pinv,
                                     const int *group_index,
                                     Matrix cov);

#endif
