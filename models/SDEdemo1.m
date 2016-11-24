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
% Example 2: Implementing the Euler method by hand
%   sys = SDEdemo1();                       % construct the system struct
%   odefun = sys.odefun;                    % the deterministic function
%   sdefun = sys.sdefun;                    % the stochastic function
%   [mu,sigma] = deal(sys.pardef{:,2});     % default parameters
%   [Y0] = deal(sys.vardef{:,2});           % initial conditions
%   dt = 0.1;                               % Euler time step
%   tdomain = 0:dt:10;                      % time domain
%   tcount = numel(tdomain);                % number of time steps
%   Y = zeros(numel(Y0),tcount);            % allocate storage for result
%   Y(:,1) = Y0;                            % initial conditions
%   for tindx = 2:numel(tdomain)            % for each time step....
%       t = tdomain(tindx);                 %     current time step 
%       y = Y(:,tindx-1);                   %     value of Y(t-dt)
%       F = odefun(t,y,mu,sigma);           %     deterministic part
%       G = sdefun(t,y,mu,sigma);           %     stochastic part
%       Y(:,tindx) = y + F*dt + sqrt(dt)*G; %     Euler step
%   end                                     % end loop
%   plot(tdomain,Y);                        % plot the result
%   xlabel('time'); ylabel('y');
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
function sys = SDEdemo1()
    % Construct the system struct
    sys.odefun = @odefun;               % Handle to our deterministic function
    sys.sdefun = @sdefun;               % Handle to our stochastic function
    sys.pardef = {'mu',  -0.1;          % SDE parameters {'name',value}
                  'sigma',0.1};
    sys.vardef = {'Y',5};               % SDE variables {'name',value}
    sys.solver = {'sde'};               % The SDE solver
    sys.tspan = [0 10];                 % default time span
              
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
end

% The deterministic function.
function dY = odefun(t,Y,a,b)  
    dY = a*Y;
end

% The stochastic function.
function dW = sdefun(t,Y,a,b)  
    dW = b*Y.*randn;
end
