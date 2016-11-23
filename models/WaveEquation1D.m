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
    
    % Copyright (c) 2016, Stewart Heitmann <heitmann@ego.id.au>
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

    % Precompute the Laplacian (excluding the dx term),
    % ... assuming periodic boundary conditions.
    %Dxx = sparse( circshift(eye(n),1) -2*eye(n) + circshift(eye(n),-1) );  
    % ... assuming open boundaries
    Dxx = sparse(diag(ones(1,n-1),1) - 2*eye(n) + diag(ones(1,n-1),-1));
    
    % Initial conditions
    x0 = 0.4*n;
    x1 = 0.6*n;
    U0 = ((1:n)>x0) .* ((1:n)<x1);
    V0 = zeros(n,1);
    
    % Construct the system struct
    sys.odefun = @odefun;                   % Handle to our ODE function
    sys.pardef = {'c',1;                    % ODE parameters {'name',value}
                  'dx',0.1};
    sys.vardef = {'U',U0;                   % ODE variables {'name',value}
                  'V',V0};
    sys.solver = {'ode45',                  % matlab ODE solvers
                  'ode23',
                  'ode113'};
    sys.odeopt = odeset('RelTol',1e-6);     % default ODE solver options
    sys.tspan = [0 20];                     % default time span
    sys.texstr = {'\textbf{WaveEquation1D} \medskip';
                  'The second-order Wave Equation in one spatial dimension\smallskip';
                  '\qquad $\partial^2 U/ \partial t^2 = c^2 \; \partial^2 U / \partial x^2$ \smallskip';
                  'transformed into a system of first-order equations\smallskip';
                  '\qquad $\dot U = V$ \smallskip';
                  '\qquad $\dot V = c^2 \; \partial_{xx} U$ \smallskip';
                  'where $c$ is the wave propagation speed.\medskip';
                  'Notes';
                  '\qquad 1. $\partial_{xx} U \approx \big( U_{i+1} - 2U_{i} + U_{i+1} \big) / dx^2$ is the spatial Laplacian.';
                  '\qquad 2. $dx$ is the spatial discretization step.';
                  ['\qquad 3. $n{=}',num2str(n),'$. \medskip']};
              
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
   