#include <iostream>
#include <cuda.h>
#include <curand_kernel.h>
#include "kernels.h"
using namespace std;

__global__ void init_fire(curandState *state,float *firesrc,float *firedest);
__global__ void do_fire(unsigned int *pData,curandState *state,float *firesrc,float *firedest);

__global__ void setup_kernel(curandState *state);
curandState *devStates;

float *firebuff[2];
int flipstate;

int init_cuda(){

	cudaMalloc((void **)&firebuff[0], SCREEN_HEIGHT * SCREEN_WIDTH *
	                  sizeof(float));

	cudaMalloc((void **)&firebuff[1], SCREEN_HEIGHT * SCREEN_WIDTH *
	                  sizeof(float));

	//cudaMemset(firebuff[0],0, SCREEN_HEIGHT * SCREEN_WIDTH *
	//                  sizeof(float));

	//cudaMemset(firebuff[1],0, SCREEN_HEIGHT * SCREEN_WIDTH *
	//                  sizeof(float));

	cudaMalloc((void **)&devStates, SCREEN_HEIGHT * SCREEN_WIDTH *
	                  sizeof(curandState));

	setup_kernel<<<SCREEN_HEIGHT,SCREEN_WIDTH>>>(devStates);

	init_fire<<<SCREEN_HEIGHT,SCREEN_WIDTH>>>(devStates,firebuff[0],firebuff[1]);

	flipstate=0;
	return 0;
}

int run_fire(unsigned int *pData){
	if(flipstate){
		do_fire<<<SCREEN_HEIGHT,SCREEN_WIDTH>>>(pData,devStates,firebuff[0],firebuff[1]);
		flipstate = 0;
	} else {
		do_fire<<<SCREEN_HEIGHT,SCREEN_WIDTH>>>(pData,devStates,firebuff[1],firebuff[0]);
		flipstate = 1;
	}
	return 0;
}

__global__ void setup_kernel(curandState *state)
{
    int id = blockIdx.x * blockDim.x + threadIdx.x;
    /* Each thread gets same seed, a different sequence
       number, no offset */
    curand_init(1234, id, 0, &state[id]);
}

__global__ void init_fire(curandState *state,float *firesrc,float *firedest){
	int id = blockIdx.x * blockDim.x + threadIdx.x;
	curandState localState = state[id];
	unsigned int rand = curand(&localState);

    firesrc[id] = rand%128;
    firedest[id] = rand%128;
    state[id] = localState;
}

__global__ void do_fire(unsigned int *pData,curandState *state,float *firesrc,float *firedest){
	int idx = blockIdx.x * blockDim.x + threadIdx.x;
	int thread_y = blockIdx.x;
	int thread_x = threadIdx.x;
	int maxwidth = blockDim.x;

	int maxheight = SCREEN_HEIGHT;

	curandState localState = state[idx];
	unsigned int rand = curand(&localState);
	state[idx] = localState;

	if(thread_y >= maxheight-1)
		firedest[idx] = rand&0xFF;
	__syncthreads();


	if(thread_y < maxheight-1){
		float avg[4];
		if((thread_x-1) >= 0)avg[1] = firesrc[(thread_y)*maxwidth + (thread_x-1)];
		avg[2] = firesrc[(thread_y+1)*maxwidth + thread_x];
		if((thread_x+1) < maxwidth)avg[3] = firesrc[(thread_y)*maxwidth + (thread_x+1)];

		avg[0] = (avg[1] + avg[2] + avg[3])/3;
		int rndcap = (avg[0]*0.035);//(4/138));
		rndcap += 1;

		if(avg[0] > 5.0)
			avg[0] += rand%rndcap;
		avg[0] -= 2.0;

		//avg[0] += rand%5;

		if(avg[0] > 255)avg[0] = 255;
		else if(avg[0] > 250)avg[0] = 0;

		if(avg[0] < 0)avg[0] = 255;
		firedest[thread_y*maxwidth + thread_x] = avg[0];
	}
	pData[idx] = ((int)firedest[idx]) << 16;

	return;
}
