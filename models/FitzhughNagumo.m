% FitzhughNagumo Generalized FitzHugh-Nagumo neural oscillator model
%    V' = d*tau*(-f*V.^3 + e*V.^2 + g*V + alpha*W + gamma.*(Iapp + Inet))
%    W' = d*(c*V.^2 + b*V - beta*W + a)./tau
% where
%    Inet = Kij*S(V-theta)
%    S(x) = 1./(1+exp(-x./sigma))
%    
%
% Example:
%   n = 20;                           % Number of neurons.
%   Kij = circshift(eye(n),1) + ...   % Define the connection matrix
%         circshift(eye(n),-1);       % (it is a chain in this case).
%   sys = FitzhughNagumo(Kij);        % Construct the system struct.
%   gui = bdGUI(sys);                 % Open the Brain Dynamics GUI.
%
% Authors
%   Matthew Aburn (2017a)
%   Stewart Heitmann (2017a,2018a)
%
% See Also:
% FitzHugh (1955) Mathematical models of threshold phenomena in the nerve
%   membrane. Bull. Math. Biophysics, 17:257--278
% Sanz-Leon et al. (2015) Mathematical framework for large-scale brain network
%   modeling in The Virtual Brain. NeuroImage 111: 385--430.


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
function sys = FitzhughNagumo(Kij)
    % determine the number of nodes from Kij
    n = size(Kij,1);
    
    % Handle to our ODE function
    sys.odefun = @odefun;
    
    % Our ODE parameters
    sys.pardef = [ struct('name','Kij',   'value',Kij); 
                   struct('name','a',     'value',0.056);
                   struct('name','b',     'value',0.08);
                   struct('name','c',     'value',0.0);
                   struct('name','d',     'value',1.0);
                   struct('name','e',     'value',0.0);
                   struct('name','f',     'value',1./3);
                   struct('name','g',     'value',1.0);
                   struct('name','alpha', 'value',-1.0);
                   struct('name','beta',  'value',0.064);
                   struct('name','gamma', 'value',1.0);
                   struct('name','tau',   'value',1.0);
                   struct('name','Iapp',  'value',0.0);
                   struct('name','sigma', 'value',1.0);
                   struct('name','theta', 'value',0.0) ];
               
    % Our ODE variables        
    sys.vardef = [ struct('name','V', 'value',4*rand(n,1)-2, 'lim',[-2.5 2.5]);
                   struct('name','W', 'value',2.6*rand(n,1)-0.8, 'lim',[-0.8 1.8]) ];
    
    % Default time span
    sys.tspan = [0 1000];
              
    % Specify ODE solvers and default options
    %sys.odesolver = {@ode45,@ode23,@ode113,@odeEuler};  % ODE solvers
    sys.odeoption = odeset('RelTol',1e-6);              % ODE solver options

    % Include the Latex (Equations) panel in the GUI
    sys.panels.bdLatexPanel.title = 'Equations'; 
    sys.panels.bdLatexPanel.latex = {'\textbf{FitzhughNagumo}';
        '';
        'Network of generalized FitzHugh-Nagumo oscillators.';
        '\qquad $\dot V_i = \tau d (-f V_i^3 + e V_i^2 + g V_i + \alpha W_i + \gamma (I_{app} + I_{net}))$';
        '\qquad $\dot W_i = \frac{d}{\tau}(c V_i^2 + b V_i - \beta W_i + a)$';
        'where';
        '\qquad $K_{ij}$ is the connectivity matrix ($n$ x $n$),';
        '\qquad $a, b, c, d, e, f, g, \alpha, \beta, \gamma, \tau, I_{app}, \sigma$ and $\theta$ are constants,';
        '\qquad $I_{app}$ is the applied current,';
        '\qquad $I_{net} = \sum_j K_{ij} S(V_j-\theta)$,';
        '\qquad $S(V) = 1/(1+\exp(-V/\sigma))$,';
        '\qquad $i{=}1 \dots n$.';
        '';
        'Notes';
        ['\qquad 1. This simulation has $n{=}',num2str(n),'$.'];
        '';
        'References:';
        '\quad FitzHugh (1955) Mathematical models of threshold phenomena in the nerve membrane, \textit{Bull. Math. Biophysics}, \textbf{17}:257--278';
        '\quad Sanz-Leon et al. (2015) Mathematical framework for large-scale brain network modeling in The Virtual Brain, \textit{NeuroImage} \textbf{111}:385--430.'};
    
    % Include the Time Portrait panel in the GUI
    sys.panels.bdTimePortrait = [];
 
    % Include the Phase Portrait panel in the GUI
    sys.panels.bdPhasePortrait = [];

    % Include the Space-Time Portrait panel in the GUI
    sys.panels.bdSpaceTime = [];

    % Include the Solver panel in the GUI
    sys.panels.bdSolverPanel = [];                 
end

% The ODE function for the generalized FitzHugh-Nagumo model.
function dY = odefun(~,Y,Kij,a,b,c,d,e,f,g,alpha,beta,gamma,tau,I,sigma,theta)  
    % extract incoming variables from Y
    Y = reshape(Y,[],2);        % reshape Y to an (nx2) matrix 
    V = Y(:,1);                 % V is (nx1) vector
    W = Y(:,2);                 % W is (nx1) vector

    % The network coupling term
    Inet = Kij*F((V-theta)./sigma);
    
    dV = d*tau*(-f*V.^3 + e*V.^2 + g*V + alpha*W + gamma.*(I + Inet));
    dW = d*(c*V.^2 + b*V - beta*W + a)./tau;

    % return result (2n x 1)
    dY = [dV; dW];
end

% Sigmoid function
function y=F(x)
    y = 1./(1+exp(-x));
end
