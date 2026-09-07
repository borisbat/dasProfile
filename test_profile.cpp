#include "daScript/misc/platform.h"

#include "test_profile.h"

#include "daScript/daScript.h"

using namespace das;

___noinline int AddOne(int a) {
    return a+1;
}

___noinline float ParseFloat(const char * s) {
    return s ? strtof(s, nullptr) : 0.0f;
}

class Module_TestProfile : public Module {
public:
    Module_TestProfile() : Module("testProfile") {
        ModuleLibrary lib(this);
        lib.addBuiltInModule();
        addExternInline<DAS_BIND_FUN(AddOne)>(*this,lib,"AddOne",SideEffects::none, "AddOne");
        addExtern<DAS_BIND_FUN(AddOne)>(*this,lib,"AddOneMember",SideEffects::none, "AddOne");
        addExternInline<DAS_BIND_FUN(ParseFloat)>(*this,lib,"ParseFloatInline",SideEffects::none, "ParseFloat");
        addExtern<DAS_BIND_FUN(ParseFloat)>(*this,lib,"ParseFloatMember",SideEffects::none, "ParseFloat");
        verifyAotReady();
    }
    virtual ModuleAotType aotRequire ( TextWriter & tw ) const override {
        tw << "#include \"test_profile.h\"\n";
        return ModuleAotType::cpp;
    }
};

REGISTER_MODULE(Module_TestProfile);
REGISTER_DYN_MODULE(Module_TestProfile, testProfile);
