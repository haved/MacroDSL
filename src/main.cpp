#include <stdio.h>

#ifdef __EMSCRIPTEN__
#include <emscripten.h>
#endif

int main(int argc, char** argv) {
  printf("hello, world!\n");
  return 0;
}
