import numpy as np

def gen_twiddle(N, width=16):
    twiddle = []
    
    for i in range(0,N):
        twiddle_complex = np.exp(-(2j*np.pi*i)/N)
        twiddle_complex_scaled = twiddle_complex * 2**(width-1)
        twiddle.append(int(np.real(twiddle_complex_scaled)) + 1j*int(np.imag(twiddle_complex_scaled)))
    
    for i in range(0, len(twiddle)):
        x = twiddle[i]
        print("{{1'b" + str(1 if np.real(x) < 0 else 0) + ", "+ ("-" if np.real(x) < 0 else "") + str(width) + "'d" + str(np.abs(int(np.round(np.real(x))))) + "},\t{1'b" + str(1 if np.imag(x) < 0 else 0) + ", " + ("-" if np.imag(x) < 0 else "") + str(width) + "'d" + str(np.abs(int(np.round(np.imag(x))))) + "}}", end="")
        if i != len(twiddle)-1:
            print(",", end="")
        print ("\t// W" + str(i), end="")
        print()

    return twiddle

gen_twiddle(64, width=12)