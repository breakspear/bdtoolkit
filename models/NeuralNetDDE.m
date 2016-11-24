% NeuralNetDDE Simple neural network with constant transmission delays
%   Implements a simple time-delayed firing-rate neural network  
%        tau * V'(t) = -V(t) + F(Ia + Ib + Ic + Iapp - theta)
%   where
%        V(t) is an (nx1) vector of firing rates
%        F(U) is a sigmoid function
%        Ia(t) = a*Aij*V(t)
%        Ib(t) = b*Bij*V(t-d1)
%        Ic(t) = c*Cij*V(t-d2)
%        Iapp is an (nx1) vector of injection currents
%        Aij,Bij,Cij are (nxn) connection matrices
%        a,b,c are scaling constants
%        d1,d2 are delay constants
%        theta is the firing threshold
%        tau is the time constant of the dynamics 
%
% Example 1: Using the Brain Dynamics Toolbox
%   n = 20;                     % number of neurons
%   sys = NeuralNetDDE(n);      % construct the system struct
%   gui = bdGUI(sys);           % Open the Brain Dynamics GUI
%
% Example 2: Calling MATLAB dde23 directly
%   n = 20;                     % number of neurons
%   sys = NeuralNetDDE(n);      % system definition
%
%   % get the dde function handles from sys
%   ddefun = sys.ddefun;
%
%   % get the default parameter values from sys
%   [Aij,Bij,Cij,a,b,c,Ie,tau]=deal(sys.pardef{:,2});
% 
%   % get the default lag parameters from sys
%   [d1,d2]=deal(sys.lagdef{:,2});
%   lags=[d1;d2];
% 
%   % get the default initial conditions from sys
%   [V0]=deal(sys.vardef{:,2});
%
%   % get the default time span from sys
%   tspan = sys.tspan;     
% 
%   % get the default dde solver options from sys
%   ddeopt = sys.ddeopt;
% 
%   % Integrate using dde23. We use the initial conditions in V0 as the
%   % historical values of V(t) for t<0.
%   sol = dde23(ddefun,lags,V0,tspan,ddeopt,Aij,Bij,Cij,a,b,c,Ie,tau);
%
%   % extract the results
%   textract = 0:0.1:tspan(end);
%   [V,dV] = deval(sol,textract); 
% 
%   % plot the results
%   plot(textract,V);
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
function sys = NeuralNetDDE(n)
    % Nearest neighbour coupling (zero lag connections)
    Aij = circshift(eye(n),1) + circshift(eye(n),-1);

    % Second-nearest neighbour coupling (connections with time lag d1)
    Bij = circshift(eye(n),2) + circshift(eye(n),-2);

    % Third-nearest neighbour coupling (connections with time lag d2)
    Cij = circshift(eye(n),3) + circshift(eye(n),-3);

    % Construct the system struct
    sys.ddefun = @ddefun;               % Handle to our DDE function
    sys.pardef = {'Aij',Aij;            % DDE parameters {'name',value}
                  'Bij',Bij;
                  'Cij',Cij;
                  'a',1/n;
                  'b',1/n;
                  'c',1/n;                  
                  'Iext',rand(n,1);
                  'theta',0.5;
                  'tau',10};
    sys.lagdef = {'d1',0.10;          % DDE lag parameters {'name',value}
                  'd2',0.15};
    sys.vardef = {'V',rand(n,1)};       % DDE variables {'name',value}
    sys.solver = {'dde23'};             % pertinent matlab DDE solvers
    sys.ddeopt = ddeset();              % default DDE solver options
    sys.tspan = [0 200];                % default time span [begin end]
    
    % Include the Latex (Equations) panel in the GUI
    sys.gui.bdLatexPanel.title = 'Equations'; 
    sys.gui.bdLatexPanel.latex = {'\textbf{NeuralNetDDE}';
        '';
        'Firing-rate neural network with constant time delays';
        '\qquad $\tau \dot V_i = -V_i + F\big(I_a + I_b + I_c + I_{ext} - \theta \big)$';
        'where';
        '\qquad $V_i(t)$ is the firing rate of the $i^{th}$ neuron,';
        '\qquad $I_a(t) = a \sum_j A_{ij} \, V_j(t)$';
        '\qquad $I_b(t) = b \sum_j B_{ij} \, V_j(t-d_1)$';
        '\qquad $I_c(t) = c \sum_j C_{ij} \, V_j(t-d_2)$';
        '\qquad $A, B, C$ are ($n$ x $n$) connectivity matrices,';
        '\qquad $a,b,c$ are scaling constants,';
        '\qquad $d1,d2$ are delay constants,';
        '\qquad $I_{ext}$ is an external current ($n$ x $1$),';
        '\qquad $\theta$ is the firing threshold,';
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
function dV = ddefun(t,V,Z,Aij,Bij,Cij,a,b,c,Iext,theta,tau)  
    % extract the lagged values of V from the Z matrix (n x lags)
    V1 = Z(:,1);    % V(t-lag1)
    V2 = Z(:,2);    % V(t-lag2)
    
    % Delay Differential Equation
    dV = (-V + F(a*Aij*V + b*Bij*V1 + c*Cij*V2 + Iext - theta))./tau;
end
    
% Sigmoid function
function y=F(x)
    y = 1./(1+exp(-x));
end

