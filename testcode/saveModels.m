% This script regenerates the mat files in the models directory.
% It must be run from the bdtoolkit root directory.
% The parameters for each model match its own help text wherever possible. 

disp 'SAVING BTF2003ODE';
Kij = rand(10);
sys = BTF2003ODE(Kij);
save ./models/BTF2003ODE.mat sys;
disp '===';

disp 'SAVING BTF2003DDE';
Kij = rand(10);
sys = BTF2003DDE(Kij);
save ./models/BTF2003DDE.mat sys;
disp '===';

disp 'SAVING BTF2003SDE';
Kij = rand(10);
sys = BTF2003SDE(Kij);
save ./models/BTF2003SDE.mat sys;
disp '===';

disp 'SAVING BrownianMotion';
sys = BrownianMotion();
save ./models/BrownianMotion.mat sys;
disp '===';

disp 'SAVING FRRB2012';
n = 12;
sys = FRRB2012(n);
save ./models/FRRB2012.mat sys;
disp '===';

disp 'SAVING FRRB2012b';
n = 10;
Kij = rand(n);
sys = FRRB2012b(Kij);
save ./models/FRRB2012b.mat sys;
disp '===';

disp 'SAVING FitzhughNagumo';
n = 20;                           % Number of neurons.
Kij = circshift(eye(n),1) + ...   % Define the connection matrix
      circshift(eye(n),-1);       % (it is a chain in this case).
sys = FitzhughNagumo(Kij);
save ./models/FitzhughNagumo.mat sys;
disp '===';

disp 'SAVING HindmarshRose';
n = 20;                           % Number of neurons
Kij = circshift(eye(n),1) + ...   % Connection matrix
      circshift(eye(n),-1);       % (a chain in this case)
sys = HindmarshRose(Kij);         % Construct the system struct
save ./models/HindmarshRose.mat sys;
disp '===';

disp 'SAVING HopfieldNet';
n = 20;                 % number of neurons
Wij = 0.5*rand(n);      % random connectivity
Wij = Wij + Wij';       % with symmetric connections (Wij=Wji)
Wij(1:n+1:end) = 0;     % and non self coupling (zero diagonal)
sys = HopfieldNet(Wij); % construct the system struct
save ./models/HopfieldNet.mat sys;
disp '===';

disp 'SAVING KuramotoNet';
n = 20;                    % number of oscillators
Kij = ones(n);             % coupling matrix
sys = KuramotoNet(Kij);    % construct the system struct
save ./models/KuramotoNet.mat sys;
disp '===';

disp 'SAVING LinearODE';
sys = LinearODE();
save ./models/LinearODE.mat sys;
disp '===';

disp 'SAVING MultiplicativeNoise';
sys = MultiplicativeNoise();
save ./models/MultiplicativeNoise.mat sys;
disp '===';

disp 'SAVING OrnsteinUhlenbeck';
n = 20;
sys = OrnsteinUhlenbeck(n);
save ./models/OrnsteinUhlenbeck.mat sys;
disp '===';

disp 'SAVING RFB2017';
sys = RFB2017();
save ./models/RFB2017.mat sys;
disp '===';

disp 'SAVING SwiftHohenberg1D';
n = 300;
dx = 0.25;
sys = SwiftHohenberg1D(n,dx);
save ./models/SwiftHohenberg1D.mat sys;
disp '===';

disp 'SAVING VanDerPolOscillators';
n = 20;                             % number of nodes
Kij = circshift(eye(n),1) + ...     % nearest-neighbour coupling
      circshift(eye(n),-1);
sys = VanDerPolOscillators(Kij);    % construct the system struct
save ./models/VanDerPolOscillators.mat sys;
disp '===';

disp 'SAVING WaveEquation1D';
n = 100;
sys = WaveEquation1D(n);
save ./models/WaveEquation1D.mat sys;
disp '===';

disp 'TESTING WilleBaker';
sys = WilleBaker();
save ./models/WilleBaker.mat sys;
disp '===';


