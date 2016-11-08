function sys = SwiftHohenberg(n,dx)
    % SwiftHohenberg  Discretised Partial Differential Equation
    %   The Swift-Hohenberg problem
    %        d_t u(x,t) = -(1+d_x^2) u(x,t) - mu*u + nu*u^3 - u^5
    %   discretised in space as a set of coupled ODEs
    %        U' = -(I+Dxx)^2 * U - mu*U + nu*U.^3 - U.^5
    %   where the Laplacian operator Dxx is an nxn matrix
    %        Dxx(i,j) = (U(i+1,j) - 2U(i,j) + U(i+1,j) )/h^2 
    %   and h is the spatial step (dx).

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

    % Precompute (part of) the Laplacian, assuming periodic boundary conditions.
    Dxx = sparse( circshift(eye(n),1) -2*eye(n) + circshift(eye(n),-1) );
    
    % Precompute the identity matrix
    Ix = speye(n);
    
    % Initial conditions
    x = [1:n]'*dx - (n+1)*dx/2;             % spatial domain, centered on x=0
    U0  = (-tanh(x-8) + tanh(x+8)).*cos(x)+2.0;
    
    % Construct the system struct
    sys.odefun = @odefun;                   % Handle to our ODE function
    sys.pardef = {'mu',1.5;                 % ODE parameters {'name',value}
                  'nu',3.0;
                  'dx',0.25};
    sys.vardef = {'U',U0};                  % ODE variables {'name',value}
    sys.solver = {'ode45','ode23','ode113'};% pertinent matlab ODE solvers
    sys.odeopt = odeset();     % default ODE solver options
    sys.tspan = [0 20];                     % default time span
    sys.texstr = {'\textbf{SwiftHohenberg1D} \medskip';
                  'Spatially discretized Swift-Hohenberg partial differential equation \smallskip';
                  '\qquad $\dot U = -(I + D_{xx})^2 U - \mu U + \nu U^3 - U^5$ \smallskip';
                  'where \smallskip';
                  '\qquad $I$ is the Identity matrix,';
                  '\qquad $D_{xx}$ is the Laplacian operator,';
                  '\qquad $\mu$ and $nu$ are scalar constants, \medskip';
                  'Notes';
                  '\qquad 1. $D_{xx,i} = \big( U_{i+1} - 2U_{i} + U_{i+1} \big) / dx^2$.';
                  '\qquad 2. $dx$ is the step size of the spatial discretization,';
                  '\qquad 3. Boundary conditions are periodic.';
                  ['\qquad 4. This simulation has $n{=}',num2str(n),'$. \medskip'];
                  'Adapted from Avitabile (2016) Numerical computation of coherent';
                  'structures in spatially-extended neural networks. ICMNS 2016, Antibes'};
              
    % The ODE function; using the precomputed values of Ix and Dxx
    function dU = odefun(t,U,mu,nu,dx)
        % Swift-Hoehenberg equation
        dU = -(Ix + Dxx./dx^2)^2 * U - mu*U + nu*U.^3 - U.^5;
    end

end
   