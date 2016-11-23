% This script runs bdLint on selected models

if ~exist('bdLint.m', 'file')
    addpath ..
end

if ~exist('ODEdemo1.m', 'file')
    addpath ../models
end

disp 'TESTING ODEdemo1';
sys = ODEdemo1();
bdLint(sys);
disp '===';

disp 'TESTING ODEdemo2';
sys = ODEdemo2();
bdLint(sys);
disp '===';

disp 'TESTING ODEdemo3';
n = 20;                             % number of nodes
Kij = circshift(eye(n),1) + ...     % nearest-neighbour coupling
      circshift(eye(n),-1);
sys = ODEdemo3(Kij);
bdLint(sys);
disp '===';

disp 'TESTING DDEdemo1';
sys = DDEdemo1();
bdLint(sys);
disp '===';

disp 'TESTING SDEdemo1';
sys = SDEdemo1();
bdLint(sys);
disp '===';

disp 'TESTING SDEdemo2';
n = 13;
sys = SDEdemo2(n);
bdLint(sys);
disp '===';

disp 'TESTING NeuralNetODE';
n = 13;
sys = NeuralNetODE(n);
bdLint(sys);
disp '===';

disp 'TESTING NeuralNetDDE';
n = 13;
sys = NeuralNetDDE(n);
bdLint(sys);
disp '===';

disp 'TESTING NeuralNetDDE2';
n = 13;
sys = NeuralNetDDE2(n);
bdLint(sys);
disp '===';

disp 'TESTING NeuralNetDDE3';
n = 13;
sys = NeuralNetDDE3(n);
bdLint(sys);
disp '===';

disp 'TESTING HindmarshRose';
n = 13;
sys = HindmarshRose(n);
bdLint(sys);
disp '===';

disp 'TESTING HopfieldNet';
n = 13;
sys = HopfieldNet(n);
bdLint(sys);
disp '===';

disp 'TESTING Kuramoto';
n = 13;
Kij = rand(n);
sys = Kuramoto(Kij);
bdLint(sys);
disp '===';

disp 'TESTING SwiftHohenberg1D';
n = 400;
dx = 0.25
sys = SwiftHohenberg1D(n,dx);
bdLint(sys);
disp '===';

disp 'TESTING WaveEquation1D';
n = 100;
sys = WaveEquation1D(n);
bdLint(sys);
disp '===';
