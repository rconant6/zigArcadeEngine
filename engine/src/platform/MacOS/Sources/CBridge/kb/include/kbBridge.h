#ifndef KEYBOARDBRIDGE_H
#define KEYBOARDBRIDGE_H

#include <stdint.h>
#define MAX_KB_EVENTS_PER_FRAME 8

typedef unsigned char kbKeyCode;
typedef unsigned char kbBool;
typedef unsigned long long kbTime;
typedef unsigned char u8;
typedef int32_t i32;

typedef enum {
  KB_KEY_PRESS,
  KB_KEY_RELEASE,
} kbEventType;

typedef struct {
  kbEventType eventType;
  kbTime timestamp;

  kbKeyCode code;

  u8 modifiers;
} kbKeyEvent;

typedef struct {
  kbKeyEvent events[MAX_KB_EVENTS_PER_FRAME];
  i32 eventCount;
  kbBool overflow;
} kbEventBatch;

#ifdef __cplusplus
extern "C" {
#endif

kbBool kb_startKeyboardMonitoring(void);
void kb_stopKeyboardMonitoring(void);
kbBool kb_pollKeyboardEventBatch(kbEventBatch *outBatch);

#ifdef __cplusplus
}
#endif

#endif // KEYBOARDBRIDGE_H
