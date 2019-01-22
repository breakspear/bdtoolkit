function sys = WaveEquation2D(n)
    % WaveEquation2D Wave Equation in two spatial dimensions
    %   The second-order Wave Equation
    %        Dtt U = c^2 (Dxx U + Dyy U)
    %   in two spatial dimesnions.
    %
    % Example:
    %   n = 100;                    % number of spatial nodes
    %   sys = WaveEquation2D(n);    % construct our system
    %   gui = bdGUI(sys);           % run the GUI application
    %
    % Authors
    %   Stewart Heitmann (2019a)
    
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
        'is transformed into a system of first-order ODEs';
        '\qquad $\dot U = V$';
        '\qquad $\dot V = c^2 \; (\partial_{xx} U + \partial_{yy} U)$';
        'where'
        '\qquad $\partial_{xx} U \approx \big( U_{i,j-1} - 2U_{i,j} + U_{i,j+1} \big) / dx^2$';
        '\qquad $\partial_{yy} U \approx \big( U_{i-1,j} - 2U_{i,j} + U_{i+1,j} \big) / dy^2$';
        'are the second-order central differences of the discretised mesh.';
        '';
        num2str([n n],'$U$ and $V$ are both %d x %d arrays in this simulation.');
        'Parameter $c$ is the wave propagation speed.';
        'Parameters $dx$ and $dy$ are the spatial step sizes.';
        'Boundary conditions are periodic';
        };
              
    % Other display panels
    sys.panels.bdSpace2D = [];                                   

              
    % The ODE function; using the precomputed values of Dxx
    function dY = odefun(~,Y,c,dx,dy)
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
    xdomain = linspace(-n*dx/2,+n*dx/2,n);
    ydomain = linspace(-n*dy/2,+n*dy/2,n);
    [x,y] = meshgrid(xdomain,ydomain);
    Y = exp(-x.^2/sigma^2).*exp(-y.^2/sigma^2);
end
