#include "any_odd_one.h"

int any_odd_one(uint32_t x) { return !!(x & 0xAAAAAAAAu); }
