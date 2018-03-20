% FRRB2012 Freyer, Roberts, Ritter, Breakspear (2012) Equation 4.
% Replicates equation (4) from Freyer, Roberts, Ritter and Breakspear
% (2012) "A Canonical Model of Multistability and Scale-Invariance in
% Biological Systems" PLoS Comput Biol 8(8): e1002634.
% doi:10.1371/journal.pcbi.1002634
%
% Equation (4) is a Stochastic Differential Equation with both
% multiplicative and additive noise sources xi_1(t) and xi_2(t).
%   dr = (-r^5 + lamba*r^3 + beta*r)*dt + eta*((1-rho)*xi_1(t) + rho*r*xi_2(t))
%
% Example:
%   n = 10;                         % number of instances
%   sys = FRRB2012(n);              % construct the system struct
%   gui = bdGUI(sys);               % open the Brain Dynamics GUI
%
% Authors
%   Stewart Heitmann (2017b,2017c,2018a)
 
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
function sys = FRRB2012(n)
    % Handles to our SDE functions
    sys.sdeF = @sdeF;               % deterministic coefficients
    sys.sdeG = @sdeG;               % stochastic coefficients
    
    % Our SDE parameters
    sys.pardef = [ struct('name','lambda', 'value', 6);
                   struct('name','beta',   'value',-2);
                   struct('name','eta',    'value', 3);
                   struct('name','rho',    'value',0.5) ];

    % Our SDE variables           
    sys.vardef = struct('name','r', 'value',rand(n,1));
    
    % Default time span
    sys.tspan = [0 100];
    
    % Specify SDE solvers and default options
    sys.sdesolver = {@sdeEM};           % Pertinent SDE solvers
    sys.sdeoption.InitialStep = 0.005;  % SDE solver step size (optional)
    sys.sdeoption.NoiseSources = 2*n;   % Number of Wiener noise processes

    % Include the Latex (Equations) panel in the GUI
    sys.panels.bdLatexPanel.title = 'Equations'; 
    sys.panels.bdLatexPanel.latex = {'\textbf{FRRB2012}';
        '';
        'Freyer F, Roberts JA, Ritter P, Breakspear M (2012) A Canonical Model of Multistability and Scale-';
        'Invariance in Biological Systems. \textit{PLoS Comput Biol} 8(8): e1002634. doi:10.1371/journal.pcbi.1002634.';
        '';
        'Equation (4)';
        '\qquad $dr = \big( -r^5 + \lambda r^3 + \beta r \big)\,dt + \eta\, \big( (1-\rho)\,\xi_1(t) + \rho\,r\,\xi_2(t) \big) $';
        'where';
        '\qquad $r(t)$ is the instantaneous amplitude of a limit cycle,';
        '\qquad $\lambda$ controls the shape of the nullcline,';
        '\qquad $\beta$ is the bifucation parameter,';
        '\qquad $\eta$ scales the overall influence of the noise,';
        '\qquad $\rho$ controls the balance of multiplicative versus additive noise,';
        '\qquad $\xi_1(t)$ and $\xi_2(t)$ are independent Weiner processes.';
        '';
        'Notes';
         num2str(n,'\\qquad 1. This simulation represents n=%d instances of Equation (4).') };
    
    % Include the Time Portrait panel in the GUI
    sys.panels.bdTimePortrait = [];

    % Include the Solver panel in the GUI
    sys.panels.bdSolverPanel = [];     
end

% The deterministic coefficient function
function f = sdeF(~,r,lambda,beta,~,~)  
    f = -r.^5 + lambda.*r.^3 + beta.*r;
end

% The noise coefficient function
function G = sdeG(~,r,~,~,eta,rho)
    n = numel(r);                 % number of instances
    I1 = eye(n).*(1-rho).*eta;    % eta * (1-rho)
    I2 = diag(r.*rho.*eta);       % eta * rho * r   
    G = [I1, I2];                 % return G as (n x 2n) matrix
end
