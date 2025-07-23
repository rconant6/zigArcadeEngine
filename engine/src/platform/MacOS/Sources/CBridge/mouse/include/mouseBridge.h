#ifndef MOUSEBRIDGE_H
#define MOUSEBRIDGE_H

#include <stdint.h>
#define MAX_MOUSE_EVENTS_PER_FRAME 8

typedef unsigned long long mTime;
typedef unsigned char mBool;
typedef int32_t i32;

typedef enum {
  M_BUTTON_PRESS,
  M_BUTTON_RELEASE,
  M_MOVE,
  M_SCROLL,
  M_ENTER_WINDOW,
  M_EXIT_WINDOW,
} mEventType;

typedef enum {
  M_BUTTON_LEFT,
  M_BUTTON_RIGHT,
  M_BUTTON_MIDDLE,
  M_BUTTON_EXTRA1,
  M_BUTTON_EXTRA2,
  M_BUTTON_NIL,
} mButton;

typedef struct {
  mEventType eventType;
  mTime timestamp;

  float windowX, windowY;
  float gameX, gameY;

  float deltaX, deltaY;
  float scrollDeltaX, scrollDeltaY;

  mButton button;
  mBool isPressed;

} mMouseEvent;

typedef struct {
  mMouseEvent events[MAX_MOUSE_EVENTS_PER_FRAME];
  i32 eventCount;
  mBool overflow;
} mMouseEventBatch;

#ifdef __cplusplus
extern "C" {

#endif
// @MainActor required
mBool m_startMouseMonitoring(void);
void m_stopMouseMonitoring(void);
mBool m_pollMouseEventBatch(mMouseEventBatch *outBatch);

void m_setWindowDimensions(i32 width, i32 height);

#ifdef __cplusplus
}
#endif

#endif // MOUSEBRIDGE_H
