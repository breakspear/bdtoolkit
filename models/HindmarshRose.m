% HindmarshRose   Network of Hindmarsh-Rose neurons
% sys = HindmarshRose(Kij)
% Constructs a system definition for the Hindmarsh-Rose model
%    x' = y - a*x.^3 + b*x.^2 - z + I - gs*(x-Vs).*Inet;
%    y' = c - d*x.^2 - y;
%    z' = r*(s*(x-x0)-z);
% where
%    Inet = Kij*F(x-theta);
%    F(x) = 1./(1+exp(-x));
%    Kij is a network connectivity matrix (nxn).
%   
% Example:
%   n = 20;                           % Number of neurons
%   Kij = circshift(eye(n),1) + ...   % Connection matrix
%         circshift(eye(n),-1);       % (a chain in this case)
%   sys = HindmarshRose(Kij);         % Construct the system struct
%   gui = bdGUI(sys);                 % Open the Brain Dynamics GUI
%
% Authors
%   Stewart Heitmann (2016a,2017a,2018a)


% Copyright (C) 2016-2018 QIMR Berghofer Medical Research Institute
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
function sys = HindmarshRose(Kij)
    % determine the number of nodes from Kij
    n = size(Kij,1);
    
    % Handle to our ODE function
    sys.odefun = @odefun;
    
    % Our ODE parameters
    sys.pardef = [ struct('name','Kij',   'value',Kij);
                   struct('name','a',     'value',1);
                   struct('name','b',     'value',3);
                   struct('name','c',     'value',1);
                   struct('name','d',     'value',5);
                   struct('name','r',     'value',0.006);
                   struct('name','s',     'value',4);
                   struct('name','x0',    'value',-1.6);
                   struct('name','I',     'value',zeros(n,1));
                   struct('name','gs',    'value',0.1);
                   struct('name','Vs',    'value',2);
                   struct('name','theta', 'value',-0.25) ];
                   
    % Our ODE variables
    sys.vardef = [ struct('name','X', 'value',rand(n,1), 'lim',[-2.5 2.5]);
                   struct('name','Y', 'value',rand(n,1), 'lim',[ -21   3]);
                   struct('name','Z', 'value',rand(n,1), 'lim',[   0   4]) ];

    % Default time span
    sys.tspan = [0 1000];
              
    % Specify ODE solvers and default options
    sys.odesolver = {@ode45,@ode23,@ode113,@odeEul};    % ODE solvers
    sys.odeoption = odeset('RelTol',1e-6);              % ODE solver options

    % Include the Latex (Equations) panel in the GUI
    sys.panels.bdLatexPanel.title = 'Equations'; 
    sys.panels.bdLatexPanel.latex = {'\textbf{HindmarshRose}';
        '';
        'Network of reciprocally-coupled Hindmarsh-Rose neurons';
        '\qquad $\dot X_i = Y_i - a\,X_i^3 + b\,X_i^2 - Z_i + I_i - g_s\,(X_i-V_s) \sum_j K_{ij} F(X_j-\theta)$';
        '\qquad $\dot Y_i = c - d\,X_i^2 - Y_i$';
        '\qquad $\dot Z_i = r\,(s\,(X_i-x_0) - Z_i)$';
        'where';
        '\qquad $K_{ij}$ is the connectivity matrix ($n$ x $n$),';
        '\qquad $g_s$ is the conductance of synaptic connections,';
        '\qquad $I_{i}$ is the external current applied to the $i^{th}$ neuron,';
        '\qquad $a, b, c, d, r, s, x_0, V_s$ and $\theta$ are constants,';
        '\qquad $F(x) = 1/(1+\exp(-x))$ is the firing-rate function,';
        '\qquad $i{=}1 \dots n$,';
        ['\qquad $n{=}',num2str(n),'$.'];
        '';
        '';
        '';
        'Hindmarsh \& Rose (1984) A model of neuronal bursting using three';
        'coupled first order differential equations. Proc R Soc London, Ser B.'};
    
    % Include the Time Portrait panel in the GUI
    sys.panels.bdTimePortrait = [];
 
    % Include the Phase Portrait panel in the GUI
    sys.panels.bdPhasePortrait = [];

    % Include the Space-Time panel in the GUI
    sys.panels.bdSpaceTime = [];

    % Include the Solver panel in the GUI
    sys.panels.bdSolverPanel = [];                 
end

% The ODE function for the Hindmarsh Rose model.
% See Dhamala, Jirsa and Ding (2004) Phys Rev Lett.
function dY = odefun(t,Y,Kij,a,b,c,d,r,s,x0,I,gs,Vs,theta)  
    % extract incoming variables from Y
    Y = reshape(Y,[],3);        % reshape Y to an (nx3) matrix 
    x = Y(:,1);                 % x is (nx1) vector
    y = Y(:,2);                 % y is (nx1) vector
    z = Y(:,3);                 % z is (nx1) vector

    % The network coupling term
    Inet = gs*(x-Vs) .* (Kij*F(x-theta));
    
    % Hindmarsh-Rose equations
    dx = y - a*x.^3 + b*x.^2 - z + I - Inet;
    dy = c - d*x.^2 - y;
    dz = r*(s*(x-x0)-z);

    % return result (3n x 1)
    dY = [dx; dy; dz];
end

% Sigmoid function
function y=F(x)
    y = 1./(1+exp(-x));
end
