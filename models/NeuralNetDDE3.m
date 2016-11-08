% NeuralNetDDE3 - Neural network with constant transmission delays
%   Implements an extreme time-delayed firing-rate neural network
%        tau * V'(t) = -V(t) + F(a*Kij*V(t-dij) + Ii)
%   where each connection ij has a specific time delay, dij.
%   A network of n neurons thus has n^2 delay terms.
%        F(U) is a sigmoid function
%        a is a scaling parameter
%        Kij is an (nxn) connection matrix
%        V is an (nx1) vector of firing rates
%        Ii the injection current applied to the ith neuron
%        tau is a time constant
%   This example is very computationally expensive so small n are
%   recommended (say n=5). The reason it is expensive is because the
%   DDE solver must evaluate V(t) at n^2 time lags. Since V(t) is itself
%   an nx1 vector, the DDE is effectively evaluating n^3 values of V at
%   each step.
%
% Example: Using the Brain Dynamics Toolbox
%   n = 5;                      % number of neurons
%   sys = NeuralNetDDE2(n);     % construct the system struct
%   gui = bdGUI(sys);           % Open the Brain Dynamics GUI
%
% Copyright (C) 2016 Stewart Heitmann <heitmann@ego.id.au>
% Licensed under the Academic Free License 3.0
% https://opensource.org/licenses/AFL-3.0
%
function sys = NeuralNetDDE3(n)
    % Random symmetric coupling matrix
    Kij = 0.5*rand(n,n);
    Kij = Kij + Kij';

    % Construct the system struct
    sys.ddefun = @ddefun;               % Handle to our DDE function
    sys.pardef = {'Kij',Kij;            % DDE parameters {'name',value}
                  'a',1/n;
                  'Ie',rand(n,1);
                  'tau',10};
    sys.lagdef = {'lags',rand(n,n)};    % DDE lag parameters {'name',value}
    sys.vardef = {'V',rand(n,1)};       % DDE variables {'name',value}
    sys.solver = {'dde23'};             % pertinent matlab DDE solvers
    sys.ddeopt = ddeset();              % default DDE solver options
    sys.tspan = [0 20];                 % default time span [begin end]
    sys.texstr = {'\textbf{NeuralNetDDE3} \medskip';
                  'An extreme time-delayed firing-rate neural network \smallskip';
                  '\qquad $\tau \dot V_i(t) = -V_i(t) + F\big(k \sum_j K_{ij} \, V_j(t-D_{ij}) + I_i \big)$ \smallskip';
                  'where each network connection has a unique time delay, \smallskip';
                  '\qquad $V_i(t)$ is the firing rate of the $i^{th}$ neuron, \smallskip';
                  '\qquad $K$ is the network connectivity matrix ($n$ x $n$), \smallskip';
                  '\qquad $k$ is a scaling parameter, \smallskip';
                  '\qquad $D$ is a matrix of delay constants ($n$ x $n$), \smallskip';
                  '\qquad $I$ is a vector of injection currents ($n$ x $1$), \smallskip';
                  '\qquad $F(v)=1/(1+\exp(-v))$ is a sigmoid function, \smallskip';
                  '\qquad $\tau$ is the time constant of the dynamics, \smallskip';
                  '\qquad $i{=}1 \dots n$. \medskip';
                  'Notes';
                  ['\qquad 1. This simulation has $n{=}',num2str(n),'$ neurons.'];
                  '\qquad 2. It is only practical for small networks ($n{<}6$)'};

end

% The DDE function.
function dV = ddefun(t,V,Z,Kij,a,Ie,tau)
    % A network of n neurons has n^2 delay terms (one per connection).
    % The delayed values of Y are all returned in Z which is an (n x n^2)
    % matrix. Each column of Z contains the vector V at a given time delay.
    % The Z matrix is arranged in n blocks of (nxn).
    % The lagged values of Vij lie along the diagonals of each block.
    % We can obtain those diagonals by exploiting the column-order of
    % storage of matlab matrices.
    n = size(Z,1);              % number of neurons
    Z = reshape(Z,n,n,n);       % reshape Z so that each plane is one block
    
    % construct an nxn matrix Vij that contains the values of Yi at the
    % appropriate time lags for Kij
    Vij = NaN(n,n);             % init storage
    for zi = 1:n                % for each block (plane)
        Vij(:,zi) = diag(Z(:,:,zi)); 
    end
    
    Uij = Kij.*Vij;             % uij = kij * Vij(t-lag_ij)
   
    % Delay Differential Equation
    dV = (-V + F(a*sum(Uij,2) + Ie))./tau;
end
    
% Sigmoid function
function y=F(x)
    y = 1./(1+exp(-x));
end

