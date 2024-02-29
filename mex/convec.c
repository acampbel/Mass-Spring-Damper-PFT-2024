/*=========================================================
 * convec.c
 * example for passing complex data from MATLAB to C and back again
 *
 * convolves  two complex input vectors
 *
 * This is a MEX-file for MATLAB.
 * Copyright 1984-2017 The MathWorks, Inc.
 *=======================================================*/

#include "mex.h"

/* computational subroutine */
void convec(const mxArray * x, const mxArray * y, const mxArray * z,
            size_t nx, size_t ny)
{
    mwSize i,j;

    #if MX_HAS_INTERLEAVED_COMPLEX
        /* get pointers to the complex arrays */
        mxComplexDouble * xc = mxGetComplexDoubles(x);
        mxComplexDouble * yc = mxGetComplexDoubles(y);
        mxComplexDouble * zc = mxGetComplexDoubles(z);
        zc[0].real = 0;
        zc[0].imag = 0;
        /* perform the convolution of the complex vectors */
        for(i=0; i<nx; i++) {
            for(j=0; j<ny; j++) {
                zc[i+j].real =
                zc[i+j].real + xc[i].real * yc[j].real - xc[i].imag * yc[j].imag;

                zc[i+j].imag =
                zc[i+j].imag + xc[i].real * yc[j].imag + xc[i].imag * yc[j].real;
            }
        }
    /* If mex file was not built using interleaved complex,
     * MX_HAS_INTERLEAVED_COMPLEX will be false.
     */
    #else
        double  *xr, *xi, *yr, *yi, *zr, *zi;
       /* get pointers to the real and imaginary parts of the inputs */
        xr = mxGetPr(x);
        xi = mxGetPi(x);
        yr = mxGetPr(y);
        yi = mxGetPi(y);
        zr = mxGetPr(z);
        zi = mxGetPi(z);

        zr[0]=0.0;
        zi[0]=0.0;
        /* perform the convolution of the complex vectors */
        for(i=0; i<nx; i++) {
            for(j=0; j<ny; j++) {
                zr[i+j] = zr[i+j] + xr[i] * yr[j] - xi[i] * yi[j];
                zi[i+j] = zi[i+j] + xr[i] * yi[j] + xi[i] * yr[j];
            }
        }
    #endif
}

/* The gateway routine. */
void mexFunction( int nlhs, mxArray *plhs[],
                  int nrhs, const mxArray *prhs[] )
{
    size_t rows, cols;
    size_t nx, ny;
    
    /* check for the proper number of arguments */
    if(nrhs != 2)
      mexErrMsgIdAndTxt( "MATLAB:convec:invalidNumInputs",
              "Two inputs required.");
    if(nlhs > 1)
      mexErrMsgIdAndTxt( "MATLAB:convec:maxlhs",
              "Too many output arguments.");
    /*Check that both inputs are row vectors*/
    if( mxGetM(prhs[0]) != 1 || mxGetM(prhs[1]) != 1 )
      mexErrMsgIdAndTxt( "MATLAB:convec:inputsNotVectors",
              "Both inputs must be row vectors.");
    rows = 1; 
    /* Check that both inputs are complex*/
    if( !mxIsComplex(prhs[0]) || !mxIsComplex(prhs[1]) )
      mexErrMsgIdAndTxt( "MATLAB:convec:inputsNotComplex",
              "Inputs must be complex.\n");
  
    /* get the length of each input vector */
    nx = mxGetN(prhs[0]);
    ny = mxGetN(prhs[1]);
  
    /* create a new array and set the output pointer to it */
    cols = nx + ny - 1;
    plhs[0] = mxCreateDoubleMatrix( (mwSize)rows, (mwSize)cols, mxCOMPLEX);

    /* call the C subroutine */
    convec(prhs[0], prhs[1], plhs[0], nx, ny);

    return;
}
