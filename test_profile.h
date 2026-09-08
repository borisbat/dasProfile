#pragma once

#include "daScript/simulate/simulate.h"
#include "daScript/simulate/aot.h"

// the interop module: the two C++ callees the das tests call across the binding, each bound
// both ways (NTTP inline and member) so tests/_abtest.das can measure the flavor delta
DAS_MOD_API int AddOne(int a);
DAS_MOD_API float ParseFloat(const char * s);
