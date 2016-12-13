% ito_euler  Solve Ito stochastic ordinary differential equations by Euler-Maruyama method (strong order 0.5).

% Copyright (c) 2016 Matthew Aburn, QIMR Berghofer Medical Research Institute
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


% Syntax:
% sol = ito_euler(f,G,[t0,tf],y0)
% sol = ito_euler(f,G,[t0,tf],y0,options)
% sol = ito_euler(f,G,[t0,tf],y0,dW,options)
% 
% Arguments:
% f	Function handle for drift coefficient function.
% G	Function handle for diffusion coefficient function.
%         f and G define the Ito equation dy = f(t,y)dt + G(t,y)dW 
% y0	A vector of initial conditions.
% dW    Optional array giving a specific realization of the m independent
%         Wiener processes (for advanced use). If not provided, Wiener
%         increments will be generated randomly.
% options  Structure of optional parameters that change the default integration properties.
%
% References:
% G. Maruyama (1955) Continuous Markov processes and stochastic equations
% Kloeden and Platen (1999) Numerical Solution of Differential Equations
function sol = ito_euler(f, G, tspan, y0, varargin)
    p = inputParser;
    p.KeepUnmatched = true;
    addRequired(p, 'f', @(x)isa(x,'function_handle'));
    addRequired(p, 'f', @(x)isa(x,'function_handle'));
    addRequired(p, 'tspan', @(x)validateattributes(x, {'numeric'}, {'size', [2]}));
    addRequired(p, 'y0', @isnumeric);
    addOptional(p, 'dW', false, @isnumeric);
    addParameter(p, 'InitialStep', 0.0005, @(x)isscalar(x)&&x>0);
    parse(p, f, G, tspan, y0, varargin{:});
    h = p.Results.InitialStep;
    dW = p.Results.dW; % false if user did not provide dW
    otherParams = struct2cell(p.Unmatched);
    [d, m] = sdeValidate(f, G, tspan, y0, h, dW, otherParams)
    x = tspan(1):h:tspan(2);
    N = floor((tspan(2) - tspan(1))./h) + 1;
    assert(N==numel(x));
    if isequal(dW, false)
        dW = wiener(N - 1, m, h);
    end
    y = [y0, NaN(d, N)];
    for n = 1:(N-1)
        tn = x(n);
        yn = y(n);
        dWn = dW(n,:)
        y(n+1) = yn + f(tn,yn,otherParams).*h + G(tn,yn,otherParams)*dWn
    end
    sol = struct('x',x,'y',y,'solver','ito_euler')
end
