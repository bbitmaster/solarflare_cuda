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