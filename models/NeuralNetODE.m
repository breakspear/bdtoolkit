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

% Copyright (c) 2016, Stewart Heitmann <heitmann@ego.id.au>
% All rights reserved.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions
% are met:
%
% 1. Redistributions of source code must retain the above copyright
%    notice, this list of conditions and the following disclaimer.
% 
% 2. Redistributions in binary form must reproduce the above copyright
%    notice, this list of conditions and the following disclaimer in
%    the documentation and/or other materials provided with the
%    distribution.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
% "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
% LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
% FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
% COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
% INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
% BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
% LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
% CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
% LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
% ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
% POSSIBILITY OF SUCH DAMAGE.
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
