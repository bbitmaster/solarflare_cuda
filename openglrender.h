/*
 * openglrender.h
 *
 *  Created on: Oct 27, 2012
 *      Author: ben
 */

#ifndef OPENGLRENDER_H_
#define OPENGLRENDER_H_

#define GL_GLEXT_PROTOTYPES
#include <GL/gl.h>

#include <SDL/SDL.h>
#include <SDL/SDL_opengl.h>

#define SCREEN_WIDTH 800
#define SCREEN_HEIGHT 600
#define SCREEN_BPP 32

class Application{
private:
    GLuint bufferID;
    GLuint textureID;
public:
	bool init();
	bool initGL();
	int gameLoop();
	void update();
	void render();
};



#endif /* OPENGLRENDER_H_ */
