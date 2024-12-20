import numpy as np

N = 256

def print_hex(x):
    return "" + str(hex(np.uint16(np.real(x)).astype(np.uint16) & 0XFFF)) + " " + str(hex(np.uint16(np.imag(x)).astype(np.uint16) & 0XFFF))

# generate random time-domain signal
np.random.seed(1)
signal = np.random.randint(0, 4096, N)
print(f"{N} sample signal: ")
print(", ".join(map(str, signal)))

def twiddle(n, points): 
    return np.exp(-(1j * np.pi * 2 * n)/points)

fft_result = np.fft.fft(signal)
np.set_printoptions(suppress=True)

print(f"\n{N} point fft result (real): ")
# print(fft_result)
print(np.real(fft_result))

print(f"\n{N} point fft result (imag): ")
print(np.imag(fft_result))

print(f"\n{N} point fft result (magnitude): ")
print(np.abs(fft_result))

# print(f"\n{N} point fft result (hex): ")
# print([print_hex(x) for x in fft_result])