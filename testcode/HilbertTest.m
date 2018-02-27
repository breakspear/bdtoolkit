function HilbertTest()
    addpath ..
    addpath ../panels
    
    % compare hilbert() versus bdHilbert.hilbert() for a random signal
    for rep=1:100
        test01();
    end
end

% Compare the output of bdHilbert.hilbert with that of the hilbert() 
% function provided by the Signal Processing Toolbox
function test01()
    % generate random signals in y (nsig x nfft)
    nfft = randi(100)+1;
    nsig = randi(10);
    y = 20*rand(nsig,nfft) - 10;
    
    % compute Hilbert using the Signal Processing Toolbox
    h1 = hilbert(y.').';
    
    % compute Hilbert using bdHilbert panel
    h2 = bdHilbert.hilbert(y);
    
    figure(1); clf; hold on;
    plot(h1,'go','LineWidth',3);
    plot(h2,'k.','LineWidth',1);
    
    % compute mean-square error
    err = abs(h1-h2);
    mse = mean(err(:));
    
    disp(num2str([nsig nfft mse],'test01: y is (%d x %d)  mse=%g'));
    
    if mse > 1e-8
        error('testOne failed');
    end
end

