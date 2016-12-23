function sys = ReactionDiffusion1D(n)
    % ReactionDiffusion1D  Reaction-Diffusion equations in one spatial dimension
    %   Alan Turing's (1952) reaction-diffusion PDE
    %        d_t A = f(A,B) + d_x^2 A
    %        d_t B = g(A,B) + nu d_x^2 B
    %   in one spatial dimension. The PDE is converted into a set of
    %   coupled ODEs by discretising space using the method of lines.
    %
    % Example:
    %   n = 200;                        % number of spatial points
    %   sys = ReactionDiffusion1D(n);   % construct our system
    %   gui = bdGUI(sys);               % run the Brain Dynamics GUI
    %
    % Authors
    %   Stewart Heitmann (2016a)
    
    % Copyright (C) 2016, QIMR Berghofer Medical Research Institute
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

    % Precompute (part of) the Laplacian, assuming periodic boundary conditions.
    Dxx = sparse( circshift(eye(n),1) -2*eye(n) + circshift(eye(n),-1) );
    
    % Construct the system struct
    sys.odefun = @odefun;                   % Handle to our ODE function
    sys.pardef = {'a',1;                    % ODE parameters {'name',value}
                  'b',2;
                  'nu',1;
                  'dx',1};
    sys.vardef = {'A',rand(n,1);            % ODE variables {'name',value}
                  'B',rand(n,1)};
    sys.tspan = [0 20];                     % default time span

    % Specify ODE solvers and default options
    sys.odesolver = {@ode45,@ode23,@ode113};     % ODE solvers
    sys.odeoption = odeset('RelTol',1e-6);       % ODE solver options

    % Include the Latex (Equations) panel in the GUI
    sys.gui.bdLatexPanel.title = 'Equations'; 
    sys.gui.bdLatexPanel.latex = {'\textbf{ReactionDiffusion1D}';
        '';
        'Turings''s (1952) reaction-diffusion equations';
        '\qquad $\dot A = f(A,B) + \partial^2 A / \partial x^2$';
        '\qquad $\dot B = g(A,B) + \nu \; \partial^2 B / \partial x^2$';
        'where';
        '\qquad $A(x,t)$ is the activator,';
        '\qquad $B(x,t)$ is the inhibitor,';
        '\qquad $f(A,B)$ is the production rate of the activator,';
        '\qquad $g(A,B)$ is the production rate of the inhibitor,';
        '\qquad $\nu$ is the diffusion coefficient.';
        'It is assumed that $f$ and $g$ are linear near equilibrium,';
        '\qquad $f(A,B) = a A - B$,';
        '\qquad $g(A,B) = b A - B$.';
        'Hence this is not a pattern-forming system but rather';
        'a study of when the uniform solution loses stability.';
        '';
        'Notes';
        '\qquad 1. $\partial^2 A / \partial x^2 \approx \big( A_{i+1} - 2A_{i} + A_{i+1} \big) / dx^2$.';
        '\qquad 2. $dx$ is the spatial discretization step,';
        '\qquad 3. Boundary conditions are periodic.';
        '\qquad 5. The uniform solution is unstable for $a{>}b$';
        '\qquad 6. Limit cycles occur for $a{<}b$';
        ['\qquad 7. $n{=}',num2str(n),'$.'];
        '';
        'References';
        '\qquad Turing (1952) The chemical basis of morphogenesis' };

    % Include the Time Portrait panel in the GUI
    sys.gui.bdTimePortrait.title = 'Time Portrait';
 
    % Include the Phase Portrait panel in the GUI
    sys.gui.bdPhasePortrait.title = 'Phase Portrait';

    % Include the Space-Time Portrait panel in the GUI
    sys.gui.bdSpaceTimePortrait.title = 'Space-Time';

    % Include the Solver panel in the GUI
    sys.gui.bdSolverPanel.title = 'Solver';         
        
    % Function hook for the GUI System-New menu
    sys.self = @self;    

    
    % The ODE function; using the precomputed values of Dxx
    function dY = odefun(~,Y,a,b,nu,dx)
        % incoming variables
        Y = reshape(Y,[],2);
        A = Y(:,1);
        B = Y(:,2);
        
        % rate equations
        f = a*A - B;
        g = b*A - B;
        
        % Reaction-Diffusion Equations
        dA = f + Dxx./dx^2 * A;
        dB = g + nu * Dxx./dx^2 * B;
        
        % return result as a vector
        dY = [dA;dB];
    end

end
   
% This function is called by the GUI System-New menu
function sys = self()
    % open a dialog box prompting the user for the value of n
    n = bdEditScalars({100,'number of spatial points'}, ...
        'New System', 'ReactionDiffusion1D');
    % if the user cancelled then...
    if isempty(n)
        sys = [];                       % return empty sys
    else
        sys = ReactionDiffusion1D(round(n));  % generate a new sys
    end
end
