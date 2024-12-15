import numpy as np

# generate random time-domain signal
np.random.seed(1)
signal = np.random.randint(-200, 200, 64)
print("signal: ")
print(", ".join(map(str, signal)))

def twiddle(n, points): 
    return np.exp(-(1j * np.pi * 2 * n)/points)

fft_result = np.fft.fft(signal)

print("\nfft result (real): ")
# print(fft_result)
print(np.real(fft_result))

