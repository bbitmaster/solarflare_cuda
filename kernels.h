/*
 * kernels.h
 *
 *  Created on: Oct 27, 2012
 *      Author: ben
 */

#ifndef KERNELS_H_
#define KERNELS_H_

#define SCREEN_WIDTH 800
#define SCREEN_HEIGHT 600
#define SCREEN_BPP 32

int init_cuda();
int run_fire(unsigned int *pData);



#endif /* KERNELS_H_ */
