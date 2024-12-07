import numpy as np

# generate random time-domain signal
np.random.seed(1)
signal = np.random.randint(-200, 200, 16)
print(signal)

def twiddle(n): 
    return np.exp(-(1j * np.pi * n)/8)

fft_result = np.fft.fft(signal)

print("\nfft result (complex): ")
print(fft_result)
# print(np.real(fft_result))

fft_s1_u0 = np.fft.fft(signal[[0, 4, 8, 12]])
fft_s1_u1 = np.fft.fft(signal[[1, 5, 9, 13]])
fft_s1_u2 = np.fft.fft(signal[[2, 6, 10, 14]])
fft_s1_u3 = np.fft.fft(signal[[3, 7, 11, 15]])
# print("\nstage1 fft result (complex): ")
# print(["" + str(hex(np.uint16(np.real(x)).astype(np.uint16) & 0XFFF)) + " " + str(hex(np.uint16(np.imag(x)).astype(np.uint16) & 0XFFF)) for x in fft_s1_u0])
# print(["" + str(hex(np.uint16(np.real(x)).astype(np.uint16) & 0XFFF)) + " " + str(hex(np.uint16(np.imag(x)).astype(np.uint16) & 0XFFF)) for x in fft_s1_u1])
# print(["" + str(hex(np.uint16(np.real(x)).astype(np.uint16) & 0XFFF)) + " " + str(hex(np.uint16(np.imag(x)).astype(np.uint16) & 0XFFF)) for x in fft_s1_u2])
# print(["" + str(hex(np.uint16(np.real(x)).astype(np.uint16) & 0XFFF)) + " " + str(hex(np.uint16(np.imag(x)).astype(np.uint16) & 0XFFF)) for x in fft_s1_u3])


fft_s2_u0_in = [fft_s1_u0[0], fft_s1_u1[0], fft_s1_u2[0], fft_s1_u3[0]]
fft_s2_u1_in = [fft_s1_u0[1], twiddle(1)*fft_s1_u1[1], twiddle(2)*fft_s1_u2[1], twiddle(3)*fft_s1_u3[1]]
fft_s2_u2_in = [fft_s1_u0[2], twiddle(2)*fft_s1_u1[2], twiddle(4)*fft_s1_u2[2], twiddle(6)*fft_s1_u3[2]]
fft_s2_u3_in = [fft_s1_u0[3], twiddle(3)*fft_s1_u1[3], twiddle(6)*fft_s1_u2[3], twiddle(9)*fft_s1_u3[3]]

fft_s2_u0 = np.fft.fft(fft_s2_u0_in)
fft_s2_u1 = np.fft.fft(fft_s2_u1_in)
fft_s2_u2 = np.fft.fft(fft_s2_u2_in)
fft_s2_u3 = np.fft.fft(fft_s2_u3_in)

print([fft_s2_u0[0], fft_s2_u1[0], fft_s2_u2[0], fft_s2_u3[0]])

