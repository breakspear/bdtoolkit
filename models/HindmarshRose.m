% HindmarshRose Network of Hindmars-Rose neurons
% The Hindmarsh-Rose equations
%    x' = y - a*x.^3 + b*x.^2 - z + I - gs*(x-Vs).*Inet;
%    y' = c - d*x.^2 - y;
%    z' = r*(s*(x-x0)-z);
% where
%    Inet = Kij*F(x-theta);
%    F(x) = 1./(1+exp(-x));
%   
% Example:
%   n = 20;                     % number of neurons
%   sys = HindmarshRose(n);     % construct the system struct
%   gui = bdGUI(sys);           % open the Brain Dynamics GUI
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
function sys = HindmarshRose(n)
    % Construct the default connection matrix (a chain in this case)
    Kij = circshift(eye(n),1) + circshift(eye(n),-1);

    % Construct the system struct
    sys.odefun = @odefun;               % Handle to our ODE function
    sys.pardef = {'Kij',Kij;            % ODE parameters {'name',value}
                  'a',1;
                  'b',3;
                  'c',1;
                  'd',5;
                  'r',0.006;
                  's',4;
                  'x0',-1.6;
                  'Iapp',1.5;
                  'gs',0.1;
                  'Vs',2;
                  'theta',-0.25};
    sys.vardef = {'x',rand(n,1);        % ODE variables {'name',value}
                  'y',rand(n,1);
                  'z',rand(n,1)};
    sys.solver = {'ode45',              % pertinent matlab ODE solvers
                  'ode23',
                  'ode113',
                  'ode15s',
                  'ode23s',
                  'ode23t',
                  'ode23tb'};
    sys.odeopt = odeset();              % default ODE solver options
    sys.tspan = [0 1000];               % default time span [begin end]
    sys.texstr = {'\textbf{HindmarshRose} \medskip';
                  'Network of reciprocally-coupled Hindmarsh-Rose neurons \smallskip';
                  '\qquad $\dot X_i = Y_i - a\,X_i^3 + b\,X_i^2 - Z_i + I_{app} - I_{net}$ \smallskip';
                  '\qquad $\dot Y_i = c - d\,X_i^2 - Y_i$ \smallskip';
                  '\qquad $\dot Z_i = r\,(s\,(X_i-x_0) - Z_i)$ \smallskip';
                  'where \smallskip';
                  '\qquad $K_{ij}$ is the connectivity matrix ($n$ x $n$),';
                  '\qquad $a, b, c, d, r, s, x_0, I_{app}, g_s, V_s$ and $\theta$ are constants,';
                  '\qquad $I_{app}$ is the applied current,';
                  '\qquad $I_{net} = g_s\,(X_i-V_s) \sum_j K_{ij} F(X_j-\theta)$,';
                  '\qquad $F(x) = 1/(1+\exp(-x))$,';
                  '\qquad $i{=}1 \dots n$. \medskip';
                  'Notes';
                  ['\qquad 1. This simulation has $n{=}',num2str(n),'$.']};
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
