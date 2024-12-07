import numpy as np

def twiddle(n): 
    return np.exp(-(1j * np.pi * n)/8)

def print_hex(x):
    return "" + str(hex(np.uint16(np.real(x)).astype(np.uint16) & 0XFFF)) + " " + str(hex(np.uint16(np.imag(x)).astype(np.uint16) & 0XFFF))


# generate random time-domain signal
np.random.seed(1)
signal = np.random.randint(-200, 200, 16)
print(signal)

fft_s1_u0_in = signal[[0, 4, 8, 12]]
fft_s1_u1_in = signal[[1, 5, 9, 13]]
fft_s1_u2_in = signal[[2, 6, 10, 14]]
fft_s1_u3_in = signal[[3, 7, 11, 15]]
print("\nstage1 inputs (complex): ")
print(fft_s1_u0_in)
print(fft_s1_u1_in)
print(fft_s1_u2_in)
print(fft_s1_u3_in)
print("\nstage1 inputs (hex): ")
print([print_hex(x) for x in fft_s1_u0_in])
print([print_hex(x) for x in fft_s1_u1_in])
print([print_hex(x) for x in fft_s1_u2_in])
print([print_hex(x) for x in fft_s1_u3_in])

fft_s1_u0 = np.fft.fft(signal[[0, 4, 8, 12]])
fft_s1_u1 = np.fft.fft(signal[[1, 5, 9, 13]])
fft_s1_u2 = np.fft.fft(signal[[2, 6, 10, 14]])
fft_s1_u3 = np.fft.fft(signal[[3, 7, 11, 15]])
print("\nstage1 fft result (hex): ")
print([print_hex(x) for x in fft_s1_u0])
print([print_hex(x) for x in fft_s1_u1])
print([print_hex(x) for x in fft_s1_u2])
print([print_hex(x) for x in fft_s1_u3])


fft_s2_u0_in = [fft_s1_u0[0], fft_s1_u1[0], fft_s1_u2[0], fft_s1_u3[0]]
fft_s2_u1_in = [fft_s1_u0[1], (1892-784j)*fft_s1_u1[1], (1448-1448j)*fft_s1_u2[1], (784-1892j)*fft_s1_u3[1]]
fft_s2_u2_in = [fft_s1_u0[2], twiddle(2)*fft_s1_u1[2], twiddle(4)*fft_s1_u2[2], twiddle(6)*fft_s1_u3[2]]
fft_s2_u3_in = [fft_s1_u0[3], twiddle(3)*fft_s1_u1[3], twiddle(6)*fft_s1_u2[3], twiddle(9)*fft_s1_u3[3]]
print("\nstage2 inputs (hex): ")
print([print_hex(x) for x in fft_s2_u0_in])
print([print_hex(x) for x in fft_s2_u1_in])
print([print_hex(x) for x in fft_s2_u2_in])
print([print_hex(x) for x in fft_s2_u3_in])

fft_s2_u0 = np.fft.fft(fft_s2_u0_in)
fft_s2_u1 = np.fft.fft(fft_s2_u1_in)
fft_s2_u2 = np.fft.fft(fft_s2_u2_in)
fft_s2_u3 = np.fft.fft(fft_s2_u3_in)
print([fft_s2_u0[0], fft_s2_u1[0], fft_s2_u2[0], fft_s2_u3[0]])



fft_result = np.fft.fft(signal)
print("\nfft result (complex): ")
print(fft_result)
# print("\nfft result (real): ")
# print(np.real(fft_result))


x=(1892-784j)
print("" + str(hex(np.uint16(np.real(x)).astype(np.uint16) & 0X1FFF)) + " " + str(hex(np.uint16(np.imag(x)).astype(np.uint16) & 0X1FFF)))