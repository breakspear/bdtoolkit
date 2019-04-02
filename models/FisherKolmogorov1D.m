function sys = FisherKolmogorov1D(n,bflag)
    % FisherKolmogorov1D The Fisher-Kolmogorov equation
    %   The Fisher-Kolmogorov equation in one spatial dimension
    %        Ut = D Uxx + r U (1-u)
    %   where U(x,t) is the density of the medium, D is diffusion constant,
    %   and r is the proliferation rate.
    %
    % Usage:
    %   sys = FisherKolmogorov1D(n,bflag)
    % where
    %   n is the number of nodes
    %   bflag defines the boundary conditions. Valid values are
    %      'periodic', 'reflecting' and 'free'.
    %
    % Example:
    %   n = 200;                            % number of spatial nodes
    %   bflag = 'periodic';                 % periodic boundaries
    %   sys = FisherKolmogorov1D(n,bflag);  % construct our system
    %   gui = bdGUI(sys);                   % run the GUI application
    %
    % Authors
    %   Stewart Heitmann (2019a)
    
    % Copyright (C) 2019 Stewart Heitmann
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
            error('bflag must be ''periodic'', ''reflecting'' or ''free''');
    end
    
    % Our ODE parameters
    dx = 1;
    sys.pardef = [ 
        struct('name','D',  'value',1,  'lim',[0 10])
        struct('name','r',  'value',1,  'lim',[0 10])
        struct('name','dx', 'value',dx, 'lim',[0.1 10])
        ];
    
    % Initial conditions
    U0 = 2*Gauss1D(n,dx,n/20);
    
    % Our ODE variables
    sys.vardef = [
        struct('name','U', 'value',U0, 'lim',[0 1])
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
        '\textbf{FisherKolmogorov1D}'
        ''
        'The Fisher-Kolmogorov equation in one spatial dimension'
        '\qquad $\partial U/ \partial t = D \; \partial^2 U / \partial x^2 + r \; U \; (1-U)$'
        'where'
        '\qquad $U(x,t)$ is the density of the medium,'
        '\qquad $D$ is the diffusion coefficient,'
        '\qquad $r$ is the proliferation rate.'
        ''
        num2str(n,'Space is discretised into $n{=}%d$ nodes using the method of lines.')
        ''
        'The Laplacian is approximated by the second-order central-difference'
        '\qquad $\partial_{xx} U \approx \big( U_{i-1} - 2U_{i} + U_{i+1} \big) / dx^2$'
        ['with ' bflag ' boundary conditions.'];
        ''
        '\textbf{References}'
        'Fisher (1937) The wave of advantageous genes. Annals of Eugenics. 7(4)'
        'Kolmogorov, Petrovski \& Piskunov (1937) Selected works of A.N. Kolmogorov I. p248-270'
        };
              
    % Include the Space-Time panel in the GUI
    sys.panels.bdSpaceTime.title = 'Space-Time';
              
    % The ODE function
    function dU = odefun(~,U,D,r,dx)
        % Fisher-Kolmogorov Equation
        dU = D .* Dxx * U./(dx^2) + r.*U.*(1-U);
    end
end

% Gaussian function
function Y = Gauss1D(n,dx,sigma)
    x = linspace(-n*dx/3,+2*n*dx/3,n);
    Y = exp(-x.^2/sigma^2);
end