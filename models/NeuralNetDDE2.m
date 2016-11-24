% NeuralNetDDE Simple neural network with constant transmission delays
%   Implements a general time-delayed firing-rate neural network
%        tau * Vi'(t) = -Vi(t) + F(k*Kij*Vi(t-di) + Ii)
%   where each neuron has a specific time delay
%        V(t) is an (nx1) vector of firing rates
%        Kij is an (nxn) connection matrix
%        k is a scaling parameter
%        di is an (nx1) vector of delay constants
%        Ii is an (nx1) vector of injection currents
%        F(U) is a sigmoid function
%        tau is a time constant
%
% Example: Using the Brain Dynamics Toolbox
%   n = 20;                     % number of neurons
%   sys = NeuralNetDDE2(n);     % construct the system struct
%   gui = bdGUI(sys);           % Open the Brain Dynamics GUI
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
function sys = NeuralNetDDE2(n)
    % Random symmetric coupling matrix
    Kij = 0.5*rand(n,n);
    Kij = Kij + Kij';

    % Construct the system struct
    sys.ddefun = @ddefun;               % Handle to our DDE function
    sys.pardef = {'Kij',Kij;            % DDE parameters {'name',value}
                  'k',1/n;
                  'Ie',rand(n,1);
                  'tau',10};
    sys.lagdef = {'lags',rand(n,1)};    % DDE lag parameters {'name',value}
    sys.vardef = {'V',rand(n,1)};       % DDE variables {'name',value}
    sys.solver = {'dde23'};             % pertinent matlab DDE solvers
    sys.ddeopt = ddeset();              % default DDE solver options
    sys.tspan = [0 200];                % default time span [begin end]
    
    % Include the Latex (Equations) panel in the GUI
    sys.gui.bdLatexPanel.title = 'Equations'; 
    sys.gui.bdLatexPanel.latex = {'\textbf{NeuralNetDDE2}';
        '';
        'Generic time-delayed firing-rate neural network';
        '\qquad $\tau \dot V_i = -V_i + F\big(k \sum_j K_{ij} \, V_j(t-d_j) + I_i \big)$ ';
        'where each neuron has a unique time delay,';
        '\qquad $V_i(t)$ is the firing rate of the $i^{th}$ neuron,';
        '\qquad $K$ is the network connectivity matrix ($n$ x $n$),';
        '\qquad $k$ is a scaling parameter,';
        '\qquad $d$ is a vector of delay constants ($n$ x $1$),';
        '\qquad $I$ is a vector of injection currents ($n$ x $1$),';
        '\qquad $F(v)=1/(1+\exp(-v))$ is a sigmoid function,';
        '\qquad $\tau$ is the time constant of the dynamics,';
        '\qquad $i{=}1 \dots n$.';
        '';
        'Notes';
        ['\qquad 1. This simulation has $n{=}',num2str(n),'$ neurons.']};

    % Include the Time Portrait panel in the GUI
    sys.gui.bdTimePortrait.title = 'Time Portrait';
 
    % Include the Phase Portrait panel in the GUI
    sys.gui.bdPhasePortrait.title = 'Phase Portrait';

    % Include the Space-Time Portrait panel in the GUI
    sys.gui.bdSpaceTimePortrait.title = 'Space-Time';

    % Include the Solver panel in the GUI
    sys.gui.bdSolverPanel.title = 'Solver';                  
end

% The DDE function.
function dV = ddefun(t,V,Z,Kij,k,Ie,tau)  
    % extract the lagged values of V from the Z matrix (n neurons x n lags)
    Vlag = diag(Z);
    
    % Delay Differential Equation
    dV = (-V + F(k*Kij*Vlag + Ie))./tau;
end
    
% Sigmoid function
function y=F(x)
    y = 1./(1+exp(-x));
end

