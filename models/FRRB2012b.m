% FRRB2012b Freyer, Roberts, Ritter, Breakspear (2012) Equation 4.
% A bidirectionally coupled network of dynamical systems with canonical
% Hopf dynamics following Freyer, Roberts, Ritter and Breakspear (2012)
% "A Canonical Model of Multistability and Scale-Invariance in Biological
% Systems" PLoS Comput Biol 8(8): e1002634. 
% doi:10.1371/journal.pcbi.1002634
%
% The dynamics are giverned by
%   dr = (-r^5 + lamba*r^3 + beta*r + k/N Kij*r)*dt + eta*((1-rho)*xi(t) + rho*r*zeta(t))
% where xi(t) and zeta(t) are independent noise sources.
%
% Example:
%   n = 10;                         % number of network nodes
%   Kij = rand(n);                  % random connectivity matrix
%   sys = FRRB2012b(Kij);           % construct the system struct
%   gui = bdGUI(sys);               % open the Brain Dynamics GUI
%
% Authors
%   Stewart Heitmann (2017b,2017c)
 
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
function sys = FRRB2012b(Kij)
    % determine the number of nodes from Kij
    n = size(Kij,1);

    % Handles to our SDE functions
    sys.sdeF = @sdeF;               % deterministic coefficients
    sys.sdeG = @sdeG;               % stochastic coefficients
    
    % Our SDE parameters
    sys.pardef = [ struct('name','Kij',    'value', Kij);            
                   struct('name','k',      'value', 0);
                   struct('name','lambda', 'value', 6);
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
    sys.panels.bdLatexPanel.latex = {
        '\textbf{FRRB2012b}';
        '';
        'A bi-directional network of nodes with canonical Hopf dynamics and multiplicative noise following';
        'Freyer F, Roberts JA, Ritter P, Breakspear M (2012) A Canonical Model of Multistability and Scale-';
        'Invariance in Biological Systems. \textit{PLoS Comput Biol} 8(8): e1002634. doi:10.1371/journal.pcbi.1002634.';
        '';
        'The dynamics of each node is governed by';
        '\qquad $dr_i = \big( -r_i^5 + \lambda r_i^3 + \beta r_i + \frac{k}{N}\, \sum_j  K_{ij} r_j\big)\,dt + \eta\, \big( (1-\rho)\,\xi_i(t) + \rho\,r_i\,\zeta_i(t) \big) $';
        'where';
        '\qquad $r_i(t)$ is the instantaneous amplitude of the limit cycle at the $i^{th}$ network node,';
        '\qquad $\lambda$ controls the shape of the $r$ nullcline,';
        '\qquad $\beta$ is the bifucation parameter,';
        '\qquad $K_{ij}$ is the network connectivity matrix ($n$ x $n$) ,';
        '\qquad $k$ scales the network connectivity,';
        num2str(n,'\\qquad $N$=%d is the number of network nodes,');        
        '\qquad $\eta$ scales the overall influence of the noise,';
        '\qquad $\rho$ controls the balance of multiplicative versus additive noise,';
        '\qquad $\xi_i(t)$ and $\zeta_i(t)$ are independent Weiner noise processes,';
        '\qquad $i = 1 \dots N$.'
        };
    
    % Include the Time Portrait panel in the GUI
    sys.panels.bdTimePortrait = [];

    % Include the Solver panel in the GUI
    sys.panels.bdSolverPanel = [];     
end

% The deterministic coefficient function
function f = sdeF(~,r,Kij,k,lambda,beta,~,~)  
    n = numel(r);                 % number of nodes
    f = -r.^5 + lambda.*r.^3 + beta.*r + k/n*Kij*r;
end

% The noise coefficient function
function G = sdeG(~,r,~,~,~,~,eta,rho)
    n = numel(r);                 % number of nodes
    I1 = eye(n).*(1-rho).*eta;    % eta * (1-rho)
    I2 = diag(r).*rho.*eta;       % eta * rho * r   
    G = [I1, I2];                 % return G as (n x 2n) matrix
end
