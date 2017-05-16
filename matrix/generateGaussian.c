#include <matrix.h>

int generateGaussian(Matrix *a, Shape shape, float w, float h)
{

  float *g = (float*)malloc(sizeof(float)*shape.width*shape.height);
  int w_radius = w/2;
  int h_radius = h/2;
  for (int y = 0; y < shape.height; y++)
  {
    for (int x = 0; x < shape.width; x++)
    {
      Point2 p = {x,y};
      g[IDX2C(p,shape)] = sqrt(1.0/(2.0*M_PI))*exp(-1.0*(pow(x-w_radius,2.0)/(2*(w*w)) + pow(y-h_radius,2.0)/(2*(h*h))));
    }
  }
  new_host_matrix(&a,g,shape);
  memassert(a,DEVICE);
  return 0;
}
