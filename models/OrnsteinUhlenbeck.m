% OrnsteinUhlenbeck  N independent Ornstein-Uhlenbeck processes
%   N independent Ornstein-Uhlenbeck processes
%        dY_i(t) = theta*(mu-Y_i(t))*dt + sigma*dW_i(t)
%   for i=1..n.
%
% Example 1: Using the Brain Dynamics GUI
%   n = 20;                         % number of processes
%   sys = OrnsteinUhlenbeck(n);     % construct the system struct
%   gui = bdGUI(sys);               % open the Brain Dynamics GUI
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
% Authors
%   Stewart Heitmann (2016a,2017a,2017c,2018a)

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
function sys = OrnsteinUhlenbeck(n)
    % Handle to our SDE functions
    sys.sdeF = @sdeF;       % deterministic part 
    sys.sdeG = @sdeG;       % stochastic part
 
    % SDE parameters
    sys.pardef = [ struct('name','theta', 'value',1.0);
                   struct('name','mu',    'value',0.5);
                   struct('name','sigma', 'value',0.5) ];
               
    % SDE state variables
    sys.vardef = struct('name','Y',  'value',5*ones(n,1));
    
    % Nominate the applicable SDE solvers
    sys.sdesolver = {@sdeEM,@sdeSH};    % Euler-Marayuma, Stratonovich-Huen
    
    % SDE solver options
    sys.sdeoption.InitialStep = 0.1;    % Solver step size
    sys.sdeoption.NoiseSources = n;     % Number of noise sources

    % Latex (Equations) panel
    sys.panels.bdLatexPanel.title = 'Equations'; 
    sys.panels.bdLatexPanel.latex = {'\textbf{Ornstein-Uhlenbeck}';
        '';
        'System of $n$ independent Ornstein-Uhlenbeck processes';
        '\qquad $dY_i = \theta (\mu - Y_i)\,dt + \sigma dW_i$';
        'where';
        '\qquad $Y_i(t)$ are the $n$ state variables,';
        '\qquad $\mu$ dictates the long-term mean of $Y_i(t)$,';
        '\qquad $\theta>0$ is the rate of convergence to the mean,';
        '\qquad $\sigma>0$ is the volatility of the noise.';
        '';
        'Notes';
        ['\qquad 1. This simulation has $n{=}',num2str(n),'$.']};
              
    % Time Portrait panel
    sys.panels.bdTimePortrait = [];
 
    % Phase Portrait panel
    sys.panels.bdPhasePortrait = [];

    % Solver panel
    sys.panels.bdSolverPanel = [];      
    
    % Default time span (optional)
    sys.tspan = [0 2000];  
end

% The deterministic part of the equation.
function F = sdeF(t,Y,theta,mu,sigma)  
    F = theta .* (mu - Y);
end

% The stochastic part of the equation.
function G = sdeG(t,Y,theta,mu,sigma)
    G = sigma .* eye(numel(Y));
end
