#include "mex.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include <stdbool.h>



// 2-tuple struct for sorting paired values
struct Vec2 {
    double x;
    double y;
};

static int compareVec2(const void *ptr1, const void *ptr2) {
    struct Vec2 tuple1 = *(struct Vec2 *) ptr1;
    struct Vec2 tuple2 = *(struct Vec2 *) ptr2;
    if (tuple1.x > tuple2.x) {
        return 1;
    } else if (tuple1.x < tuple2.x) {
        return -1;
    } else {
        if (tuple1.y > tuple2.y) {
            return 1;
        } else {
            return -1;
        }
    }
}

// Minimal red-black tree implementation
struct Node {
    struct Node *left;
    struct Node *right;
    double val;
    int count;
    int branch_count;
    bool red;
};

// whether a node is red or not
static bool isRed(const struct Node *node) {
    if (node) {
        return node->red;
    }
    return false;
}

// size of a node
static int branchCount(const struct Node *node) {
    if (node) {
        return node->branch_count;
    }
    return 0;
}

// make a left-leaning link lean to the right
static struct Node *rotateRight(struct Node *node) {
    struct Node *x = NULL;
    x = node->left;
    node->left = x->right;
    x->right = node;
    x->red = node->red;
    node->red = true;
    x->branch_count = branchCount(x->left) + branchCount(x->right) + x->count;
    node->branch_count = branchCount(node->left) + branchCount(node->right) + node->count;
    return x;
}

// make a right-leaning link lean to the left
static struct Node *rotateLeft(struct Node *node) {
    struct Node *x = NULL;
    x = node->right;
    node->right = x->left;
    x->left = node;
    x->red = node->red;
    node->red = true;
    x->branch_count = branchCount(x->left) + branchCount(x->right) + x->count;
    node->branch_count = branchCount(node->left) + branchCount(node->right) + node->count;
    return x;
}

// flip the colors of a node and its two children
static void flipColors(struct Node *node) {
    node->red = !(node->red);
    node->left->red = !(node->left->red);
    node->right->red = !(node->right->red);
}

// insert element into red-black tree rooted at node
static struct Node *insert(struct Node *node, double val, int *num_lt_ptr, int *num_eq_ptr) {
    // we reached a leaf, create a new node
    if (!node) {
        node = malloc(sizeof(struct Node));
        node->left = NULL;
        node->right = NULL;
        node->val = val;
        node->count = 1;
        node->branch_count = 1;
        node->red = true;
        *num_lt_ptr = 0;
        *num_eq_ptr = node->count;
        return node;
    }
    // we reached a node with matching value
    if (val == node->val) {
        ++node->count;
        ++node->branch_count;
        *num_lt_ptr = branchCount(node->left);
        *num_eq_ptr = node->count;
        return node;
    }
    // continue iterating
    if (val > node->val) {
        node->right = insert(node->right, val, num_lt_ptr, num_eq_ptr);
        // insert must be performed before this operation, as we are
        // counting upwards from the leaf nodes
        *num_lt_ptr += branchCount(node->left) + node->count;
    } else {
        node->left = insert(node->left, val, num_lt_ptr, num_eq_ptr);
    }
    
    // fix any right-leaning links
    if (isRed(node->left) && isRed(node->right)) {
        flipColors(node);
    }
    if (!isRed(node->left) && isRed(node->right)) {
        node = rotateLeft(node);
    }
    if (isRed(node->left) && isRed(node->left->left)) {
        node = rotateRight(node);
    }
    node->branch_count = branchCount(node->left) + branchCount(node->right) + node->count;
    
    return node;
}

// delete a tree rooted at node
static void delete(struct Node *node) {
    if (node) {
        delete(node->left);
        delete(node->right);
        free(node);
    }
}

// find node corresponding to val, set to 1, and return count
int countAndReset(struct Node *node, double val) {
    if (!node) {
        return 0;
    }
    if (val == node->val) {
        int tmp = node->count;
        node->count = 1;
        return tmp;
    }
    if (val > node->val) {
        return countAndReset(node->right, val);
    } else {
        return countAndReset(node->left, val);
    }
}

int min(int x, int y) {
    if (x < y) {
        return x;
    } else {
        return y;
    }
}

static void kendallTauB(const double x[], const double y[], double *tau_ptr, double *p_ptr, const int num_subs) {
    /* kendallTauB: Loosely based on fast Kendall tau-b algorithm, as
     * described in http://dx.doi.org/10.1007/BF02736122.
     *  x: array of values to correlate
     *  y: array of values to correlate
     *  tau_ptr: memory location to output tau correlation statistic
     *  p_ptr: memory location to output 2-tailed p-value
     *  num_subs: length of x and y arrays (must be equal)
     */

    // pair x-y values in tuples and sort in ascending order
    struct Vec2 tuples[num_subs];
    for (int i = 0; i < num_subs; ++i) {
        tuples[i].x = x[i];
        tuples[i].y = y[i];
    }
    qsort(tuples, num_subs, sizeof(struct Vec2), compareVec2);
    
    // red-black tree for inserting values
    struct Node *tree_x = NULL;
    struct Node *tree_y = NULL;
    // values for calculating tau
    int d_count = 0, e_count = 0;
    long long int discordant = 0, tied_x = 0, tied_y = 0, tied_both = 0;
    // ensure these values are different on the first iteration
    double x_prev = tuples[0].x - 1;
    double y_prev = tuples[0].y - 1;
    for (int i = 0; i < num_subs; ++i) {
        if (tuples[i].x != x_prev) {
            d_count = 0;
            e_count = 1;
        } else {
            if (tuples[i].y != y_prev) {
                ++e_count;
            } else {
                d_count = d_count + e_count;
                e_count = 1;
            }
        }
        // calculate how many values are less than or equal our current one
        int x_lt, y_lt, x_eq, y_eq;
        tree_x = insert(tree_x, tuples[i].x, &x_lt, &x_eq);
        tree_y = insert(tree_y, tuples[i].y, &y_lt, &y_eq);
        int x_other_eq = x_eq - 1;
        int y_other_eq = y_eq - 1;
        tied_x += x_other_eq;
        tied_y += y_other_eq;
        tied_both += min(x_other_eq, y_other_eq);
        
        // add to concordant and discordant counts
        int a_count = y_lt - d_count;
        int b_count = y_eq - e_count;
        int c_count = i - (a_count + b_count + d_count + e_count - 1);
        discordant = discordant + c_count;
        
        // set new previous values
        x_prev = tuples[i].x;
        y_prev = tuples[i].y;
    }
    
    // summations for calculating p (destructive effect on trees)
    int vt = 0, vu = 0, v2x = 0, v2y = 0;
    for (int i = 0; i < num_subs; ++i) {
        int count_x = countAndReset(tree_x, tuples[i].x);
        if (count_x > 1) {
            int count_x2 = count_x * (count_x - 1);
            vt += count_x2 * (2 * count_x + 5);
            v2x += count_x2 * (count_x - 2);
        }
        int count_y = countAndReset(tree_y, tuples[i].y);
        if (count_y > 1) {
            int count_y2 = count_y * (count_y - 1);
            vu += count_y2 * (2 * count_y + 5);
            v2y += count_y2 * (count_y - 2);
        }
    }
    delete(tree_x);
    delete(tree_y);
    
    // calculate summary statistics
    long long int num_pairs, num_pairs2, num_tied_pairs, concordant;
    num_pairs2 = (num_subs * (num_subs - 1));
    num_pairs = num_pairs2 / 2;
    num_tied_pairs = tied_x + tied_y - tied_both;
    concordant = num_pairs - (discordant + num_tied_pairs);
    long double k = concordant - discordant;
    // if memory was passed for tau, output it
    if (tau_ptr) {
        *tau_ptr = k / sqrt((long double)((num_pairs - tied_x) * (num_pairs - tied_y)));
    }
    // if memory was passed for p-value, output it
    if (p_ptr) {
        long double v0n, v0, v1n, v1, v2n, v2, v3n, v3, std, z, p;
        v0n = num_pairs * (2 * num_subs + 5);
        v0 = v0n / 9;
        v1n = tied_x * tied_y;
        v1 = v1n / num_pairs;
        v2n = v2x * v2y;
        v2 =  v2n / (18 * num_pairs * (num_subs - 2));
        v3n = (vt + vu);
        v3 = v3n / 18;
        std = sqrt(v0 + v1 + v2 - v3);
        z = (abs(k) - 1) / std;
        p = erfcl(z * sqrt((long double)1/2));
        *p_ptr = (double)p;
    }
}



void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    bool calc_tau = false, calc_p = false;
    int mrows, ncols;

    // Check for proper number of arguments
    if (nrhs < 2) {
        mexErrMsgTxt("Too few input arguments");
    } else if (nrhs > 2) {
        mexErrMsgTxt("Too many input arguments");
    } else if (nlhs > 2) {
        mexErrMsgTxt("Too many output arguments");
    } else if (nlhs == 2) {
        calc_tau = true;
        calc_p = true;
    } else if (nlhs == 1) {
        calc_tau = true;
    } else {
        return;
    }

    // matlab array pointers
    const mxArray *x_matlab, *y_matlab;
    x_matlab = prhs[0];
    y_matlab = prhs[1];
   
    // check arguments
    if (!mxIsDouble(x_matlab) || mxIsComplex(x_matlab)) {
        mexErrMsgTxt("Input x should be a noncomplex scalar double vector");
    }
    if (!mxIsDouble(y_matlab) || mxIsComplex(y_matlab)) {
        mexErrMsgTxt("Input y should be a noncomplex scalar double matrix");
    }
    if (mxGetNumberOfDimensions(x_matlab) > 2) {
        char err[100];
        sprintf(err, "Input x has too many dimensions: %ld", mxGetNumberOfDimensions(x_matlab));
        mexErrMsgTxt(err);
    }
    if (mxGetNumberOfDimensions(y_matlab) > 2) {
        char err[100];
        sprintf(err, "Input y has too many dimensions: %ld", mxGetNumberOfDimensions(y_matlab));
        mexErrMsgTxt(err);
    }
    
    // array dimensions
    int x_rows, x_cols, y_rows, y_cols;
    x_rows = mxGetM(x_matlab);
    x_cols = mxGetN(x_matlab);
    y_rows = mxGetM(y_matlab);
    y_cols = mxGetN(y_matlab);
    int num_subs, num_tests;
    num_subs = y_rows;
    num_tests = y_cols;
    
    // check dimensions
    if (x_cols != 1) {
        char err[100];
        sprintf(err, "Dimensions of input x should be Nx1\nsize(x): (%d, %d)", x_rows, x_cols);
        mexErrMsgTxt(err);
    }
    if (x_rows != y_rows) {
        char err[100];
        sprintf(err, "Row count of inputs x and y should correspond\nsize(x): (%d, %d)\nsize(y): (%d, %d)", x_rows, x_cols, y_rows, y_cols);
        mexErrMsgTxt(err);
    }
    
    // c pointers to data
    double *x_arr, *y_mat;
    x_arr = mxGetPr(x_matlab);
    y_mat = mxGetPr(y_matlab);
    
    // allocate appropriately sized output arrays
    double *tau_arr = NULL, *p_arr = NULL;
    mxArray *tau_matlab, *p_matlab;
    int plhs_index = 0;
    if (calc_tau) {
        tau_matlab = mxCreateDoubleMatrix(1, num_tests, mxREAL);
        plhs[plhs_index++] = tau_matlab;
        tau_arr = mxGetPr(tau_matlab);
    }
    if (calc_p) {
        p_matlab = mxCreateDoubleMatrix(1, num_tests, mxREAL);
        plhs[plhs_index++] = p_matlab;
        p_arr = mxGetPr(p_matlab);
    }
    
    // run kendallTauB function on one pair of vectors at a time
    for (int i = 0; i < num_tests; ++i) {
        // take vector slices of matrices
        double *y_arr = y_mat + (i * num_subs);
        double *tau_idx = NULL, *p_idx = NULL;
        if (calc_tau) {
            tau_idx = tau_arr + i;
        }
        if (calc_p) {
            p_idx = p_arr + i;
        }
        kendallTauB(x_arr, y_arr, tau_idx, p_idx, num_subs);
    }
}