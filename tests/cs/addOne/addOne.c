#if defined(_WIN32)
#define ADDONE_EXPORT __declspec(dllexport)
#else
#define ADDONE_EXPORT __attribute__((visibility("default")))
#endif

ADDONE_EXPORT int AddOne(int a) {
    return a + 1;
}

ADDONE_EXPORT int addOne(int a) {
    return AddOne(a);
}
