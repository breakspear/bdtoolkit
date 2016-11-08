% HopfieldNet  Continuous Hopfield betwork
%   Constructs a continuous Hopfield network with n nodes.
%       tau * V' = -V + W*F(V) + I
%   where V is (nx1) vector on neuron potentials,
%   W is (nxn) matrix of connection weights,
%   I is (nx1) vector of injection currents,
%   F(V)=tanh(b*V) with slope parameter b.
%
% Example:
%   n = 20;                 % number of neurons
%   sys = HopfieldNet(n);   % construct the system struct
%   gui = bdGUI(sys);       % open the Brain Dynamics GUI
%
% Copyright (C) 2016 Stewart Heitmann <heitmann@ego.id.au>
% Licensed under the Academic Free License 3.0
% https://opensource.org/licenses/AFL-3.0
%
function sys = HopfieldNet(n)
    % Random symmetric connection matrix with no self coupling
    Wij = 0.5*rand(n);      % random connections
    Wij = Wij + Wij';       % force symmetry
    Wij(1:n+1:end) = 0;     % zero the diagonal
    
    % Construct the system struct
    sys.odefun = @odefun;               % Handle to our ODE function
    sys.pardef = {'Wij',Wij;            % ODE parameters {'name',value}
                  'Iapp',rand(n,1);
                  'b',1;
                  'tau',10};
    sys.vardef = {'V',rand(n,1)};       % ODE variables {'name',value}
    sys.solver = {'ode45'};             % pertinent matlab ODE solvers
    sys.odeopt = odeset();              % default ODE solver options
    sys.tspan = [0 200];               % default time span [begin end]
    sys.texstr = {'\textbf{HopfieldNet} \medskip';
                  'The Continuous Hopfield Network \smallskip';
                  '\qquad $\tau \dot V_i = -V_i + \sum_j W_{ij} \tanh(b\, V_i) + I_{app}$ \smallskip';
                  'where \smallskip';
                  '\qquad $V$ is the firing rate of each neuron ($n$ x $1$),';
                  '\qquad $K$ is the connectivity matrix ($n$ x $n$),';
                  '\qquad $b$ is a slope parameter,';
                  '\qquad $I_{app}$ is the applied current ($n$ x $1$),';
                  '\qquad $i{=}1 \dots n$. \medskip';
                  'Notes';
                  ['\qquad 1. This simulation has $n{=}',num2str(n),'$.']};

end

% The ODE function.
function dV = odefun(t,V,Wij,Ii,b,tau)  
    dV = (-V + Wij*tanh(b*V) + Ii)./tau;
end
