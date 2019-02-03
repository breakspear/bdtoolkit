function sys = WaveEquation2D(n,bflag)
    % WaveEquation2D The 2D Wave Equation
    %   The second-order Wave Equation in two spatial dimensions
    %        Utt = c^2 (Uxx + Uyy)
    %   converted into a system of first-order equations
    %        Ut = V
    %        Vt = c^2 (Uxx + Uyy)
    %   where U is wave amplitude, V is the speed of the vertical 
    %   displacement and c is the wave propagation speed.
    %
    % Usage:
    %   sys = WaveEquation2D(n,bflag)
    % where
    %   n is the number of nodes
    %   bflag defines the boundary conditions. Valid values are
    %      'periodic', 'reflecting', 'free' and 'absorbing'.
    %
    % Example:
    %   n = 200;                          % number of spatial nodes
    %   bflag = 'periodic';               % periodic boundaries
    %   sys = WaveEquation2D(n,bflag);    % construct our system
    %   gui = bdGUI(sys);                 % run the GUI application
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

    % Return the appropriate ODE function handle for the boundary conditions 
    switch bflag 
        case 'periodic'
            sys.odefun = @odefun1;
        case 'reflecting'
            sys.odefun = @odefun2;
        case 'free'
            sys.odefun = @odefun3;
        case 'absorbing'
            sys.odefun = @odefun4;
        otherwise
            error('bflag must be ''periodic'', ''reflecting'', ''free'' or ''absorbing''');
    end
        
    % Our ODE parameters
    dx = 1;
    dy = 1;
    sys.pardef = [
        struct('name','c',  'value',10)
        struct('name','dx', 'value',dx)
        struct('name','dy', 'value',dy)
        ];
    
    % Gaussian as initial conditions
    U0 = 2*Gauss2D(n,dx,dy,n/20);
    
    % Our ODE variables
    sys.vardef = [
        struct('name','U', 'value',U0,       'lim',[-1 1])
        struct('name','V', 'value',zeros(n), 'lim',[-1 1])
        ];
               
    % Default time span
    sys.tspan = [0 1];
    
    % Specify ODE solvers and default solver options
    sys.odesolver = {@ode45,@ode23};

    % Include the Latex (Equations) panel in the GUI
    sys.panels.bdLatexPanel.title = 'Equations'; 
    sys.panels.bdLatexPanel.latex = {
        '\textbf{WaveEquation2D}';
        '';
        'The second-order Wave Equation in two spatial dimensions';
        '\qquad $\partial^2 U / \partial t^2 = c^2 \; (\partial^2 U / \partial x^2 + \partial^2 U / \partial y^2)$';
        'where $c$ is the wave propagation speed.';
        'The system is transformed into a system of first-order ODEs';
        '\qquad $\dot U = V$';
        '\qquad $\dot V = c^2 \; (\partial_{xx} U + \partial_{yy} U)$';
         num2str([n n],'with space discretised into %d x %d nodes using the method lines.');
        'The Laplacian is approximated by the second-order central-difference'
        '\qquad $\partial_{xx} U \approx \big( U_{i,j-1} - 2U_{i,j} + U_{i,j+1} \big) / dx^2$';
        '\qquad $\partial_{yy} U \approx \big( U_{i-1,j} - 2U_{i,j} + U_{i+1,j} \big) / dy^2$';
        ['with ' bflag ' boundary conditions.'];        
        };
              
    % Other display panels
    sys.panels.bdSpace2D = [];                                   

    % The ODE function with periodic boundary conditions
    % Dxx = [-2  1  0  1 ]
    %       [ 1 -2  1  0 ]
    %       [ 0  1 -2  1 ]
    %       [ 1  0  1 -2 ]
    function dY = odefun1(~,Y,c,dx,dy)
        % incoming variables
        Y = reshape(Y,[n n 2]);     % restore 2D data foemat
        U = Y(:,:,1);               % 1st plane of Y contains U
        V = Y(:,:,2);               % 2nd plane of Y contains V

        % Central difference formulas
        [Uxx,Uyy] = CenterDiff(U,dx,dy);

        % Second-order Wave Equation transformed into a system of first-order equations.
        dV = c^2 * (Uxx + Uyy);
        dU = V;

        % Return a column vector
        dY = reshape( cat(3,dU,dV), [], 1);
    end
              
    % The ODE function with reflecting boundary conditions
    % Dxx = [-2  0  0  0 ]
    %       [ 1 -2  1  0 ]
    %       [ 0  1 -2  1 ]
    %       [ 0  0  0 -2 ]
    function dY = odefun2(~,Y,c,dx,dy)
        % incoming variables
        Y = reshape(Y,[n n 2]);     % restore 2D data foemat
        U = Y(:,:,1);               % 1st plane of Y contains U
        V = Y(:,:,2);               % 2nd plane of Y contains V

        % Central difference formulas
        [Uxx,Uyy] = CenterDiff(U,dx,dy);
        
        % Impose reflecting boundaries
        Uxx(:,1)   = -2*U(:,1) ./ dx^2;
        Uxx(:,end) = -2*U(:,end) ./ dx^2;
        Uyy(1,:)   = -2*U(1,:) ./ dy^2;
        Uyy(end,:) = -2*U(end,:) ./ dy^2;

        % Second-order Wave Equation transformed into a system of first-order equations.
        dV = c^2 * (Uxx + Uyy);
        dU = V;

        % Return a column vector
        dY = reshape( cat(3,dU,dV), [], 1);
    end

    % The ODE function with free boundary conditions
    % Dxx = [-1  1  0  0 ]
    %       [ 1 -2  1  0 ]
    %       [ 0  1 -2  1 ]
    %       [ 0  0  1 -1 ]
    function dY = odefun3(~,Y,c,dx,dy)
        % incoming variables
        Y = reshape(Y,[n n 2]);     % restore 2D data foemat
        U = Y(:,:,1);               % 1st plane of Y contains U
        V = Y(:,:,2);               % 2nd plane of Y contains V

        % Central difference formulas
        [Uxx,Uyy] = CenterDiff(U,dx,dy);
        
        % Impose free boundaries
        Uxx(:,1)   = ( -U(:,1) + U(:,2) ) ./ dx^2;
        Uxx(:,end) = ( -U(:,end) + U(:,end-1) )./ dx^2;
        Uyy(1,:)   = ( -U(1,:) + U(2,:) )./ dy^2;
        Uyy(end,:) = ( -U(end,:) + U(end-1,:) )./ dy^2;

        % Second-order Wave Equation transformed into a system of first-order equations.
        dV = c^2 * (Uxx + Uyy);
        dU = V;

        % Return a column vector
        dY = reshape( cat(3,dU,dV), [], 1);
    end

    % The ODE function with absorbing boundary conditions
    function dY = odefun4(~,Y,c,dx,dy)
        % incoming variables
        Y = reshape(Y,[n n 2]);     % restore 2D data foemat
        U = Y(:,:,1);               % 1st plane of Y contains U
        V = Y(:,:,2);               % 2nd plane of Y contains V

        % Central difference formulas
        [Uxx,Uyy] = CenterDiff(U,dx,dy);

        % Second-order Wave Equation transformed into a system of first-order equations.
        dV = c^2 * (Uxx + Uyy);
        dU = V;

        % Mur's absorbing boundary conditions
        dU(:,1) = c*(U(:,2)-U(:,1))./dx;
        dU(:,end) = -c*(U(:,end)-U(:,end-1))./dx;
        dU(1,:) = c*(U(2,:)-U(1,:))./dy;
        dU(end,:) = -c*(U(end,:)-U(end-1,:))./dy;

        % Return a column vector
        dY = reshape( cat(3,dU,dV), [], 1);
    end

end

% Central Difference approximation of the Laplacian
function [Uxx,Uyy] = CenterDiff(U,dx,dy)
    W = circshift(U,-1,2);      % West
    E = circshift(U,+1,2);      % East
    N = circshift(U,-1,1);      % North
    S = circshift(U,+1,1);      % South
    Uxx = (W-2*U+E) ./dx^2;     % Dxx U
    Uyy = (S-2*U+N) ./dy^2;     % Dyy U
end

% Gaussian Surface in 2D
function Y = Gauss2D(n,dx,dy,sigma)
    xdomain = linspace(-n*dx*2/3,+n*dx*1/3,n);
    ydomain = linspace(-n*dy*3/5,+n*dy*2/5,n);
    [x,y] = meshgrid(xdomain,ydomain);
    Y = exp(-x.^2/sigma^2).*exp(-y.^2/sigma^2);
end
