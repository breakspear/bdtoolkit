% SDEdemo3
% Copyright (c) 2016, Matthew Aburn, QIMR Berghofer Medical Research Institute
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
function sys = SDEdemo3()
    % Construct the system struct
    sys.odefun = @odefun;           % Handle to our deterministic function
    sys.sdefun = @sdefun;           % Handle to our stochastic function
    sys.pardef = {'a', 1.0;         % SDE parameters {'name',value}
                  'b', 0.8};
    sys.vardef = {'y', 0.1};        % SDE variables {'name',value}
    sys.tspan = [0 5];              % default time span
    
    % Specify SDE solvers and default options
    sys.sdesolver = {@sde00};           % Pertinent SDE solvers
    sys.sdeoption.InitialStep = 0.005;  % SDE solver step size (optional)
    sys.sdeoption.NoiseSources = 1;     % Number of Weiner noise processes

    % Include the Latex (Equations) panel in the GUI
    sys.gui.bdLatexPanel.title = 'Equations'; 
    sys.gui.bdLatexPanel.latex = {'\textbf{SDEdemo3}';
        'An Ito stochastic differential equation';
        '\qquad $dy = -(a + y\,b^2)(1-y^2)\,dt + b(1-y^2)\,dW_t$';
        'where';
        '\qquad $y(t)$ is the dynamic variable,';
        '\qquad $a$ and $b$ are scalar constants,';
        '\qquad $dW_t$ is a Weiner process.'};
    
    % Include the Time Portrait panel in the GUI
    sys.gui.bdTimePortrait.title = 'Time Portrait';

    % Include the Solver panel in the GUI
    sys.gui.bdSolverPanel.title = 'Solver';                       
end

% The deterministic coefficient function
function f = odefun(t,y,a,b)  
    f = -(a + y.*b^2).*(1 - y^2);
end

% The noise coefficient function.
function G = sdefun(t,y,a,b)  
    G = b.*(1 - y^2);
end
