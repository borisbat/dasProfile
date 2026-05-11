// Companion module for testProfile that carries AOT stubs for tests/*.das.
// Loaded alongside testProfile.shared_module via .das_module so the AOT
// generated .cpp files' AotListBase static initializers fire on dlopen.

#include "daScript/daScript.h"

using namespace das;

class Module_TestProfileAot : public Module {
public:
    Module_TestProfileAot() : Module("testProfileAot") {}
};

REGISTER_DYN_MODULE(Module_TestProfileAot, testProfileAot);
