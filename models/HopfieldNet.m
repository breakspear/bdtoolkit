% HopfieldNet  Continuous Hopfield betwork
%   Constructs a continuous Hopfield network with n nodes.
%       tau * V' = -V + W*F(V) + I
%   where V is (nx1) vector on neuron potentials,
%   W is (nxn) matrix of connection weights,
%   I is (nx1) vector of injection currents,
%   F(V)=tanh(b*V) with slope parameter b.
%
% Example:
%   n = 20;                 % number of neurons
%   sys = HopfieldNet(n);   % construct the system struct
%   gui = bdGUI(sys);       % open the Brain Dynamics GUI
%

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
function sys = HopfieldNet(n)
    % Random symmetric connection matrix with no self coupling
    Wij = 0.5*rand(n);      % random connections
    Wij = Wij + Wij';       % force symmetry
    Wij(1:n+1:end) = 0;     % zero the diagonal
    
    % Construct the system struct
    sys.odefun = @odefun;               % Handle to our ODE function
    sys.pardef = {'Wij',Wij;            % ODE parameters {'name',value}
                  'Iapp',rand(n,1);
                  'b',1;
                  'tau',10};
    sys.vardef = {'V',rand(n,1)};       % ODE variables {'name',value}
    sys.solver = {'ode45'};             % pertinent matlab ODE solvers
    sys.odeopt = odeset();              % default ODE solver options
    sys.tspan = [0 200];               % default time span [begin end]
    sys.texstr = {'\textbf{HopfieldNet} \medskip';
                  'The Continuous Hopfield Network \smallskip';
                  '\qquad $\tau \dot V_i = -V_i + \sum_j W_{ij} \tanh(b\, V_i) + I_{app}$ \smallskip';
                  'where \smallskip';
                  '\qquad $V$ is the firing rate of each neuron ($n$ x $1$),';
                  '\qquad $K$ is the connectivity matrix ($n$ x $n$),';
                  '\qquad $b$ is a slope parameter,';
                  '\qquad $I_{app}$ is the applied current ($n$ x $1$),';
                  '\qquad $i{=}1 \dots n$. \medskip';
                  'Notes';
                  ['\qquad 1. This simulation has $n{=}',num2str(n),'$.']};

end

% The ODE function.
function dV = odefun(t,V,Wij,Ii,b,tau)  
    dV = (-V + Wij*tanh(b*V) + Ii)./tau;
end
