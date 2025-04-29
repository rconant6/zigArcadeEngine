#ifndef WINDOWBRIDGE_H
#define WINDOWBRIDGE_H

typedef unsigned char wbBool;
typedef unsigned int wbWindowID;
typedef unsigned char uint8;
typedef signed int int32;

typedef struct {
  float width;
  float height;
  const char *title;
} wbWindowConfig;

typedef struct {
  float r;
  float g;
  float b;
  float a;
} Color;

#ifdef __cplusplus
extern "C" {
#endif

// Initialize the application
wbBool wb_initApplication(void);

// Create a window w/ the specs provided
wbWindowID wb_createWindow(wbWindowConfig config);

// Destroy the window on cleanup
void wb_destroyWindow(wbWindowID id);

// Check if window should close (not sure why this is needed)
wbBool wb_shouldWindowClose(wbWindowID id);

// Process application events
void wb_processEvents(void);

// Pass buffer data for drawing
void wb_updateWindowPixels(wbWindowID id, const uint8 *pixels, int32 width,
                           int32 height);

#ifdef __cplusplus
}
#endif
#endif // WINDOWBRIDGE_H
