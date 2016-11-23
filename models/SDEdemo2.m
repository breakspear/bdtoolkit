% SDEdemo2  Independent Ornstein-Uhlenbeck processes
%   N independent Ornstein-Uhlenbeck processes
%        dY_i(t) = theta*(mu-Y_i(t))*dt + sigma*dW_i(t)
%   for i=1..n.
%
% Example 1: Using the Brain Dynamics GUI
%   n = 20;                 % number of equations
%   sys = SDEdemo2(n);      % construct the system struct
%   gui = bdGUI(sys);       % open the Brain Dynamics GUI
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
function sys = SDEdemo2(n)
    % Construct the system struct
    sys.odefun = @odefun;               % Handle to our deterministic function
    sys.sdefun = @sdefun;               % Handle to our stochastic function
    sys.pardef = {'theta',0.1;          % SDE parameters {'name',value}
                  'mu',1;
                  'sigma',0.5};
    sys.vardef = {'Y',5*ones(n,1)};     % SDE variables {'name',value}
    sys.solver = {'sde'};               % The SDE solver
    sys.tspan = [0 10];                 % default time span  
    sys.texstr = {'\textbf{SDEdemo2} \medskip';
                  'N independent Ornstein-Uhlenbeck processes\smallskip';
                  '\qquad $dY_i = \theta (\mu - Y_i)\,dt + \sigma dW_i$ \smallskip';
                  'where \smallskip';
                  '\qquad $Y(t)$ is a vector of dynamic variables ($n$ x $1$),';
                  '\qquad $\theta>0$ is the rate of convergence to the mean,';
                  '\qquad $\mu$ is the (long-term) mean,';
                  '\qquad $\sigma>0$ is the volatility,';
                  '\qquad $dW_i(t)$ is a Weiner process,';
                  '\qquad $i{=}1 \dots n$. \medskip';
                  'Notes';
                  ['\qquad 1. This simulation has $n{=}',num2str(n),'$.']};
end

% The deterministic function.
function dY = odefun(t,Y,theta,mu,sigma)  
    dY = theta .* (mu - Y);
end

% The stochastic function.
function dW = sdefun(t,Y,theta,mu,sigma)
    dW = sigma.*randn(size(Y));
end
