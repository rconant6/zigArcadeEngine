#ifndef WINDOWBRIDGE_H
#define WINDOWBRIDGE_H

typedef unsigned char wbBool;
typedef unsigned int wbWindowID;

typedef struct {
  float width;
  float height;
  const char *title;
} wbWindowConfig;

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

// Make the window visible
unsigned short wb_makeApplicationVisible();

#ifdef __cplusplus
}
#endif
#endif // WINDOWBRIDGE_H
