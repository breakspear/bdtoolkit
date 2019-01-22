function sys = WaveEquation1D(n,bflag)
    % WaveEquation1D Wave Equation in one spatial dimension
    %   The second-order Wave Equation in one spatial dimension
    %        Dtt U = c^2 Dxx U
    %   converted into a system of first-order equations
    %        U' = V
    %        V' = c^2 dxx V
    %   where U is wave amplitude, V is the speed of the vertical 
    %   displacement and c is the wave propagation speed. 
    %
    % Usage:
    %   sys = WaveEquation1D(n,bflag)
    % where
    %   n is the number of nodes
    %   bflag defines the boundary conditions. Valid values are
    %      'periodic', 'reflecting', 'free'.
    %
    % Example:
    %   n = 100;                        % number of spatial nodes
    %   bflag = 'periodic';             % periodic boundaries
    %   sys = WaveEquation1D(n,bflag);  % construct our system
    %   gui = bdGUI(sys);               % run the GUI application
    %
    % Authors
    %   Stewart Heitmann (2016a,2017a,2018a,2019a)
    
    % Copyright (C) 2016-2019 QIMR Berghofer Medical Research Institute
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
    switch bflag    % edit me
        case 'periodic'
            % periodic boundary conditions
            Dxx = sparse( circshift(eye(n),1) -2*eye(n) + circshift(eye(n),-1) );  
        case 'reflecting'
            % reflecting boundaries
            Dxx = sparse(diag(ones(1,n-1),1) - 2*eye(n) + diag(ones(1,n-1),-1));    
            Dxx(1,2) = 0;
            Dxx(n,n-1) = 0;
        case 'free'
            % free boundaries
            Dxx = sparse(diag(ones(1,n-1),1) - 2*eye(n) + diag(ones(1,n-1),-1));    
            Dxx(1,1) = -1;
            Dxx(n,n) = -1;
        otherwise
            error('bflag must be ''periodic'', ''reflecting'' or ''free''');
    end
    
    % Handle to our ODE function
    sys.odefun = @odefun;
    
    % Our ODE parameters
    dx = 1;
    sys.pardef = [ 
        struct('name','c',  'value',10, 'lim',[0 20])
        struct('name','dx', 'value',dx, 'lim',[0.5 10])
        ];
    
    % Initial conditions
    U0 = 2*Gauss1D(n,dx,n/20);
    V0 = zeros(n,1);
    
    % Our ODE variables
    sys.vardef = [
        struct('name','U', 'value',U0, 'lim',[-0.5 2])
        struct('name','V', 'value',V0, 'lim',[-0.5 2])
        ];
               
    % Default time span
    sys.tspan = [0 20];
    
    % Specify ODE solvers and default solver options
    sys.odesolver = {@ode45,@ode23,@ode113,@odeEul};
    sys.odeoption.RelTol = 1e-6;
    sys.InitialStep = 0.00001;

    % Include the Latex (Equations) panel in the GUI
    sys.panels.bdLatexPanel.title = 'Equations'; 
    sys.panels.bdLatexPanel.latex = {
        '\textbf{WaveEquation1D}';
        '';
        'The second-order Wave Equation in one spatial dimension';
        '\qquad $\partial^2 U/ \partial t^2 = c^2 \; \partial^2 U / \partial x^2$';
        'is transformed into a system of first-order ODEs';
        '\qquad $\dot U = V$';
        '\qquad $\dot V = c^2 \; \partial_{xx} U$';
        'where'
        '\qquad $\partial_{xx} U \approx \big( U_{i-1} - 2U_{i} + U_{i+1} \big) / dx^2$';
        'is the second-order central difference approximation of the Laplacian.';
        '';
        num2str(n,'$U$ and $V$ are both nx1 vectors where n=%d in this simulation.');
        'Parameter $c$ is the wave propagation speed.';
        'Parameter $dx$ is the spatial step sizes.';
        ['Boundary conditions are ' bflag '.'];
        };
              
    % Include the Space-Time panel in the GUI
    sys.panels.bdSpaceTime.title = 'Space-Time';
              
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

% Gaussian function
function Y = Gauss1D(n,dx,sigma)
    x = linspace(-n*dx/3,+2*n*dx/3,n);
    Y = exp(-x.^2/sigma^2);
end

