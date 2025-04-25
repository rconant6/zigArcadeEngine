#ifndef KEYBOARDBRIDGE_H
#define KEYBOARDBRIDGE_H

typedef unsigned char kbKeyCode;
typedef unsigned char kbBool;
typedef unsigned long long kbTime;

typedef struct {
  kbKeyCode code;
  kbBool isPressed;
  kbTime timestamp;
} kbKeyEvent;

#ifdef __cplusplus
extern "C" {
#endif

// Start monitoring keyboard events
kbBool kb_startKeyboardMonitoring(void);

// Stop monitoring keyboard events
void kb_stopKeyboardMonitoring(void);

// Poll for next keyboard event (returns 1 if event available, 0 if none)
kbBool kb_pollKeyboardEvent(kbKeyEvent *outEvent);

// Check if a specific key is currently pressed
kbBool kb_isKeyPressed(kbKeyCode keyCode);
#ifdef __cplusplus
}
#endif

#endif // KEYBOARDBRIDGE_H
