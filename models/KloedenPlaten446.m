% KloedenPlaten446 SDE equation (4.46) from Kloeden and Platen (1992)
%   An explicitly solvable Ito SDE from Kloeden and Platen (1992)  
%     dy = -(a + y*b^2)*(1-y^2)*dt + b(1-y^2)*dW
%
% Example:
%   sys = KloedenPlaten446();       % construct the system struct
%   gui = bdGUI(sys);               % open the Brain Dynamics GUI
%
% Authors
%   Matthew Aburn (2016a)
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
function sys = KloedenPlaten446()
    % Handles to our SDE functions
    sys.sdeF = @sdeF;               % deterministic part
    sys.sdeG = @sdeG;               % stochastic part
    
    % Our SDE parameters
    sys.pardef = [ struct('name','a', 'value',1.0);
                   struct('name','b', 'value',0.8) ];

    % Our SDE variables           
    sys.vardef = struct('name','y', 'value',0.1);
    
    % Default time span
    sys.tspan = [0 5];
    
    % Specify SDE solvers and default options
    sys.sdesolver = {@sdeEM,@sdeSH};    % Relevant SDE solvers
    sys.sdeoption.InitialStep = 0.005;  % SDE solver step size (optional)
    sys.sdeoption.NoiseSources = 1;     % Number of Wiener noise processes

    % Include the Latex (Equations) panel in the GUI
    sys.panels.bdLatexPanel.title = 'Equations'; 
    sys.panels.bdLatexPanel.latex = {'\textbf{KloedenPlaten446}';
        '';
        'Ito Stochastic Differential Equation (4.46) from Kloeden and Platen (1992)';
        '\qquad $dy = -(a + y\,b^2)(1-y^2)\,dt + b(1-y^2)\,dW_t$';
        'where';
        '\qquad $y(t)$ is the dynamic variable,';
        '\qquad $a$ and $b$ are scalar constants.';
        '';
        'It has the explicit solution';
        '\qquad $y = A/B$';
        'where';
        '\qquad $A = (1+y_0) \exp(-2at + 2b W_t) + y_0 - 1$';
        '\qquad $B = (1+y_0) \exp(-2at + 2b W_t) - y_0 + 1$';
        '';
        '';
        '\textbf{Reference}';
        'Kloeden and Platen (1992) Numerical Solution of Stochastic Diffrential Equations'; 
        ''};
        
    % Include the Time Portrait panel in the GUI
    sys.panels.bdTimePortrait = [];

    % Include the Solver panel in the GUI
    sys.panels.bdSolverPanel = [];     
end

% The deterministic part of the equation
function f = sdeF(~,y,a,b)  
    f = -(a + y.*b^2).*(1 - y^2);
end

% The stochastic part of the equation
function G = sdeG(~,y,~,b)  
    G = b.*(1 - y^2);
end
