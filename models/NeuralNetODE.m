% NeuralNetODE Simple firing-rate neural network
%   Constructs a simple firing-rate neural network 
%        tau * V' = -V + F(k*Kij*V + I - b)
%   where V is a (nx1) vector of firing rates,
%   F(V) is a sigmoid function,
%   k is a scaling parameter,
%   Kij is an (nxn) matrix of connection weights,
%   I is an (nx1) vector of injection currents.
%   b is a scalar threshold parameter
%   
% Example:
%   n = 20;                     % number of neurons
%   sys = NeuralNetODE(n);      % construct the system struct
%   gui = bdGUI(sys);           % open the Brain Dynamics GUI
%
% Copyright (C) 2016 Stewart Heitmann <heitmann@ego.id.au>
% Licensed under the Academic Free License 3.0
% https://opensource.org/licenses/AFL-3.0
%
function sys = NeuralNetODE(n)
    % Random symmetric connection matrix with no self coupling
    Kij = 0.5*rand(n);      % random connections
    Kij = Kij + Kij';       % force symmetry
    Kij(1:n+1:end) = 0;     % zero the diagonal
    
    % Construct the system struct
    sys.odefun = @odefun;               % Handle to our ODE function
    sys.pardef = {'Kij',Kij;            % ODE parameters {'name',value}
                  'k',1/n;
                  'Ii',rand(n,1);
                  'b',1;
                  'tau',10};
    sys.vardef = {'V',rand(n,1)};       % ODE variables {'name',value}
    sys.solver = {'ode45';              % pertinent matlab ODE solvers
                  'ode23';
                  'ode113';
                  'ode15s';
                  'ode23s';
                  'ode23t';
                  'ode23tb'};
    sys.odeopt = odeset();              % default ODE solver options
    sys.tspan = [0 1000];               % default time span [begin end]
    sys.texstr = {'\textbf{NeuralNetODE} \medskip';
                  'Simple Firing-Rate Neural Network \smallskip';
                  '\qquad $\tau \dot V_i = -V_i + F\big(k_i \sum_j K_{ij} \, V_j + I_i - b \big)$ \smallskip';
                  'where \smallskip';
                  '\qquad $V_i(t)$ is the firing rate of the $i^{th}$ neuron,';
                  '\qquad $K$ is the network connectivity matrix ($n$ x $n$),';
                  '\qquad $k$ is a scaling parameter,';
                  '\qquad $I_i$ is an external current applied to the $i^{th}$ neuron,';
                  '\qquad $b$ is the firing threshold,';
                  '\qquad $F(v)=1/(1+\exp(-v))$ is a sigmoid function,';
                  '\qquad $\tau$ is the time constant of the dynamics,';
                  '\qquad $i{=}1 \dots n$. \medskip';
                  'Notes';
                  ['\qquad 1. This simulation has $n{=}',num2str(n),'$ neurons.']};
end

% The ODE function.
function dV = odefun(t,V,Kij,k,Ii,b,tau)  
    dV = (-V + F(k*Kij*V + Ii - b))./tau;
end

% Sigmoid function
function y=F(x)
    y = 1./(1+exp(-x));
end
