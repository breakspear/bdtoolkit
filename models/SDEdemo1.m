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
% Copyright (C) 2016 Stewart Heitmann <heitmann@ego.id.au>
% Licensed under the Academic Free License 3.0
% https://opensource.org/licenses/AFL-3.0
%
function sys = SDEdemo1()
    % Construct the system struct
    sys.odefun = @odefun;               % Handle to our deterministic function
    sys.sdefun = @sdefun;               % Handle to our stochastic function
    sys.pardef = {'mu',  -0.1;          % SDE parameters {'name',value}
                  'sigma',0.1};
    sys.vardef = {'Y',5};               % SDE variables {'name',value}
    sys.solver = {'sde'};               % The SDE solver
    sys.tspan = [0 10];                 % default time span
    sys.texstr = {'\textbf{SDEdemo1} \medskip';
                  'A Stochastic Differential Equation \smallskip';
                  '\qquad $dY = \mu\,Y\,dt + \sigma\,Y\,dW_t$ \smallskip';
                  'describing geometric Brownian motion, where \smallskip';
                  '\qquad $Y(t)$ is the dynamic variable, \smallskip';
                  '\qquad $\mu$ and $\sigma$ are scalar constants, \smallskip';
                  '\qquad $dW_t$ is a Weiner process. \medskip'};
end

% The deterministic function.
function dY = odefun(t,Y,a,b)  
    dY = a*Y;
end

% The stochastic function.
function dW = sdefun(t,Y,a,b)  
    dW = b*Y.*randn;
end
