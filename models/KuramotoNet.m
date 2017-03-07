% KuramotoNet - Network of Kuramoto Phase Oscillators
%   Constructs a Kuramoto network with n nodes.
%       theta_i' = omega_i + SUM_j Kij*sin(theta_i-theta_j)
%   where 
%       theta is an (nx1) vector of oscillator phases (in radians),
%       omega is an (nx1) vector of natural frequencies (cycles/sec)
%       Kij is an (nxn) matrix of connection weights,
%
% Example:
%   n = 20;                 % number of oscillators
%   Kij = ones(n);          % coupling matrix
%   sys = Kuramoto(Kij);    % construct the system struct
%   gui = bdGUI(sys);       % open the Brain Dynamics GUI
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
function sys = KuramotoNet(Kij)
    % Determine the number of nodes from the size of the coupling matrix
    n = size(Kij,1);
    
    % Handles to our ODE and auxiliary functions
    sys.odefun = @odefun;
    sys.auxfun = @auxfun;
    
    % ODE parameters
    sys.pardef = [ struct('name','Kij',   'value',Kij);
                   struct('name','k',     'value',1);               
                   struct('name','omega', 'value',randn(n,1)) ];
               
    % ODE state variables
    sys.vardef = struct('name','theta', 'value',2*pi*rand(n,1));
    
    % Auxiliary variables
    sys.auxdef = [ struct('name','phi', 'value',zeros(n,1));
                   struct('name','R',   'value',0) ];
               
    % Time span
    sys.tspan = [0 100];

    % Relevant ODE solvers
    sys.odesolver = {@ode45,@ode23,@ode113,@odeEul};
    
    % ODE solver options
    sys.odeoption.RelTol = 1e-6;
    sys.odeoption.MaxStep = 0.1;                
                    
    % Latex (Equations) panel
    sys.panels.bdLatexPanel.title = 'Equations'; 
    sys.panels.bdLatexPanel.latex = {'\textbf{Kuramoto}';
        '';
        'Network of Kuramoto Oscillators';
        '\qquad $\dot \theta_i = \omega_i + \frac{k}{n} \sum_j K_{ij} \sin(\theta_i - \theta_j)$';
        'where';
        '\qquad $\theta_i$ is the phase of the $i^{th}$ oscillator (radians),';
        '\qquad $\omega_i$ is its natural oscillation frequency (cycles/sec),';
        '\qquad $K$ is the network connectivity matrix ($n$ x $n$),';
        '\qquad $k$ is a scaling constant,';
        '\qquad $i,j=1 \dots n$';
        '';
        'Auxillary variables';
        '\qquad $\phi_i = \sin( \theta_i - \theta_1 )$ is the sinusoid of the phase of $\theta_i$ relative to $\theta_1$';                  
        '\qquad $R = \frac{1}{n} \sum_i \exp(\mathbf{i} \theta_i)$ is the Kuramoto order parameter.';
        '';
        'Notes';
        ['\qquad 1. This simulation has $n{=}',num2str(n),'$ oscillators.'];
        '\qquad 2. $\mathbf{i} = \sqrt{-1}$';
        '';
        'References';
        '\qquad Kuramoto (1984) Chemical oscillations, waves and turbulence.';
        '\qquad Strogatz (2000) From Kuramoto to Crawford.';
        '\qquad Breakspear et al (2010) Generative models of cortical oscillations.'};
    
    % Time Portrait panel
    sys.panels.bdTimePortrait.title = 'Time Portrait';
 
    % Phase Portrait panel
    sys.panels.bdPhasePortrait.title = 'Phase Portrait';

    % Space-Time panel
    sys.panels.bdSpaceTime.title = 'Space-Time';

    % Correlation panel
    sys.panels.bdCorrPanel.title = 'Correlation';

    % Solver panel
    sys.panels.bdSolverPanel.title = 'Solver';                
end

% Kuramoto ODE function where
% theta is a (1xn) vector of oscillator phases,
% Kij is either a scalar or an (nxn) matrix of connection weights,
% k is a scalar,
% omega is either a scalar or (1xn) vector of oscillator frequencies.
function dtheta = odefun(t,theta,Kij,k,omega)
    n = numel(theta);
    theta_i = theta * ones(1,n);                        % (nxn) matrix with same theta values in each row
    theta_j = ones(n,1) * theta';                       % (nxn) matrix with same theta values in each col
    theta_ij = theta_i - theta_j;                       % (nxn) matrix of all possible (theta_i - theta_j) combinations
    dtheta = omega + k/n.*sum(Kij.*sin(theta_ij),1)';   % Kuramoto Equation in vector form.
end

% The toolbox applies this auxillary function to the solution returned by
% the solver. The ODE parameters are the same as odefun. Its output is
% a two dimensional array where each row containes one auxiliary variable
% whose values are computed t all time samples in vector t.
% In this case, the auxillary variables are
%    phi(j) = sin(theta(j) - theta(1))
% and the Kuramoto order parameter
%    R = 1/n * sum(exp(1i*theta)).
function aux = auxfun(sol,Kij,k,omega)
    theta = sol.y;                                % (nxt) matrix
    n = size(theta,1);
    phi = sin(theta - ones(n,1)*theta(1,:));      % (nxt) matrix
    R = abs(sum(exp(1i*theta),1))./n;             % (1xt) vector
    aux = [phi; R];
end
