% HindmarshRose   Network of Hindmarsh-Rose neurons
% The Hindmarsh-Rose equations
%    x' = y - a*x.^3 + b*x.^2 - z + I - gs*(x-Vs).*Inet;
%    y' = c - d*x.^2 - y;
%    z' = r*(s*(x-x0)-z);
% where
%    Inet = Kij*F(x-theta);
%    F(x) = 1./(1+exp(-x));
%   
% Example:
%   n = 20;                           % Number of neurons
%   Kij = circshift(eye(n),1) + ...   % Connection matrix
%         circshift(eye(n),-1);       % (a chain in this case)
%   sys = HindmarshRose(Kij);         % Construct the system struct
%   gui = bdGUI(sys);                 % Open the Brain Dynamics GUI
%
% Authors
%   Stewart Heitmann (2016a,2017a)


% Copyright (C) 2016,2017 QIMR Berghofer Medical Research Institute
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
                   struct('name','Iapp',  'value',1.5);
                   struct('name','gs',    'value',0.1);
                   struct('name','Vs',    'value',2);
                   struct('name','theta', 'value',-0.25) ];
                   
    % Our ODE variables
    sys.vardef = [ struct('name','x', 'value',rand(n,1));
                   struct('name','y', 'value',rand(n,1));
                   struct('name','z', 'value',rand(n,1)) ];

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
        '\qquad $\dot X_i = Y_i - a\,X_i^3 + b\,X_i^2 - Z_i + I_{app} - g_s\,(X_i-V_s) \sum_j K_{ij} F(X_j-\theta)$';
        '\qquad $\dot Y_i = c - d\,X_i^2 - Y_i$';
        '\qquad $\dot Z_i = r\,(s\,(X_i-x_0) - Z_i)$';
        'where';
        '\qquad $K_{ij}$ is the connectivity matrix ($n$ x $n$),';
        '\qquad $a, b, c, d, r, s, x_0, I_{app}, g_s, V_s$ and $\theta$ are constants,';
        '\qquad $I_{app}$ is the applied current,';
        '\qquad $F(x) = 1/(1+\exp(-x))$,';
        '\qquad $i{=}1 \dots n$.';
        '';
        'Notes';
        ['\qquad 1. This simulation has $n{=}',num2str(n),'$.']};
    
    % Include the Time Portrait panel in the GUI
    sys.panels.bdTimePortrait = [];
 
    % Include the Phase Portrait panel in the GUI
    sys.panels.bdPhasePortrait = [];

    % Include the Space-Time panel in the GUI
    sys.panels.bdSpaceTime = [];

    % Include the Solver panel in the GUI
    sys.panels.bdSolverPanel = [];                 
    
    % Function hook for the GUI System-New menu
    sys.self = @self;
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

% This function is called by the GUI System-New menu
function sys = self()
    % open a dialog box prompting the user for the value of n
    n = bdEditScalars({100,'number of neurons'}, ...
        'New System', 'Hindmarsh-Rose Model');
    % if the user cancelled then...
    if isempty(n)
        sys = [];                       % return empty sys
    else
        sys = HindmarshRose(round(n));  % generate a new sys
    end
end
