% Analytic Signal and Hilbert Transform. 
% Reproduced from the Matlab documentation for the hilbert function.

fs = 1e4;
t = 0:1/fs:1; 

x = 2.5+cos(2*pi*203*t)+sin(2*pi*721*t)+cos(2*pi*1001*t);

y1 = hilbert(x);
y2 = bdHilbert.hilbert(x);

mse = mean(abs(y1-y2).^2)
assert(mse<1e-8);

figure(1);

subplot(1,2,1);
plot(t,real(y1),t,imag(y1))
xlim([0.01 0.03])
legend('real','imaginary')
title('hilbert Function')

subplot(1,2,2);
plot(t,real(y2),t,imag(y2))
xlim([0.01 0.03])
legend('real','imaginary')
title('bdHilbert.hilbert Function')
