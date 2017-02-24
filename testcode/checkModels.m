% This script runs bdSysCheck on selected models

if ~exist('bdSysCheck.m', 'file')
    addpath ..
end

if ~exist('LinearODE2D.m', 'file')
    addpath ../models
end

disp 'TESTING LinearODE2D';
sys = LinearODE2D();
bdSysCheck(sys);
disp '===';

disp 'TESTING VanDerPolOscillators';
n = randi(10);
disp(num2str(n,'n=%d'));
sys = VanDerPolOscillators(rand(n));
bdSysCheck(sys);
disp '===';

disp 'TESTING FitzhughNagumo';
n = randi(10);
disp(num2str(n,'n=%d'));
sys = FitzhughNagumo(rand(n));
bdSysCheck(sys);
disp '===';

disp 'TESTING HindmarshRose';
n = randi(10);
disp(num2str(n,'n=%d'));
sys = HindmarshRose(rand(n));
bdSysCheck(sys);
disp '===';

disp 'TESTING HopfieldNet';
n = randi(10);
disp(num2str(n,'n=%d'));
sys = HopfieldNet(n);
bdSysCheck(sys);
disp '===';

disp 'TESTING KuramotoNet';
n = randi(10);
disp(num2str(n,'n=%d'));
Kij = rand(n);
sys = KuramotoNet(Kij);
bdSysCheck(sys);
disp '===';

disp 'TESTING SwiftHohenberg1D';
n = 300;
disp(num2str(n,'n=%d'));
dx = 0.25;
disp(num2str(dx,'dx=%f'));
sys = SwiftHohenberg1D(n,dx);
bdSysCheck(sys);
disp '===';

disp 'TESTING WaveEquation1D';
n = 100;
sys = WaveEquation1D(n);
bdSysCheck(sys);
disp '===';

disp 'TESTING BrownianMotion';
sys = BrownianMotion();
bdSysCheck(sys);
disp '===';

disp 'TESTING OrnsteinUhlenbeck';
n = randi(10);
disp(num2str(n,'n=%d'));
sys = OrnsteinUhlenbeck(n);
bdSysCheck(sys);
disp '===';

disp 'TESTING MultipNoise';
sys = MultipNoise();
bdSysCheck(sys);
disp '===';

disp 'TESTING DDEdemo1';
sys = DDEdemo1();
bdSysCheck(sys);
disp '===';


disp 'TESTING SwiftHohenberg1D';
n = 400;
dx = 0.25;
sys = SwiftHohenberg1D(n,dx);
bdSysCheck(sys);
disp '===';

