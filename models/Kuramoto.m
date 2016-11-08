% Kuramoto - Coupled Phase Oscillators
%   Constructs a Kuramoto network with n nodes.
%       theta_i' = omega_i + SUM_j Kij*sin(theta_i-theta_j)
%   where 
%       theta is an (nx1) vector of oscillator phases (in radians),
%       omega is an (nx1) vector of natural frequencies (cycles/sec)
%       Kij is an (nxn) matrix of connection weights,
%
% Example:
%   n = 20;                 % number of oscillators
%   sys = Kuramoto(n);      % construct the system struct
%   gui = bdGUI(sys);       % open the Brain Dynamics GUI
%
% Copyright (C) 2016 Stewart Heitmann <heitmann@ego.id.au>
% Licensed under the Academic Free License 3.0
% https://opensource.org/licenses/AFL-3.0
%
function sys = Kuramoto(n)
    % Construct the default connection matrix (a chain in this case)
    Kij = circshift(eye(n),1) + circshift(eye(n),-1);

    % Construct the system struct
    sys.odefun = @odefun;                   % Handle to our ODE function
    sys.pardef = {'Kij', Kij;               % ODE parameters {'name',value}
                  'k',1;               
                  'omega',randn(n,1)};
    sys.vardef = {'theta',2*pi*rand(n,1)};  % ODE variables {'name',value}
    sys.solver = {'ode45',                  % pertinent matlab ODE solvers
                  'ode23',
                  'ode113',
                  'ode15s'};
    sys.tspan = [0 100];                    % default time span [begin end]
    sys.odeopt = odeset();                  % default ODE solver options
    sys.texstr = {'\textbf{Kuramoto} \medskip';
                  'Network of Kuramoto Phase-Coupled Oscillators\smallskip';
                  '\qquad $\dot \theta_i = \omega_i + \frac{k}{n} \sum_j K_{ij} \sin(\theta_i - \theta_j)$ \smallskip';
                  'where \smallskip';
                  '\qquad $\theta_i$ is the phase of the $i^{th}$ oscillator (radians),';
                  '\qquad $\omega_i$ is its natural oscillation frequency (cycles/sec),';
                  '\qquad $K$ is the connectivity matrix ($n$ x $n$),';
                  '\qquad $k$ is a scaling constant,';
                  '\qquad $i,j=1 \dots n$. \medskip';
                  'Notes';
                  ['\qquad 1. This simulation has $n{=}',num2str(n),'$ oscillators. \medskip']};
end

% Kuramoto ODE function where
% theta is a (1xn) vector of oscillator phases,
% Kij is either a scalar or an (nxn) matrix of connection weights,
% k is a scalar,
% omega is either a scalar or (1xn) vector of oscillator frequencies.
function dtheta = odefun(t,theta,Kij,k,omega)
    n = numel(theta);
    theta_i = theta * ones(1,n);                        % (nxn) matrix with same theta values in each row
    theta_j = ones(n,1) * theta';                       % (nxn) matrix with same theta values in each col
    theta_ij = theta_i - theta_j;                       % (nxn) matrix of all possible (theta_i - theta_j) combinations
    dtheta = omega + k/n.*sum(Kij.*sin(theta_ij),1)';   % Kuramoto Equation in vector form.
end
