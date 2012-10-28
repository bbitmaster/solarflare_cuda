#include <iostream>
#include <cuda.h>
#include <curand_kernel.h>
using namespace std;

__global__ void do_fire(unsigned int *pData,curandState *state,float *firebuff[2]);
__global__ void setup_kernel(curandState *state);
curandState *devStates;

float *firebuff[2];

int init_cuda(){

	cudaMalloc((void **)&firebuff[1], 600 * 800 *
	                  sizeof(float));

	cudaMalloc((void **)&firebuff[2], 600 * 800 *
	                  sizeof(float));

	cudaMalloc((void **)&devStates, 600 * 800 *
	                  sizeof(curandState));
	setup_kernel<<<600,800>>>(devStates);

	return 0;
}

int run_fire(unsigned int *pData){
	do_fire<<<600,800>>>(pData,devStates,firebuff);
	return 0;
}

__global__ void setup_kernel(curandState *state)
{
    int id = threadIdx.x + blockIdx.x * 64;
    /* Each thread gets same seed, a different sequence
       number, no offset */
    curand_init(1234, id, 0, &state[id]);
}

__global__ void do_fire(unsigned int *pData,curandState *state,float *firebuff[2]){
	int idx = blockIdx.x * blockDim.x + threadIdx.x;
	int thread_y = blockIdx.x;
	int thread_x = threadIdx.x;
	int maxwidth = blockDim.x;

	curandState localState = state[idx];
	//pData[idx] = ((blockIdx.x&0xff) << 8) + threadIdx.x;

	int rand = curand_uniform(&localState)*256;
	rand &= 0xFF;
	state[idx] = localState;

	if(thread_y >= 600-1)
		pData[idx] = (rand << 16);
	__syncthreads();

	if(thread_y < 600-1){
		pData[thread_y*maxwidth + thread_x] = pData[(thread_y+1)*maxwidth + thread_x];
	}

	return;
}
