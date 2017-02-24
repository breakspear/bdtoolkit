% OrnsteinUhlenbeck  N independent Ornstein-Uhlenbeck processes
%   N independent Ornstein-Uhlenbeck processes
%        dY_i(t) = theta*(mu-Y_i(t))*dt + sigma*dW_i(t)
%   for i=1..n.
%
% Example 1: Using the Brain Dynamics GUI
%   n = 20;                 % number of processes
%   sys = OrnsteinUhlenbeck(n);      % construct the system struct
%   gui = bdGUI(sys);       % open the Brain Dynamics GUI
% 
% Example 2: Using the Brain Dynamics command-line solver
%   n = 20;                                            % num of processes
%   sys = OrnsteinUhlenbeck(n);                        % system struct
%   sys.pardef = bdSetValue(sys.pardef,'mu',0.5);      % 'mu' parameter
%   sys.pardef = bdSetValue(sys.pardef,'sigma',0.1);   % 'sigma' parameter
%   sys.vardef = bdSetValue(sys.vardef,'Y',rand(n,1)); % 'Y' initial values
%   sys.tspan = [0 10];                                % time domain
%   sol = bdSolve(sys);                                % solve
%   t = sol.x;                                         % time steps
%   Y = sol.y;                                         % solution variables
%   dW = sol.dW;                                       % Wiener increments
%   subplot(1,2,1); 
%   plot(t,Y); xlabel('time'); ylabel('Y');            % plot time trace 
%   subplot(1,2,2);
%   histfit(dW(:)); xlabel('dW'); ylabel('count');     % noise histogram
%
% Example 3: Using pre-generated (fixed) random values
%   n = 20;                                       % number of processes
%   sys = OrnsteinUhlenbeck(n);                   % construct system struct
%   sys.sdeoption.randn = randn(n,101);           % standard normal values
%   sys.tspan = [0 10];                           % time domain
%   sol1 = bdSolve(sys);                          % solve
%   sol2 = bdSolve(sys);                          % solve (again)
%   figure
%   plot(sol1.x,sol1.y,'b');  title('sol1');      % plot 1st result in blue
%   figure
%   plot(sol2.x,sol2.y,'r');  title('sol2');      % plot 2nd result in red                                      
%
% Authors
%   Stewart Heitmann (2016a,2017a)

% Copyright (C) 2016, QIMR Berghofer Medical Research Institute
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
function sys = OrnsteinUhlenbeck(n)
    % Handle to our SDE functions
    sys.sdeF = @sdeF;                   % deterministic coefficients
    sys.sdeG = @sdeG;                   % stochastic coefficients
 
    % Our SDE parameters
    sys.pardef = [ struct('name','theta', 'value',1.0);
                   struct('name','mu',    'value',0.5);
                   struct('name','sigma', 'value',0.5) ];
               
    % Our SDE variables
    sys.vardef = struct('name','Y',  'value',5*ones(n,1));
    
    % Default time span
    sys.tspan = [0 10];  
           
   % Specify SDE solvers and default options
    sys.sdesolver = {@sdeIto};          % Pertinent SDE solvers
    sys.sdeoption.InitialStep = 0.01;   % SDE solver step size (optional)
    sys.sdeoption.NoiseSources = n;     % Number of Wiener noise processes

    % Include the Latex (Equations) panel in the GUI
    sys.panels.bdLatexPanel.title = 'Equations'; 
    sys.panels.bdLatexPanel.latex = {'\textbf{Ornstein-Uhlenbeck}';
        '';
        'N independent Ornstein-Uhlenbeck processes';
        '\qquad $dY_i = \theta (\mu - Y_i)\,dt + \sigma dW_i$';
        'where';
        '\qquad $Y(t)$ is a vector of dynamic variables ($n$ x $1$),';
        '\qquad $\theta>0$ is the rate of convergence to the mean,';
        '\qquad $\mu$ is the (long-term) mean,';
        '\qquad $\sigma>0$ is the volatility.';
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

% The deterministic coefficient function.
function F = sdeF(t,Y,theta,mu,sigma)  
    F = theta .* (mu - Y);
end

% The noise coefficient function.
function G = sdeG(t,Y,theta,mu,sigma)
    G = sigma .* eye(numel(Y));
end

% This function is called by the GUI System-New menu
function sys = self()
    % open a dialog box prompting the user for the value of n
    n = bdEditScalars({100,'number of processes'}, ...
        'New System', mfilename);
    % if the user cancelled then...
    if isempty(n)
        sys = [];                             % return empty sys
    else
        sys = OrnsteinUhlenbeck(round(n));    % generate a new sys
    end
end
