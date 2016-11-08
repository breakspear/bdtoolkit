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
% Copyright (C) 2016 Stewart Heitmann <heitmann@ego.id.au>
% Licensed under the Academic Free License 3.0
% https://opensource.org/licenses/AFL-3.0
%
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
