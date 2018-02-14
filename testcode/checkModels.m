% This script runs bdSysCheck on selected models

if ~exist('bdSysCheck.m', 'file')
    error('bdtoolkit is not in the matlab path');
end

if ~exist('LinearODE.m', 'file')
    error('bdtoolkit/models is not in the matlab path');
end

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


