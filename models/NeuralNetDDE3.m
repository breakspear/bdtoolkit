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
%   This model is very computationally expensive because the
%   DDE solver must evaluate V(t) at n^2 time lags. Consequently it is
%   only recommended for very small networks (say n=5).
%
% Example: Using the Brain Dynamics Toolbox
%   Kij = rand(5);              % random network
%   sys = NeuralNetDDE2(Kij);   % construct the system struct
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
function sys = NeuralNetDDE3(Kij)
    % determine the number of nodes from Kij
    n = size(Kij,1);

    % Construct the system struct
    sys.ddefun = @ddefun;               % Handle to our DDE function
    sys.pardef = {'Kij',Kij;            % DDE parameters {'name',value}
                  'a',1/n;
                  'Ie',rand(n,1);
                  'tau',10};
    sys.lagdef = {'lags',rand(n,n)};    % DDE lag parameters {'name',value}
    sys.vardef = {'V',rand(n,1)};       % DDE variables {'name',value}
    sys.tspan = [0 20];                 % default time span [begin end]

    % Specify DDE solvers and default options
    sys.ddesolver = {@dde23};                   % DDE solvers
    sys.ddeoption = odeset('RelTol',1e-6);      % DDE solver options

    % Include the Latex (Equations) panel in the GUI
    sys.gui.bdLatexPanel.title = 'Equations'; 
    sys.gui.bdLatexPanel.latex = {'\textbf{NeuralNetDDE3}';
        '';
        'An extreme time-delayed firing-rate neural network';
        '\qquad $\tau \dot V_i(t) = -V_i(t) + F\big(k \sum_j K_{ij} \, V_j(t-D_{ij}) + I_i \big)$';
        'where each network connection has a unique time delay,';
        '\qquad $V_i(t)$ is the firing rate of the $i^{th}$ neuron,';
        '\qquad $K$ is the network connectivity matrix ($n$ x $n$),';
        '\qquad $k$ is a scaling parameter,';
        '\qquad $D$ is a matrix of delay constants ($n$ x $n$),';
        '\qquad $I$ is a vector of injection currents ($n$ x $1$),';
        '\qquad $F(v)=1/(1+\exp(-v))$ is a sigmoid function,';
        '\qquad $\tau$ is the time constant of the dynamics,';
        '\qquad $i{=}1 \dots n$.';
        '';
        'Notes';
        ['\qquad 1. This simulation has $n{=}',num2str(n),'$ neurons.'];
        '\qquad 2. It is only practical for small networks ($n{<}6$)'};

    % Include the Time Portrait panel in the GUI
    sys.gui.bdTimePortrait.title = 'Time Portrait';
 
    % Include the Phase Portrait panel in the GUI
    sys.gui.bdPhasePortrait.title = 'Phase Portrait';

    % Include the Space-Time Portrait panel in the GUI
    sys.gui.bdSpaceTimePortrait.title = 'Space-Time';

    % Include the Solver panel in the GUI
    sys.gui.bdSolverPanel.title = 'Solver';  
    
    % Function hook for the GUI System-New menu
    sys.self = @self;    
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

% The self function is called by the GUI to reconfigure the model
function sys = self()
    % Prompt the user to load Kij from file. 
    info = {mfilename,'','Load the connectivity matrix, Kij'};
    Kij = bdLoadMatrix(mfilename,info);
    if isempty(Kij) 
        % the user cancelled the operation
        sys = [];  
    else
        % pass Kij to our main function
        sys = NeuralNetODE(Kij);
    end
end