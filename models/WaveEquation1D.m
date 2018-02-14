function sys = WaveEquation1D(n)
    % WaveEquation1D Wave Equation in one spatial dimension
    %   The second-order Wave Equation in one spatial dimension
    %        Dtt U = c^2 Dxx U
    %   converted into a system of first-order equations
    %        U' = V
    %        V' = c^2 dxx V
    %   where U is wave amplitude, V is the speed of the vertical 
    %   displacement and c is the wave propagation speed. 
    %
    % Example:
    %   n = 100;                    % number of spatial nodes
    %   sys = WaveEquation1D(n);    % construct our system
    %   gui = bdGUI(sys);           % run the GUI application
    %
    % Authors
    %   Stewart Heitmann (2016a,2017a,2018a)
    
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

    % Precompute the Laplacian (excluding the dx term)
    switch 2    % edit me
        case 1
            % periodic boundary conditions
            Dxx = sparse( circshift(eye(n),1) -2*eye(n) + circshift(eye(n),-1) );  
        case 2
            % reflecting boundaries
            Dxx = sparse(diag(ones(1,n-1),1) - 2*eye(n) + diag(ones(1,n-1),-1));    
            Dxx(1,2) = 0;
            Dxx(n,n-1) = 0;
        case 3
            % free boundaries
            Dxx = sparse(diag(ones(1,n-1),1) - 2*eye(n) + diag(ones(1,n-1),-1));    
            Dxx(1,1) = -1;
            Dxx(n,n) = -1;
    end
    
    % Initial conditions
    x0 = 0.2*n;
    x1 = 0.4*n;
    U0 = ((1:n)>x0) .* ((1:n)<x1);
    V0 = zeros(n,1);
    
    % Handle to our ODE function
    sys.odefun = @odefun;
    
    % Our ODE parameters
    sys.pardef = [ struct('name','c',  'value',1.0);
                   struct('name','dx', 'value',0.1) ];
    
    % Our ODE variables
    sys.vardef = [ struct('name','U', 'value',U0);
                   struct('name','V', 'value',V0) ];
               
    % Default time span
    sys.tspan = [0 20];
    
    % Specify ODE solvers and default solver options
    sys.odesolver = {@ode45,@ode23,@ode113,@odeEul};
    sys.odeoption.RelTol = 1e-6;
    sys.InitialStep = 0.00001;

    % Include the Latex (Equations) panel in the GUI
    sys.panels.bdLatexPanel.title = 'Equations'; 
    sys.panels.bdLatexPanel.latex = {'\textbf{WaveEquation1D}';
        '';
        'The second-order Wave Equation';
        '\qquad $\partial^2 U/ \partial t^2 = c^2 \; \partial^2 U / \partial x^2$';
        'is a PDE in one spatial dimension, $x \in \mathrm{R}^1.$';
        '';
        'The PDE is transformed into a system of first-order ODEs';
        '\qquad $\dot U = V$';
        '\qquad $\dot V = c^2 \; \partial_{xx} U$';
        'by discretizing space using the method of lines.'
        '';
        'Notes';
        '\qquad 1. $c$ is the wave propagation speed.';
        '\qquad 2. $\partial_{xx} U \approx \big( U_{i+1} - 2U_{i} + U_{i+1} \big) / dx^2$ is the spatial Laplacian.';
        '\qquad 3. $dx$ is the spatial discretization step.';
        ['\qquad 4. $n{=}',num2str(n),'$.']};
              
    % Include the Time Portrait panel in the GUI
    sys.panels.bdTimePortrait.title = 'Time Portrait';
 
    % Include the Space-Time panel in the GUI
    sys.panels.bdSpaceTime.title = 'Space-Time';

    % Include the Solver panel in the GUI
    sys.panels.bdSolverPanel.title = 'Solver';                                   

              
    % The ODE function; using the precomputed values of Dxx
    function dY = odefun(~,Y,c,dx)
        % incoming variables
        Y = reshape(Y,[],2);
        U = Y(:,1);
        V = Y(:,2);
        
        % Second-order Wave Equations. Converted to a system of first-order
        % equations that are discretized in space.
        dV = c^2 * Dxx./dx^2 * U;
        dU = V;
        
        % return result as a vector
        dY = [dU; dV];
    end

end
