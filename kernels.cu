#include <iostream>
#include <cuda.h>
#include <curand_kernel.h>
using namespace std;

__global__ void do_fire(unsigned int *pData,curandState *state,float *firesrc,float *firedest);
__global__ void setup_kernel(curandState *state);
curandState *devStates;

float *firebuff[2];
int flipstate;

int init_cuda(){

	cudaMalloc((void **)&firebuff[0], 600 * 800 *
	                  sizeof(float));

	cudaMalloc((void **)&firebuff[1], 600 * 800 *
	                  sizeof(float));

	cudaMalloc((void **)&devStates, 600 * 800 *
	                  sizeof(curandState));
	setup_kernel<<<600,800>>>(devStates);

	flipstate=0;
	return 0;
}

int run_fire(unsigned int *pData){
	if(flipstate){
		do_fire<<<600,800>>>(pData,devStates,firebuff[0],firebuff[1]);
		flipstate = 0;
	} else {
		do_fire<<<600,800>>>(pData,devStates,firebuff[1],firebuff[0]);
		flipstate = 1;
	}
	return 0;
}

__global__ void setup_kernel(curandState *state)
{
    int id = threadIdx.x + blockIdx.x * 64;
    /* Each thread gets same seed, a different sequence
       number, no offset */
    curand_init(1234, id, 0, &state[id]);
}

__global__ void do_fire(unsigned int *pData,curandState *state,float *firesrc,float *firedest){
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
		firedest[idx] = rand;
	__syncthreads();


	if(thread_y < 600-1){
		float avg[4];
		if((thread_x-1) >= 0)avg[1] = firesrc[(thread_y+1)*maxwidth + thread_x-1];
		avg[2] = firesrc[(thread_y+1)*maxwidth + thread_x];
		if((thread_x+1) < 800)avg[3] = firesrc[(thread_y+1)*maxwidth + thread_x+1];

		avg[0] = (avg[1] + avg[2] + avg[3])/3;

		firedest[thread_y*maxwidth + thread_x] = avg[0];
	}

	pData[idx] = (((int)firedest[idx])&0xFF) << 16;

	return;
}
