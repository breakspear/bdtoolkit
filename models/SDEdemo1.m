% SDEdemo1 Geometric Brownian motion
%   Stochastic Differential Equation (SDE)
%        dy(t) = mu*y(t)*dt + sigma*y(t)*dW(t)
%   decribing geometric Brownian motion. The Brain Dynamics toolbox
%   requires the determeinstic and stochastic parts of the SDE to be
%   implemented separately. In this case, the deterministic part is  
%        F(t,y) = mu*y(t)
%   and the stochastic part is
%        G(t,y) = sigma*y(t)*randn
%   The toolbox numerically integrates the combined equations using the
%   fixed step Euler method. Specifically, each step is computed as
%        dy(t+dt) = F(t,y)*dt + sqrt(dt)*G(t,y) 
%   where F(t,y) is implemented by sys.odefun(t,y,a,b)
%   and G(t,y) is implemented by sys.sdefun(t,y,a,b).
%
% Example 1: Using the Brain Dynamics GUI
%   sys = SDEdemo1();       % construct the system struct
%   gui = bdGUI(sys);       % open the Brain Dynamics GUI
% 
% Example 2: Using the Brain Dynamics command-line solver
%   sys = SDEdemo1();                                 % get system struct
%   sys.pardef = bdSetValue(sys.pardef,'mu',-0.1);    % 'mu' parameter
%   sys.pardef = bdSetValue(sys.pardef,'sigma',0.1);  % 'sigma' parameter
%   sys.vardef = bdSetValue(sys.vardef,'Y',rand);     % 'Y' initial value
%   sys.tspan = [0 10];                               % time domain
%   sol = bdSolve(sys);                               % solve
%   t = sol.x;                                        % time steps
%   Y = sol.y;                                        % solution variables
%   dW = sol.dW;                                      % noise samples
%   ax = plotyy(t,Y, t,dW);                           % plot the result
%   xlabel('time');
%   ylabel(ax(1),'Y');
%   ylabel(ax(2),'dW');
%
% Example 3: Using pre-generated (fixed) random walks
%   sys = SDEdemo1();                             % get system struct
%   sys.sdeoption.randn = randn(1,101);           % our random sequences
%   sys.tspan = [0 10];                           % time domain
%   sol1 = bdSolve(sys);                          % solve
%   sol2 = bdSolve(sys);                          % solve (again)
%   plotyy(sol1.x,sol1.y, sol1.x,sol1.dW);        % plot 1st result
%   hold on
%   plotyy(sol2.x,sol2.y, sol2.x,sol2.dW);        % plot 2nd result
%   hold off                                      
%   std(sol1.y - sol2.y)                          % results are identical
%
% Authors
%   Stewart Heitmann (2016a)

% Copyright (c) 2016, Queensland Institute Medical Research (QIMR)
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
function sys = SDEdemo1()
    % Construct the system struct
    sys.odefun = @odefun;               % Handle to our deterministic function
    sys.sdefun = @sdefun;               % Handle to our stochastic function
    sys.pardef = {'mu',  -0.1;          % SDE parameters {'name',value}
                  'sigma',0.1};
    sys.vardef = {'Y',5};               % SDE variables {'name',value}
    sys.tspan = [0 10];                 % default time span
              
   % Specify SDE solvers and default options
    sys.sdesolver = {@sdeIto};          % Relevant SDE solvers
    sys.sdeoption.InitialStep = 0.01;   % SDE solver step size (optional)
    sys.sdeoption.NoiseSources = 1;     % Number of Weiner noise processes

    % Include the Latex (Equations) panel in the GUI
    sys.gui.bdLatexPanel.title = 'Equations'; 
    sys.gui.bdLatexPanel.latex = {'\textbf{SDEdemo1}';
        '';
        'A Stochastic Differential Equation describing geometric Brownian motion';
        '\qquad $dY = \mu\,Y\,dt + \sigma\,Y\,dW_t$';
        'where';
        '\qquad $Y(t)$ is the dynamic variable,';
        '\qquad $\mu$ and $\sigma$ are scalar constants,';
        '\qquad $dW_t$ is a Weiner process.'};
    
    % Include the Time Portrait panel in the GUI
    sys.gui.bdTimePortrait.title = 'Time Portrait';

    % Include the Solver panel in the GUI
    sys.gui.bdSolverPanel.title = 'Solver';
    
    % Handle to this function. The GUI uses it to construct a new system. 
    sys.self = str2func(mfilename);
end

% The deterministic function.
function F = odefun(t,Y,a,b)  
    F = a*Y;
end

% The stochastic function.
function G = sdefun(t,Y,a,b)  
    G = b*Y;
end
