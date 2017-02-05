#include <utils/MatrixUtil.h>
#include <utils/ImageUtil.h>
#include <nppi.h>
#include "kernels/ImageKernels.cu"

#ifdef __cplusplus
  extern "C" {
#endif

void cudaErrCheck(cudaError_t stat)
{
  if (stat != cudaSuccess)
  {
    printf("CUDA ERR\n%s\n",cudaGetErrorString(stat));
  }
}

void nppCallErrCheck(NppStatus status)
{
  if (status != NPP_SUCCESS)
  {
    printf("\n##########\nNPP ERROR!\nError code: %d\n##########\n",status);
  }
}

//#############
//INIT Methods
//############
void syncDeviceFromHostImpl(Image* self)
{
  copyHostToDeviceCudaMatrix(self->pixels);
}

void syncHostFromDeviceImpl(Image* self)
{
  copyDeviceToHostCudaMatrix(self->pixels);
}

void freeImageImpl(Image* self)
{
  printf("imfree\n");
  self->pixels->free(self->pixels);
  free(self->pixbuf);
  free(self);
}

Image* newEmptyImageImpl(ImageUtil* self, Shape shape)
{
  if (VERBOSITY > 3)
  {
    printf("CREATING NEW EMPTY IMAGE\n");
  }
  Image* im = (Image*)malloc(sizeof(Image));
  im->nChannels = 1;
  im->shape = shape;
  im->pixels=self->matutil->newEmptyMatrix(shape);
  im->free = freeImageImpl;
  im->syncHostFromDevice = syncHostFromDeviceImpl;
  im->syncDeviceFromHost = syncDeviceFromHostImpl;
  return im;
}

Image* newImageImpl(ImageUtil* self, float* data, Shape shape)
{
  if (VERBOSITY > 3)
  {
    printf("CREATING NEW IMAGE FROM DATA\n");
  }
  Image* im = self->newEmptyImage(self,shape);
  free(im->pixels->hostPtr);
  im->pixels->hostPtr = data;
  return im;
}

Image* newImageFromMatrixImpl(ImageUtil* self, Matrix* m)
{
  if (VERBOSITY > 3)
  {
    printf("CREATING NEW IMAGE FROM MATRIX\n");
  }
  Image* im = self->newEmptyImage(self,m->shape);
  im->pixels->free(im->pixels);
  im->pixels = m;
  return im;
}
//#################
//END INIT METHODS
//################

//#######
//FILTERS
//#######
Image* convolveImageImpl(ImageUtil* self, Image* im, Image* kernel)
{
  Image* retval = self->newEmptyImage(self,im->shape);

  if (im->pixels->isHostSide)
  {
    copyHostToDeviceCudaMatrix(im->pixels);
  }
  if (kernel->pixels->isHostSide)
  {
    copyHostToDeviceCudaMatrix(kernel->pixels);
  }
  if (retval->pixels->isHostSide)
  {
    copyHostToDeviceCudaMatrix(retval->pixels);
  }

  Npp32f* pSrc = im->pixels->devicePtr;
  int nSrcStep = im->shape.height*sizeof(float);
  NppiSize oSrcSize = {im->shape.height,im->shape.width};
  NppiPoint oSrcOffset = {0,0};
  Npp32f* pDst = retval->pixels->devicePtr;
  int nDstStep = im->shape.height*sizeof(float);
  NppiSize oSizeROI = {im->shape.height,im->shape.width};
  Npp32f* pKernel = kernel->pixels->devicePtr;
  NppiSize oKernelSize = {kernel->shape.height,kernel->shape.width};
  NppiPoint oAnchor = {oKernelSize.width/2,oKernelSize.height/2};
  NppiBorderType eBorderType = NPP_BORDER_REPLICATE;
  nppCallErrCheck(nppiFilterBorder_32f_C1R(pSrc,nSrcStep,oSrcSize,oSrcOffset,pDst,nDstStep,oSizeROI,pKernel,oKernelSize,oAnchor,eBorderType));

  return retval;
}

Image* gradientXImageImpl(ImageUtil* self, Image* im)
{
  Image* retval = self->newEmptyImage(self,im->shape);

  if (im->pixels->isHostSide)
  {
    copyHostToDeviceCudaMatrix(im->pixels);
  }
  if (retval->pixels->isHostSide)
  {
    copyHostToDeviceCudaMatrix(retval->pixels);
  }

  Npp32f* pSrc = im->pixels->devicePtr;
  int nSrcStep = im->shape.height*sizeof(float);
  NppiSize oSrcSize = {im->shape.height,im->shape.width};
  NppiPoint oSrcOffset = {0,0};
  Npp32f* pDstX = retval->pixels->devicePtr;;
  int nDstXStep = retval->shape.height*sizeof(float);;
  Npp32f* pDstY = NULL;
  int nDstYStep = 0;
  Npp32f* pDstMag = NULL;
  int nDstMagStep = 0;
  Npp32f* pDstAngle = NULL;
  int nDstAngleStep = 0;
  NppiSize oSizeROI = {im->shape.height,im->shape.width};
  NppiNorm eNorm = nppiNormL2;
  NppiMaskSize eMaskSize = NPP_MASK_SIZE_3_X_3;
  NppiBorderType eBorderType = NPP_BORDER_REPLICATE;
  nppCallErrCheck(nppiGradientVectorSobelBorder_32f_C1R(pSrc,nSrcStep,oSrcSize,oSrcOffset,pDstX,nDstXStep,pDstY,nDstYStep,pDstMag,nDstMagStep,pDstAngle,nDstAngleStep,oSizeROI,eMaskSize,eNorm,eBorderType));

  return retval;
}

Image* gradientYImageImpl(ImageUtil* self, Image* im)
{
  Image* retval = self->newEmptyImage(self,im->shape);

  if (im->pixels->isHostSide)
  {
    copyHostToDeviceCudaMatrix(im->pixels);
  }
  if (retval->pixels->isHostSide)
  {
    copyHostToDeviceCudaMatrix(retval->pixels);
  }

  Npp32f* pSrc = im->pixels->devicePtr;
  int nSrcStep = im->shape.height*sizeof(float);
  NppiSize oSrcSize = {im->shape.height,im->shape.width};
  NppiPoint oSrcOffset = {0,0};
  Npp32f* pDstX = NULL;
  int nDstXStep = 0;
  Npp32f* pDstY = retval->pixels->devicePtr;;
  int nDstYStep = retval->shape.height*sizeof(float);
  Npp32f* pDstMag = NULL;
  int nDstMagStep = 0;
  Npp32f* pDstAngle = NULL;
  int nDstAngleStep = 0;
  NppiSize oSizeROI = {im->shape.height,im->shape.width};
  NppiNorm eNorm = nppiNormL2;
  NppiMaskSize eMaskSize = NPP_MASK_SIZE_3_X_3;
  NppiBorderType eBorderType = NPP_BORDER_REPLICATE;
  nppCallErrCheck(nppiGradientVectorSobelBorder_32f_C1R(pSrc,nSrcStep,oSrcSize,oSrcOffset,pDstX,nDstXStep,pDstY,nDstYStep,pDstMag,nDstMagStep,pDstAngle,nDstAngleStep,oSizeROI,eMaskSize,eNorm,eBorderType));

  return retval;
}

Image* gradientMagnitudeImageImpl(ImageUtil* self, Image* im)
{
  Image* retval = self->newEmptyImage(self,im->shape);

  if (im->pixels->isHostSide)
  {
    copyHostToDeviceCudaMatrix(im->pixels);
  }
  if (retval->pixels->isHostSide)
  {
    copyHostToDeviceCudaMatrix(retval->pixels);
  }

  Npp32f* pSrc = im->pixels->devicePtr;
  int nSrcStep = im->shape.height*sizeof(float);
  NppiSize oSrcSize = {im->shape.height,im->shape.width};
  NppiPoint oSrcOffset = {0,0};
  Npp32f* pDstX = NULL;
  int nDstXStep = 0;
  Npp32f* pDstY = NULL;
  int nDstYStep = 0;
  Npp32f* pDstMag = retval->pixels->devicePtr;
  int nDstMagStep = retval->shape.height*sizeof(float);
  Npp32f* pDstAngle = NULL;
  int nDstAngleStep = 0;
  NppiSize oSizeROI = {im->shape.height,im->shape.width};
  NppiNorm eNorm = nppiNormL2;
  NppiMaskSize eMaskSize = NPP_MASK_SIZE_3_X_3;
  NppiBorderType eBorderType = NPP_BORDER_REPLICATE;
  //nppSetStream(self->matutil->stream);
  nppCallErrCheck(nppiGradientVectorSobelBorder_32f_C1R(pSrc,nSrcStep,oSrcSize,oSrcOffset,pDstX,nDstXStep,pDstY,nDstYStep,pDstMag,nDstMagStep,pDstAngle,nDstAngleStep,oSizeROI,eMaskSize,eNorm,eBorderType));

  return retval;
}

Image* gradientAngleImageImpl(ImageUtil* self, Image* im)
{
  Image* retval = self->newEmptyImage(self,im->shape);

  if (im->pixels->isHostSide)
  {
    copyHostToDeviceCudaMatrix(im->pixels);
  }
  if (retval->pixels->isHostSide)
  {
    copyHostToDeviceCudaMatrix(retval->pixels);
  }

  Npp32f* pSrc = im->pixels->devicePtr;
  int nSrcStep = im->shape.height*sizeof(float);
  NppiSize oSrcSize = {im->shape.height,im->shape.width};
  NppiPoint oSrcOffset = {0,0};
  Npp32f* pDstX = NULL;
  int nDstXStep = 0;
  Npp32f* pDstY = NULL;
  int nDstYStep = 0;
  Npp32f* pDstMag = NULL;
  int nDstMagStep = 0;
  Npp32f* pDstAngle = retval->pixels->devicePtr;
  int nDstAngleStep = retval->shape.height*sizeof(float);
  NppiSize oSizeROI = {im->shape.height,im->shape.width};
  NppiNorm eNorm = nppiNormL2;
  NppiMaskSize eMaskSize = NPP_MASK_SIZE_3_X_3;
  NppiBorderType eBorderType = NPP_BORDER_REPLICATE;
  nppCallErrCheck(nppiGradientVectorSobelBorder_32f_C1R(pSrc,nSrcStep,oSrcSize,oSrcOffset,pDstX,nDstXStep,pDstY,nDstYStep,pDstMag,nDstMagStep,pDstAngle,nDstAngleStep,oSizeROI,eMaskSize,eNorm,eBorderType));

  return retval;
}

ImageGradientVectorPair* gradientsImageImpl(ImageUtil* self, Image* im)
{
  Image* magnitude = self->newEmptyImage(self,im->shape);
  Image* angle = self->newEmptyImage(self,im->shape);

  if (im->pixels->isHostSide)
  {
    copyHostToDeviceCudaMatrix(im->pixels);
  }
  if (magnitude->pixels->isHostSide)
  {
    copyHostToDeviceCudaMatrix(magnitude->pixels);
  }
  if (angle->pixels->isHostSide)
  {
    copyHostToDeviceCudaMatrix(angle->pixels);
  }

  ImageGradientVectorPair* retval = (ImageGradientVectorPair*)malloc(sizeof(ImageGradientVectorPair));
  retval->magnitude = magnitude;
  retval->angle = angle;
  Npp32f* pSrc = im->pixels->devicePtr;
  int nSrcStep = im->shape.height*sizeof(float);
  NppiSize oSrcSize = {im->shape.height,im->shape.width};
  NppiPoint oSrcOffset = {0,0};
  Npp32f* pDstX = NULL;
  int nDstXStep = 0;
  Npp32f* pDstY = NULL;
  int nDstYStep = 0;
  Npp32f* pDstMag = magnitude->pixels->devicePtr;
  int nDstMagStep = magnitude->shape.height*sizeof(float);
  Npp32f* pDstAngle = angle->pixels->devicePtr;
  int nDstAngleStep = angle->shape.height*sizeof(float);
  NppiSize oSizeROI = {im->shape.height,im->shape.width};
  NppiNorm eNorm = nppiNormL2;
  NppiMaskSize eMaskSize = NPP_MASK_SIZE_3_X_3;
  NppiBorderType eBorderType = NPP_BORDER_REPLICATE;
  nppCallErrCheck(nppiGradientVectorSobelBorder_32f_C1R(pSrc,nSrcStep,oSrcSize,oSrcOffset,pDstX,nDstXStep,pDstY,nDstYStep,pDstMag,nDstMagStep,pDstAngle,nDstAngleStep,oSizeROI,eMaskSize,eNorm,eBorderType));

  return retval;
}
//############
//END FILTERS
//###########

//#########
//GEOMETRY
//########
Image* resampleImageImpl(ImageUtil* self, Image* im, Shape shape)
{
  Image* retval = self->newEmptyImage(self,shape);

  if (im->pixels->isHostSide)
  {
    copyHostToDeviceCudaMatrix(im->pixels);
  }
  if (retval->pixels->isHostSide)
  {
    copyHostToDeviceCudaMatrix(retval->pixels);
  }

  Npp32f* pSrc = im->pixels->devicePtr;
  int nSrcStep = im->shape.height*sizeof(float);
  NppiSize oSrcSize = {im->shape.height,im->shape.width};
  NppiRect oSrcROI = {0,0,im->shape.height,im->shape.width};
  Npp32f* pDst = retval->pixels->devicePtr;
  int nDstStep = retval->shape.height*sizeof(float);
  NppiRect oDstROI = {0,0,retval->shape.height,retval->shape.width};
  double nXFactor = ((float)shape.width)/((float)im->shape.height);
  double nYFactor = ((float)shape.height)/((float)im->shape.width);
  double nXShift = 0;
  double nYShift = 0;
  NppiInterpolationMode eInterpolation = NPPI_INTER_CUBIC;
  nppCallErrCheck(nppiResizeSqrPixel_32f_C1R(pSrc,oSrcSize,nSrcStep,oSrcROI,pDst,nDstStep,oDstROI,nXFactor,nYFactor,nXShift,nYShift,eInterpolation));

  return retval;
}
//#############
//END GEOMETRY
//#############

//##########
//ARITHMETIC
//##########
Image* addImageImpl(ImageUtil* self, Image* im1, Image*im2)
{
  Image* retval = self->newEmptyImage(self,im1->shape);

  if (im1->pixels->isHostSide)
  {
    copyHostToDeviceCudaMatrix(im1->pixels);
  }
  if (im2->pixels->isHostSide)
  {
    copyHostToDeviceCudaMatrix(im2->pixels);
  }
  if (retval->pixels->isHostSide)
  {
    copyHostToDeviceCudaMatrix(retval->pixels);
  }

  Npp32f* pSrc1 = im1->pixels->devicePtr;
  int nSrc1Step = im1->shape.height*sizeof(float);
  Npp32f* pSrc2 = im2->pixels->devicePtr;
  int nSrc2Step = im2->shape.height*sizeof(float);
  Npp32f* pDst = retval->pixels->devicePtr;
  int nDstStep = retval->shape.height*sizeof(float);
  NppiSize oSizeROI = {im1->shape.height,im1->shape.width};
  nppCallErrCheck(nppiAdd_32f_C1R(pSrc1,nSrc1Step,pSrc2,nSrc2Step,pDst,nDstStep,oSizeROI));

  return retval;
}

Image* subtractImageImpl(ImageUtil* self, Image* im1, Image*im2)
{
  Image* retval = self->newEmptyImage(self,im1->shape);

  if (im1->pixels->isHostSide)
  {
    copyHostToDeviceCudaMatrix(im1->pixels);
  }
  if (im2->pixels->isHostSide)
  {
    copyHostToDeviceCudaMatrix(im2->pixels);
  }
  if (retval->pixels->isHostSide)
  {
    copyHostToDeviceCudaMatrix(retval->pixels);
  }

  Npp32f* pSrc1 = (Npp32f*)(im1->pixels->devicePtr);
  int nSrc1Step = im1->shape.height*sizeof(float);
  Npp32f* pSrc2 = im2->pixels->devicePtr;
  int nSrc2Step = im2->shape.height*sizeof(float);
  Npp32f* pDst = retval->pixels->devicePtr;
  int nDstStep = retval->shape.height*sizeof(float);
  NppiSize oSizeROI = {im1->shape.height,im1->shape.width};
  nppCallErrCheck(nppiSub_32f_C1R(pSrc1,nSrc1Step,pSrc2,nSrc2Step,pDst,nDstStep,oSizeROI));

  return retval;
}

Image* multiplyCImageImpl(ImageUtil* self, Image* im, float val)
{
  Image* retval = self->newEmptyImage(self,im->shape);

  if (im->pixels->isHostSide)
  {
    copyHostToDeviceCudaMatrix(im->pixels);
  }
  if (retval->pixels->isHostSide)
  {
    copyHostToDeviceCudaMatrix(retval->pixels);
  }

  float* pSrc1 = im->pixels->devicePtr;
  int nSrc1Step = im->shape.height*sizeof(float);
  float nConstant = val;
  float* pDst = retval->pixels->devicePtr;
  int nDstStep = retval->shape.height*sizeof(float);
  NppiSize oSizeROI = {im->shape.height,im->shape.width};
  nppCallErrCheck(nppiMulC_32f_C1R(pSrc1,nSrc1Step,nConstant,pDst,nDstStep,oSizeROI));

  return retval;
}

Image* multiplyImageImpl(ImageUtil* self, Image* im1, Image* im2)
{
  Image* retval = self->newEmptyImage(self,im1->shape);

  if (im1->pixels->isHostSide)
  {
    copyHostToDeviceCudaMatrix(im1->pixels);
  }
  if (im2->pixels->isHostSide)
  {
    copyHostToDeviceCudaMatrix(im2->pixels);
  }
  if (retval->pixels->isHostSide)
  {
    copyHostToDeviceCudaMatrix(retval->pixels);
  }


  float* pSrc1 = im1->pixels->devicePtr;
  int nSrc1Step = im1->shape.height*sizeof(float);
  float* pSrc2 = im2->pixels->devicePtr;
  int nSrc2Step = im2->shape.height*sizeof(float);
  float* pDst = retval->pixels->devicePtr;
  int nDstStep = retval->shape.height*sizeof(float);
  NppiSize oSizeROI = {im1->shape.height,im1->shape.width};
  nppCallErrCheck(nppiMul_32f_C1R(pSrc1,nSrc1Step,pSrc2,nSrc2Step,pDst,nDstStep,oSizeROI));

  return retval;
}
//###############
//END ARITHMETIC
//##############

//##########
//STATISTICS
//##########
Image* maxImageImpl(ImageUtil* self, Image* im, int radius)
{
  Image* retval = self->newEmptyImage(self,im->shape);
  if (im->pixels->isHostSide)
  {
    copyHostToDeviceCudaMatrix(im->pixels);
  }
  if (retval->pixels->isHostSide)
  {
    copyHostToDeviceCudaMatrix(retval->pixels);
  }

  int wregions = im->shape.height/radius;
  int hregions = im->shape.width/radius;
  float* pSrc = im->pixels->devicePtr;
  float* pDst = retval->pixels->devicePtr;
  NppiSize oSize = {im->shape.height,im->shape.width};

  int bdimX = fmin(32,wregions);
  int bdimY = fmin(32,hregions);
  dim3 bdim(bdimX,bdimY);
  dim3 gdim(wregions/bdimX + 1,hregions/bdimY + 1);
  LocalMaxKernel<<<gdim,bdim>>>(pSrc,pDst,oSize,radius);

  return retval;
}

ImageIndexPair* maxIdxImageImpl(ImageUtil* self, Image* im, int radius)
{
  Image* dst = self->newEmptyImage(self,im->shape);
  if (im->pixels->isHostSide)
  {
    copyHostToDeviceCudaMatrix(im->pixels);
  }
  if (dst->pixels->isHostSide)
  {
    copyHostToDeviceCudaMatrix(dst->pixels);
  }
  int wregions = im->shape.height/radius;
  int hregions = im->shape.width/radius;
  Npp32f* pSrc = im->pixels->devicePtr;
  Npp32f* pDst = dst->pixels->devicePtr;
  int* pIdx;
  size_t indexSize = sizeof(int)*(wregions*hregions);
  cudaErrCheck(cudaMalloc(&pIdx,indexSize));
  NppiSize oSize = {im->shape.height,im->shape.width};

  int bdimX = fmin(32,wregions);
  int bdimY = fmin(32,hregions);
  dim3 bdim(bdimX,bdimY);
  dim3 gdim(wregions/bdimX + 1,hregions/bdimY + 1);
  LocalMaxIdxKernel<<<gdim,bdim>>>(pSrc,pDst,pIdx,oSize,radius);
  ImageIndexPair* retval = (ImageIndexPair*)malloc(sizeof(ImageIndexPair));
  retval->image=im;
  retval->index=pIdx;
  retval->count=wregions*hregions;
  retval->subPixelX = NULL;
  retval->subPixelY = NULL;
  return retval;
}

Image* localContrastImageImpl(ImageUtil* self, Image* im, int radius)
{
  Image* retval = self->newEmptyImage(self,im->shape);

  if (im->pixels->isHostSide)
  {
    copyHostToDeviceCudaMatrix(im->pixels);
  }
  if (retval->pixels->isHostSide)
  {
    copyHostToDeviceCudaMatrix(retval->pixels);
  }

  int wregions = im->shape.height/radius;
  int hregions = im->shape.width/radius;
  float* pSrc = im->pixels->devicePtr;
  float* pDst = retval->pixels->devicePtr;
  NppiSize oSize = {im->shape.height,im->shape.width};

  int bdimX = fmin(32,wregions);
  int bdimY = fmin(32,hregions);
  dim3 bdim(bdimX,bdimY);
  dim3 gdim(wregions/bdimX + 1,hregions/bdimY + 1);
  LocalContrastKernel<<<gdim,bdim>>>(pSrc,pDst,oSize,radius);

  return retval;
}
//##############
//END STATISTICS
//##############

//######################
// BEGIN COMPUTERVISION
//######################

void subPixelAlignImageIndexPairImpl(ImageUtil* self, ImageIndexPair* data)
{
  if (data->image->pixels->isHostSide)
  {
    copyHostToDeviceCudaMatrix(data->image->pixels);
  }
  printf("1\n");
  Image* Ix = self->gradientX(self,data->image);
  Image* Iy = self->gradientY(self,data->image);
  Image* Ixx = self->gradientX(self,Ix);
  Image* Ixy = self->gradientY(self,Ix);
  Image* Iyy = self->gradientY(self,Iy);
  printf("2\n");

  int* pIdx = data->index;
  float* pSubPixelX;
  float* pSubPixelY;
  NppiSize oSize = {Ix->shape.height,Ix->shape.width};
  printf("3\n");

  size_t size = sizeof(float)*(data->count);
  cudaErrCheck(cudaMalloc(&pSubPixelX,size));
  cudaErrCheck(cudaMalloc(&pSubPixelY,size));
  printf("4\n");

  int bdimX = min(1024,data->count);
  dim3 bdim(bdimX);
  dim3 gdim((data->count/bdimX) + 1);
  printf("5\n");
  SubPixelAlignKernel<<<gdim,bdim>>>(Ix->pixels->devicePtr,Iy->pixels->devicePtr,Ixx->pixels->devicePtr,Ixy->pixels->devicePtr,Iyy->pixels->devicePtr,pIdx,pSubPixelX,pSubPixelY,oSize,data->count);
  Ix->free(Ix);
  Iy->free(Iy);
  Ixx->free(Ixx);
  Ixy->free(Ixy);
  Iyy->free(Iyy);
  printf("6\n");
  data->subPixelX = (float*)malloc(size);
  data->subPixelY = (float*)malloc(size);
  cudaErrCheck(cudaMemcpy(data->subPixelX,pSubPixelX,size,cudaMemcpyDeviceToHost));
  cudaErrCheck(cudaMemcpy(data->subPixelY,pSubPixelY,size,cudaMemcpyDeviceToHost));
  printf("7\n");
}

void eliminatePointsBelowThresholdImpl(ImageUtil* self, ImageIndexPair* keypoints, float* threshold)
{
  printf("ELIM BELOW THRESHOLD\n");
  float thresh;
  if (threshold == NULL)
  {
    thresh = 0.1;
  } else {
    thresh = *threshold;
  }
  printf("1\n");
  int* d_keepCount;
  int* d_keepIndex;
  float* d_keepSubPixelX;
  float* d_keepSubPixelY;

  cudaErrCheck(cudaMalloc(&d_keepIndex,sizeof(int)*keypoints->count));
  cudaErrCheck(cudaMalloc(&d_keepSubPixelX,sizeof(float)*keypoints->count));
  cudaErrCheck(cudaMalloc(&d_keepSubPixelY,sizeof(float)*keypoints->count));
  cudaErrCheck(cudaMalloc(&d_keepCount,sizeof(int)));
  cudaErrCheck(cudaMemset(d_keepCount,0,sizeof(int)));
  printf("2\n");

  NppiSize oSize = {keypoints->image->shape.height,keypoints->image->shape.width};

  if (keypoints->image->pixels->isHostSide)
  {
    copyHostToDeviceCudaMatrix(keypoints->image->pixels);
  }

  int blockDimX = fmin(1024,keypoints->count);
  dim3 bdim(blockDimX);
  dim3 gdim(keypoints->count/blockDimX + 1);
  printf("bdim: (%i,%i) gdim: (%i,%i) N: %i\n",bdim.x,bdim.y,gdim.x,gdim.y,keypoints->count);
  printf("imshape: (%i,%i)\n",keypoints->image->shape.height,keypoints->image->shape.width);
  printf("isNull: %i\n",keypoints->index==NULL);
  EliminatePointsBelowThresholdKernel<<<gdim,bdim,sizeof(int)*keypoints->count+1>>>(keypoints->image->pixels->devicePtr,oSize,keypoints->subPixelX,keypoints->subPixelY,keypoints->index,keypoints->count,d_keepSubPixelX,d_keepSubPixelY,d_keepIndex,d_keepCount,thresh);
  cudaDeviceSynchronize();
  cudaErrCheck(cudaGetLastError());
  printf("3\n");
  int* h_keepCount = (int*)malloc(sizeof(int));
  cudaErrCheck(cudaMemcpy(h_keepCount,d_keepCount,sizeof(int),cudaMemcpyDeviceToHost));
  int keepCount = *h_keepCount;
  printf("h_keepCount = %i\n",keepCount);
  cudaErrCheck(cudaFree(&d_keepIndex[keepCount]));
  cudaErrCheck(cudaFree(&d_keepSubPixelX[keepCount]));
  cudaErrCheck(cudaFree(&d_keepSubPixelY[keepCount]));
  printf("4\n");

  keypoints->count = keepCount;
  keypoints->index = d_keepIndex;
  keypoints->subPixelX = d_keepSubPixelX;
  keypoints->subPixelY = d_keepSubPixelY;
}

void eliminateEdgePointsImpl(ImageUtil* self, ImageIndexPair* keypoints, float* threshold)
{
  float thresh;
  if (threshold == NULL)
  {
    thresh = 0.1;
  } else {
    thresh = *threshold;
  }

  Image* Ix = self->gradientX(self,keypoints->image);
  Image* Iy = self->gradientY(self,keypoints->image);

  int* d_keepCount;
  int* d_keepIndex;
  float* d_keepSubPixelX;
  float* d_keepSubPixelY;
  cudaErrCheck(cudaMalloc(&d_keepCount,sizeof(int)));
  cudaErrCheck(cudaMalloc(&d_keepIndex,sizeof(int)*keypoints->count));
  cudaErrCheck(cudaMalloc(&d_keepSubPixelX,sizeof(float)*keypoints->count));
  cudaErrCheck(cudaMalloc(&d_keepSubPixelY,sizeof(float)*keypoints->count));

  NppiSize oSize = {keypoints->image->shape.height,keypoints->image->shape.width};

  if (keypoints->image->pixels->isHostSide)
  {
    copyHostToDeviceCudaMatrix(keypoints->image->pixels);
  }

  if (Ix->pixels->isHostSide)
  {
    copyHostToDeviceCudaMatrix(Ix->pixels);
  }

  if (Iy->pixels->isHostSide)
  {
    copyHostToDeviceCudaMatrix(Iy->pixels);
  }

  int blockDimX = fmin(1024,keypoints->count);

  dim3 bdim(blockDimX);
  dim3 gdim(keypoints->count/blockDimX + 1);
  EliminateEdgePointsKernel<<<gdim,bdim>>>(keypoints->image->pixels->devicePtr,oSize,keypoints->subPixelX,keypoints->subPixelY,keypoints->index,keypoints->count,Ix->pixels->devicePtr,Iy->pixels->devicePtr,d_keepSubPixelX,d_keepSubPixelY,d_keepIndex,d_keepCount,thresh);
  Ix->free(Ix);
  Iy->free(Iy);
  int* h_keepCount = (int*)malloc(sizeof(int));
  cudaErrCheck(cudaMemcpy(h_keepCount,d_keepCount,sizeof(int),cudaMemcpyDeviceToHost));
  int keepCount = h_keepCount[0];
  cudaErrCheck(cudaFree(&d_keepIndex[keepCount]));
  cudaErrCheck(cudaFree(&d_keepSubPixelX[keepCount]));
  cudaErrCheck(cudaFree(&d_keepSubPixelY[keepCount]));

  keypoints->count = keepCount;
  keypoints->index = d_keepIndex;
  keypoints->subPixelX = d_keepSubPixelX;
  keypoints->subPixelY = d_keepSubPixelY;
}


Matrix** makeFeatureDescriptorsForImageIndexPairImpl(ImageUtil* self, ImageIndexPair* keypoints, Image* im, int featureWidth)
{
  float* d_features;
  float* d_subPixelX;
  float* d_subPixelY;
  cudaErrCheck(cudaMalloc(&d_features,sizeof(float)*featureWidth*featureWidth*keypoints->count));
  cudaErrCheck(cudaMalloc(&d_subPixelY,sizeof(float)*keypoints->count));
  cudaErrCheck(cudaMalloc(&d_subPixelX,sizeof(float)*keypoints->count));
  cudaMemcpy(d_subPixelX,keypoints->subPixelX,sizeof(float)*keypoints->count,cudaMemcpyHostToDevice);
  cudaMemcpy(d_subPixelY,keypoints->subPixelY,sizeof(float)*keypoints->count,cudaMemcpyHostToDevice);

  NppiSize oSize = {im->shape.height,im->shape.width};

  int bdimX = min(1024,keypoints->count);
  dim3 bdim(bdimX);
  dim3 gdim((keypoints->count/bdimX) + 1);
  MakeFeatureDescriptorKernel<<<gdim, bdim>>>(im->pixels->devicePtr,oSize,d_subPixelX,d_subPixelY,keypoints->count,d_features,featureWidth);
  Matrix** retval = (Matrix**)malloc(sizeof(Matrix*)*keypoints->count);
  for (int i = 0; i < keypoints->count; i++)
  {
    float* h_feature = (float*)malloc(sizeof(float)*featureWidth*featureWidth);
    cudaErrCheck(cudaMemcpy(h_feature,&d_features[i*featureWidth*featureWidth],sizeof(float)*featureWidth*featureWidth,cudaMemcpyDeviceToHost));
    Shape shape = {featureWidth,featureWidth};
    Matrix* m = self->matutil->newMatrix(h_feature,shape);
    retval[i] = m;
  }
  cudaErrCheck(cudaFree(d_subPixelX));
  cudaErrCheck(cudaFree(d_subPixelY));
  cudaErrCheck(cudaFree(d_features));
  return retval;
}

Matrix* generalizeFeatureMatrixImpl(ImageUtil* self, Matrix* features, int nBins)
{
  if (features->isHostSide)
  {
    copyHostToDeviceCudaMatrix(features);
  }
  int nFeatureWidth = (int)sqrt(features->shape.width);
  Shape shape = {nBins*nFeatureWidth,features->shape.height};
  Matrix* genFeatures = self->matutil->newEmptyMatrix(shape);
  copyHostToDeviceCudaMatrix(genFeatures);
  int bdimX = 16;
  int bdimY = fmin(64,features->shape.height);
  dim3 bdim(bdimX,bdimY);
  dim3 gdim(1,features->shape.height/bdimY + 1);
  GeneralizeFeatureKernel<<<gdim,bdim>>>(features->devicePtr,genFeatures->devicePtr,features->shape.height,features->shape.width,16,nBins);
  return genFeatures;
}

void unorientFeatureMatrixImpl(ImageUtil* self, Matrix* features, int nBins)
{
  if (features->isHostSide)
  {
    copyHostToDeviceCudaMatrix(features);
  }
  int bdimX = fmin(1024,features->shape.height);
  dim3 bdim(bdimX);
  dim3 gdim(features->shape.height/bdimX + 1);
  UnorientFeatureKernel<<<gdim,bdim,sizeof(float)*nBins>>>(features->devicePtr,features->shape.height,features->shape.width,nBins);
}

//########
// END CV
//########


DLLEXPORT ImageUtil* GetImageUtil(MatrixUtil* matutil)
{
  ImageUtil* self = (ImageUtil*)malloc(sizeof(ImageUtil));

  self->matutil = matutil;
  self->newEmptyImage = newEmptyImageImpl;
  self->newImage = newImageImpl;
  self->newImageFromMatrix = newImageFromMatrixImpl;
  self->resample = resampleImageImpl;
  self->add = addImageImpl;
  self->subtract = subtractImageImpl;
  self->multiply = multiplyImageImpl;
  self->multiplyC = multiplyCImageImpl;
  self->max = maxImageImpl;
  self->maxIdx = maxIdxImageImpl;
  self->localContrast = localContrastImageImpl;
  self->gradientX = gradientXImageImpl;
  self->gradientY = gradientYImageImpl;
  self->gradientMagnitude = gradientMagnitudeImageImpl;
  self->gradientAngle = gradientAngleImageImpl;
  self->gradients = gradientsImageImpl;
  self->convolve = convolveImageImpl;
  self->subPixelAlignImageIndexPair = subPixelAlignImageIndexPairImpl;
  self->makeFeatureDescriptorsForImageIndexPair = makeFeatureDescriptorsForImageIndexPairImpl;
  self->unorientFeatureMatrix = unorientFeatureMatrixImpl;
  self->generalizeFeatureMatrix = generalizeFeatureMatrixImpl;
  self->eliminatePointsBelowThreshold = eliminatePointsBelowThresholdImpl;
  self->eliminateEdgePoints = eliminateEdgePointsImpl;

  return self;
}

#ifdef __cplusplus
  }
#endif
