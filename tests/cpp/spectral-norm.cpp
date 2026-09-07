#include "profile.h"
#include <cmath>
#include <cstdlib>

namespace {

inline int A(int i, int j) { return ((i + j) * (i + j + 1) / 2 + i + 1); }

double dot(const double * v, const double * u, int n) {
    double sum = 0;
    for (int i = 0; i < n; i++) sum += v[i] * u[i];
    return sum;
}

void mult_Av(const double * v, double * out, int n) {
    for (int i = 0; i < n; i++) {
        double sum = 0;
        for (int j = 0; j < n; j++) sum += v[j] / A(i, j);
        out[i] = sum;
    }
}

void mult_Atv(const double * v, double * out, int n) {
    for (int i = 0; i < n; i++) {
        double sum = 0;
        for (int j = 0; j < n; j++) sum += v[j] / A(j, i);
        out[i] = sum;
    }
}

double * tmp;
void mult_AtAv(const double * v, double * out, int n) {
    mult_Av(v, tmp, n);
    mult_Atv(tmp, out, n);
}

}  // namespace

static volatile int rounds = 2;

PROFILE_NOINLINE double testSnorm(int iterations) {
    const int n = 500;
    double * u = (double *) malloc(n * sizeof(double));
    double * v = (double *) malloc(n * sizeof(double));
    tmp = (double *) malloc(n * sizeof(double));
    for (int i = 0; i < n; i++) u[i] = 1;
    for (int i = 0; i < iterations; i++) {
        mult_AtAv(u, v, n);
        mult_AtAv(v, u, n);
    }
    double result = sqrt(dot(u, v, n) / dot(v, v, n));
    free(u); free(v); free(tmp);
    return result;
}

int main() {
    double result = 0;
    profile::run("spectral norm", [&] { result = testSnorm(rounds); profile::keep(result); });
    if (fabs(result - 1.274224153) >= 1e-5) profile::fail("spectral norm: wrong result");
    return 0;
}
