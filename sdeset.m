% sdeset  Create or alter options structure for stochastic differential equation solvers.

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
% options = sdeset('name1',value1,'name2',value2,...)
% options = sdeset(oldopts,'name1',value1,...)
% options = sdeset(oldopts,newopts)
% sdeset
% 
% Properties:
% InitialStep - Initial step size [ positive scalar ]
%    Currently this will set the fixed step size used for all steps.
function options = sdeset(varargin)
    if nargin < 1
        disp('InitialStep: [ positive scalar ]')
    elseif mod(nargin, 2) ~= 0
        error('Arguments must occur in name-value pairs.')
    else
        options = struct('InitialStep',[]);
        for i = 1:2:(nargin-1)
            name = varargin{i};
            value = varargin{i+1};
            if ~strcmp(name,'InitialStep')
                error('Unrecognized property name ''%s''.',name)
            else
                if ~isscalar(value) || value<=0 
                    error('InitialStep must be a positive scalar.')
                else
                    options.(name) = value;
                end
            end
        end
    end
end
