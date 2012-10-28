#note: I am using fedora 17 with CUDA 5.0 installed. This makefile
#contains some things specific to *my* setup on this system.
#Namely, I had to install GCC 4.6.3 from source since CUDA does not
#work with GCC 4.7 and fedora now uses GCC 4.7 
#I add /home/ben/cudapath/ to my path which contains softlinks to
#gcc 4.6.3 so that CUDA sees that version.
#
#Another thing that may be different on another system, is cuda could be
#installed elsewhere. On my system I have it at /usr/local/cuda-5.0
#
#please edit appropriately
NVCC=nvcc

#CXX=clang++
CXX=g++
#CXX=icpc
#PATH=/opt/intel/bin:/usr/local/gcc46/bin:/usr/local/bin:/usr/bin
LIB := -lGL -lGLU -lcudart `sdl-config --cflags --libs`
PATH := /home/ben/cudapath/:${PATH}

INCPATH := -I/usr/local/cuda-5.0/include/
LIB += -L/usr/local/cuda-5.0/lib64/

all: openglrender

openglrender.o: openglrender.cpp
	$(CXX) -O3 -c openglrender.cpp $(INCPATH)

kernels.o: kernels.cu kernels.h
	$(NVCC) -O3 -c kernels.cu $(INCPATH)
	
openglrender: openglrender.o kernels.o
	$(CXX) -O3 -o openglrender openglrender.o kernels.o $(LIB) $(INCPATH)
	
clean:
	rm *.o
	rm openglrender
