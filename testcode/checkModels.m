% This script runs bdSysCheck on selected models

if ~exist('bdSysCheck.m', 'file')
    error('bdtoolkit is not in the matlab path');
end

if ~exist('LinearODE.m', 'file')
    error('bdtoolkit/models is not in the matlab path');
end

if ~exist('sdeEM.m', 'file')
    error('bdtoolkit/solvers is not in the matlab path');
end

%%
disp 'TESTING BOLDHRF';
sys = BOLDHRF();
bdSysCheck(sys);
disp '===';

%%
disp 'TESTING BrownianMotion';
sys = BrownianMotion();
bdSysCheck(sys);
disp '===';

%%
disp 'TESTING BTF2003';
n = randi(10);
disp(num2str(n,'n=%d'));
Kij = rand(n);
sys = BTF2003(Kij);
bdSysCheck(sys);
disp '===';

%%
disp 'TESTING BTF2003DDE';
n = randi(10);
disp(num2str(n,'n=%d'));
Kij = rand(n);
sys = BTF2003DDE(Kij);
bdSysCheck(sys);
disp '===';

%%
disp 'TESTING BTF2003SDE';
n = randi(10);
disp(num2str(n,'n=%d'));
Kij = rand(n);
sys = BTF2003SDE(Kij);
bdSysCheck(sys);
disp '===';

%%
disp 'TESTING DFCL2009';
sys = DFCL2009();
bdSysCheck(sys);
disp '===';

%%
disp 'TESTING Epileptor2014ODE';
sys = Epileptor2014ODE();
bdSysCheck(sys);
disp '===';

%%
disp 'TESTING Epileptor2014SDE';
sys = Epileptor2014SDE();
bdSysCheck(sys);
disp '===';

%%
disp 'TESTING FitzhughNagumo';
n = randi(10);
disp(num2str(n,'n=%d'));
sys = FitzhughNagumo(rand(n));
bdSysCheck(sys);
disp '===';

%%
disp 'TESTING FRRB2012';
n = randi(10);
disp(num2str(n,'n=%d'));
sys = FRRB2012(n);
bdSysCheck(sys);
disp '===';

%%
disp 'TESTING FRRB2012b';
n = randi(10);
disp(num2str(n,'n=%d'));
Kij = rand(n);
sys = FRRB2012b(Kij);
bdSysCheck(sys);
disp '===';

%%
disp 'TESTING HindmarshRose';
n = randi(10);
disp(num2str(n,'n=%d'));
sys = HindmarshRose(rand(n));
bdSysCheck(sys);
disp '===';

%%
disp 'TESTING HodgkinHuxley';
sys = HodgkinHuxley();
bdSysCheck(sys);
disp '===';

%%
disp 'TESTING HopfieldNet';
n = randi(10);
disp(num2str(n,'n=%d'));
sys = HopfieldNet(n);
bdSysCheck(sys);
disp '===';

%%
disp 'TESTING KloedenPlaten446';
sys = KloedenPlaten446();
bdSysCheck(sys);
disp '===';

%%
disp 'TESTING KuramotoNet';
n = randi(10);
disp(num2str(n,'n=%d'));
Kij = rand(n);
sys = KuramotoNet(Kij);
bdSysCheck(sys);
disp '===';

%%
disp 'TESTING LinearODE';
sys = LinearODE();
bdSysCheck(sys);
disp '===';

%%
disp 'TESTING OrnsteinUhlenbeck';
n = randi(10);
disp(num2str(n,'n=%d'));
sys = OrnsteinUhlenbeck(n);
bdSysCheck(sys);
disp '===';

%%
disp 'TESTING RFB2017';
sys = RFB2017();
bdSysCheck(sys);
disp '===';

%%
disp 'TESTING SwiftHohenberg1D';
n = 300;
disp(num2str(n,'n=%d'));
dx = 0.25;
disp(num2str(dx,'dx=%f'));
sys = SwiftHohenberg1D(n,dx);
bdSysCheck(sys);
disp '===';

%%
disp 'TESTING VanDerPolOscillators';
n = randi(10);
disp(num2str(n,'n=%d'));
sys = VanDerPolOscillators(rand(n));
bdSysCheck(sys);
disp '===';

%%
disp 'TESTING WaveEquation1D';
n = 100;
sys = WaveEquation1D(n);
bdSysCheck(sys);
disp '===';

%%
disp 'TESTING WilleBakerEx3';
sys = WilleBakerEx3();
bdSysCheck(sys);
disp '===';

%%
disp 'TESTING WilsonCowan';
sys = WilsonCowan();
bdSysCheck(sys);
disp '===';

%%
disp 'TESTING WilsonCowanNet';
n = randi(10);
disp(num2str(n,'n=%d'));
Kij = rand(n,n);
Je = rand(n,1);
Ji = rand(n,1);
sys = WilsonCowanNet(Kij,Je,Ji);
bdSysCheck(sys);
disp '===';

%%
disp 'TESTING WilsonCowanRing';
n = 100;                           % number of spatial steps
dx = 0.5;                          % length of each spatial step (mm)
  
% Gaussian coupling kernels
gauss1d = @(x,sigma) exp(-x.^2/sigma^2)./(sigma*sqrt(pi));
sigmaE = 2;                        % spread of excitatory gaussian
sigmaI = 4;                        % spread of inhibitory gaussian
kernelx = -10:dx:10;               % spatial domain of kernel (mm)
Ke = gauss1d(kernelx,sigmaE)*dx;   % excitatory coupling kernel
Ki = gauss1d(kernelx,sigmaI)*dx;   % inhibitory coupling kernel
 
% Injection currents
Je = 0.7;
Ji = 0;
 
% Construct the model and check the system structure
sys = WilsonCowanRing(n,Ke,Ki,Je,Ji);
bdSysCheck(sys);
disp '===';
