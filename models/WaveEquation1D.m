function sys = WaveEquation1D(n,bflag)
    % WaveEquation1Db The 1D Wave Equation
    %   The second-order Wave Equation in one spatial dimension
    %        Utt = c^2 Uxx
    %   converted into a system of first-order equations
    %        Ut = V
    %        Vt = c^2 Uxx
    %   where U is wave amplitude, V is the speed of the vertical 
    %   displacement and c is the wave propagation speed. 
    %
    % Usage:
    %   sys = WaveEquation1D(n,bflag)
    % where
    %   n is the number of nodes
    %   bflag defines the boundary conditions. Valid values are
    %      'periodic', 'reflecting', 'free' and 'absorbing'.
    %
    % Example:
    %   n = 200;                        % number of spatial nodes
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

    
    % Handle to our ODE function
    sys.odefun = @odefun;

    % Precompute the Laplacian (excluding the dx term)
    switch bflag
        case 'periodic'
            % periodic boundary conditions
            % Dxx = [-2  1  0  1 ]
            %       [ 1 -2  1  0 ]
            %       [ 0  1 -2  1 ]
            %       [ 1  0  1 -2 ]
            Dxx = sparse( circshift(eye(n),1) -2*eye(n) + circshift(eye(n),-1) );  
        case 'absorbing'
            % periodic boundary conditions + odefun2
            Dxx = sparse( circshift(eye(n),1) -2*eye(n) + circshift(eye(n),-1) );  
            sys.odefun = @odefun2;
        case 'reflecting'
            % reflecting boundaries
            % Dxx = [-2  0  0  0 ]
            %       [ 1 -2  1  0 ]
            %       [ 0  1 -2  1 ]
            %       [ 0  0  0 -2 ]
            Dxx = sparse(diag(ones(1,n-1),1) - 2*eye(n) + diag(ones(1,n-1),-1));    
            Dxx(1,2) = 0;
            Dxx(n,n-1) = 0;
        case 'free'
            % free boundaries
            % Dxx = [-1  1  0  0 ]
            %       [ 1 -2  1  0 ]
            %       [ 0  1 -2  1 ]
            %       [ 0  0  1 -1 ]
            Dxx = sparse(diag(ones(1,n-1),1) - 2*eye(n) + diag(ones(1,n-1),-1));    
            Dxx(1,1) = -1;
            Dxx(n,n) = -1;
        otherwise
            error('bflag must be ''periodic'', ''reflecting'', ''free'' or ''absorbing''');
    end
    
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
    sys.odesolver = {@ode45,@ode23};
    sys.odeoption.RelTol = 1e-6;
    sys.InitialStep = 0.00001;

    % Include the Latex (Equations) panel in the GUI
    sys.panels.bdLatexPanel.title = 'Equations'; 
    sys.panels.bdLatexPanel.latex = {
        '\textbf{WaveEquation1D}';
        '';
        'The second-order Wave Equation in one spatial dimension';
        '\qquad $\partial^2 U/ \partial t^2 = c^2 \; \partial^2 U / \partial x^2$';
        'where $c$ is the wave propagation speed.';
        'The system is transformed into a system of first-order ODEs';
        '\qquad $\dot U = V$';
        '\qquad $\dot V = c^2 \; \partial_{xx} U$';
        num2str(n,'with space discretised into $n{=}%d$ nodes using the method lines.');
        '';
        'The Laplacian is approximated by the second-order central-difference'
        '\qquad $\partial_{xx} U \approx \big( U_{i-1} - 2U_{i} + U_{i+1} \big) / dx^2$';
        ['with ' bflag ' boundary conditions.'];
        };
              
    % Include the Space-Time panel in the GUI
    sys.panels.bdSpaceTime.title = 'Space-Time';
              
    % The ODE function
    function dY = odefun(~,Y,c,dx)
        % incoming variables
        Y = reshape(Y,[],2);
        U = Y(:,1);
        V = Y(:,2);
        
        % Wave Equation
        dV = c^2 * Dxx*U./(dx^2);
        dU = V;

        % return result as a vector
        dY = [dU; dV];
    end

    % The odefun with absorbing boundary conditions
    function dY = odefun2(~,Y,c,dx)
        % incoming variables
        Y = reshape(Y,[],2);
        U = Y(:,1);
        V = Y(:,2);

        % Wave Equation
        dV = c^2 * Dxx*U./(dx^2);
        dU = V;
        
        % Mur's absorbing boundary
        dU(1) = c*(U(2)-U(1))./dx;
        dU(end) = -c*(U(end)-U(end-1))./dx;      
        
        % return result as a vector
        dY = [dU; dV];
    end

end

% Gaussian function
function Y = Gauss1D(n,dx,sigma)
    x = linspace(-n*dx/3,+2*n*dx/3,n);
    Y = exp(-x.^2/sigma^2);
end

