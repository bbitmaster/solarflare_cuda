/*
 * openglrender.cpp
 *
 *  Created on: Oct 27, 2012
 *      Author: Ben
 */

//This is the craziest include list I have seen.
//see: http://stackoverflow.com/questions/7532110/vertex-buffer-objects-with-sdl


#include "openglrender.h"
#include "kernels.h"

#include <iostream>
#include <cstdlib>

#include <cuda_gl_interop.h>
#include <cuda.h>

using namespace std;


int main(int argc,char *argv[]){
	Application app;

	if(!app.init()){
		cout << "Initialization Error" << endl;
	}

	app.gameLoop();
}


bool Application::init()
{
    //Initialize SDL
    if( SDL_Init( SDL_INIT_EVERYTHING ) < 0 )
    {
        return false;
    }

    atexit(SDL_Quit);

    //Create Window
    if( SDL_SetVideoMode( SCREEN_WIDTH, SCREEN_HEIGHT, SCREEN_BPP, SDL_OPENGL ) == NULL )
    {
        return false;
    }

    //Initialize OpenGL
    if( initGL() == false )
    {
        return false;
    }
    init_cuda();
    //Set caption
    SDL_WM_SetCaption( "OpenGL Test", NULL );

    return true;
}


bool Application::initGL()
{

	// Set up which portion of the
	// window is being used
	glViewport(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);

	// Just set up an orthogonal system
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();

	glOrtho(0,1.0f,0,1.0f,0.0f,1.0f);
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();

	glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	glDisable(GL_DEPTH_TEST);

	cudaGLSetGLDevice(0);

    //Check for error
    GLenum error = glGetError();
    if( error != GL_NO_ERROR )
    {
        printf( "Error initializing OpenGL! %s\n", gluErrorString( error ) );
        return false;
    }

    glGenBuffers(1,&bufferID);

    glBindBuffer(GL_PIXEL_UNPACK_BUFFER,bufferID);

    glBufferData(GL_PIXEL_UNPACK_BUFFER,SCREEN_WIDTH * SCREEN_HEIGHT * 4,NULL,GL_DYNAMIC_COPY);

    cudaGLRegisterBufferObject(bufferID);

    glEnable(GL_TEXTURE_2D);

    glGenTextures(1,&textureID);

    glBindTexture(GL_TEXTURE_2D,textureID);

    glTexImage2D(GL_TEXTURE_2D,0,GL_RGBA8,SCREEN_WIDTH,SCREEN_HEIGHT,0,GL_BGRA,GL_UNSIGNED_BYTE,NULL);

    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);

    return true;
}

int Application::gameLoop(){
	SDL_Event event;
	bool quit=false;

	while(!quit){
		//While there are events to handle
		while( SDL_PollEvent( &event ) )
		{
			if( event.type == SDL_QUIT )
			{
				quit = true;
			}
			else if( event.type == SDL_KEYDOWN )
			{
				cout << "keypress..." << endl;
				quit = true;
			}
		}

		//Run frame update
		update();

		//Render frame
		render();
		//cout << "test..." << endl;
		//TODO: fix
		//SDL_Delay(16);
	}

	return 0;
}

void Application::update()
{

}

void Application::render()
{
    //Clear color buffer
    //glClear( GL_COLOR_BUFFER_BIT );

	/*
	glBindBuffer(GL_PIXEL_PACK_BUFFER,bufferID);
	glReadPixels(0,0,SCREEN_WIDTH, SCREEN_HEIGHT, GL_BGRA,GL_UNSIGNED_BYTE, 0);
	GLuint* pixels = (GLuint*) glMapBuffer( GL_PIXEL_PACK_BUFFER, GL_READ_WRITE);

	int x, y;

	for( x = 0; x <800; x++){
		y = 599;
			//pixels[x + y*SCREEN_WIDTH] = rand()&0x00ffffff;
			pixels[x + y*SCREEN_WIDTH] = rand()&0x00ff0000;
	}

	for( x = 1; x <799; x++)
		for(y = 0; y < 599;y++){
		{
			int r1 = (pixels[(x-1) + (y+1)*SCREEN_WIDTH] >> 16) & 0xFF;
			int r2 = (pixels[(x) + (y+1)*SCREEN_WIDTH] >> 16) & 0xFF;
			int r3 = (pixels[(x+1) + (y+1)*SCREEN_WIDTH] >> 16) & 0xFF;
			pixels[x + y*SCREEN_WIDTH] = ((r1+r2+r3 + (rand()%10 - 3))/3)<<16;
		}
	}

	glUnmapBuffer(GL_PIXEL_PACK_BUFFER);
	glBindBuffer(GL_PIXEL_PACK_BUFFER, 0); // unbind the PBO

	*/
	unsigned int *pData;
	cudaGLMapBufferObject((void **)&pData, bufferID);
	run_fire(pData);
	cudaGLUnmapBufferObject(bufferID);

	glBindBuffer(GL_PIXEL_UNPACK_BUFFER,bufferID);
	glBindTexture(GL_TEXTURE_2D,textureID);
	glTexSubImage2D(GL_TEXTURE_2D,0,0,0,SCREEN_WIDTH,SCREEN_HEIGHT,GL_BGRA,GL_UNSIGNED_BYTE,NULL);

    glBegin(GL_QUADS);
		glTexCoord2f( 0, 1); glVertex3f(0, 0, 0);
		glTexCoord2f( 0, 0); glVertex3f(0, 1, 0);
		glTexCoord2f( 1, 0); glVertex3f(1, 1, 0);
		glTexCoord2f( 1, 1); glVertex3f(1, 0, 0);
    glEnd();


    //Update screen
    SDL_GL_SwapBuffers();
}
