% sdeValidate  Check user-supplied functions and return the number of dimensions
% and number of driving Wiener processes for an Ito or Stratonovich stochastic
% differential equation.

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
% [d,m] = sdeValidate(f,G,[t0,tf],y0)
% [d,m] = sdeValidate(f,G,[t0,tf],y0,h,dW)
% 
% Arguments:
% f	Function handle for drift coefficient function.
% G	Function handle for diffusion coefficient function.
%         f and G define the Ito equation dy = f(t,y)dt + G(t,y)dW 
% tspan [t0, tf] start and end times
% y0	A vector of initial conditions.
% h     The constant integration time step.
% dW    Optional array giving a specific realization of the m independent
%         Wiener processes (for advanced use).
function [d,m] = sdeValidate(f, G, tspan, y0, h, dW, otherParams)
    assert(isnumeric(tspan),'tspan must be numeric.');
    assert(size(tspan,1)==1 && size(tspan,2)==2,'tspan must be a 1x2 vector.');
    assert(isnumeric(y0), 'The initial condition y0 must be numeric.');
    assert(size(y0,2)==1, 'The initial condition y0 must be a column vector.');
    % determine dimension d of the system
    d = size(y0,1);
    assert(isa(f,'function_handle'), 'f must be a function handle.');
    ftest = f(tspan(1), y0, otherParams);
    assert(isnumeric(ftest) && size(ftest,2)==1, 'f must return a column vector.');
    assert(size(y0,1)==size(ftest,1), 'y0 and f have incompatible shapes.');
    % determine number of driving noise processes m
    assert(isa(G,'function_handle'), 'G must be a function handle.');
    Gtest = G(tspan(1), y0, otherParams);
    assert(isnumeric(Gtest), 'G must return a numeric scalar or matrix.');
    assert(size(y0,1)==size(Gtest,1), 'y0 and G have incompatible shapes.');
    m = size(Gtest,2);
    message = [ ...
        'From function G, it seems m=', m, '. If present the optional '...
        'parameter dW must be a numeric array of size [N-1, m] giving m '...
        'independent Wiener increments for each of N-1 time intervals.'...
    ];
    if exist('dW','var') && ~isempty(dW) && ~isequal(dW, false)
        assert(exist('h','var'), 'If dW is given then h must also be given');
        assert(isscalar(h), 'The time step h must be a scalar.');
        N = floor((tspan(2) - tspan(1))./h) + 1;
        assert(isnumeric(dW), message);
        assert(size(dW,1)==N-1, message);
        assert(size(dW,2)==m, message);
    end
end
