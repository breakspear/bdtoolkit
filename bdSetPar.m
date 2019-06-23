%bdSetPar  Write a parameter value into a system structure
%Usage:
%   sys = bdSetPar(sys,'name',val)
%where
%   sys is the system structure containing the parameter definition.
%   'name' is the string name of the parameter (sys.pardef.name).
%   val is its new value (sys.pardef.value)
%
%sys = bdSetPar(sys,'name',val) is equivalent to 
%sys.pardef = bdSetValue(sys.pardef,'name',val)
%  
%SEE ALSO
%  bdSetVar, bdSetLag, bdSetValue, bdSetValues
%
%AUTHORS
%  Stewart Heitmann (2019a)

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
function sys = bdSetPar(sys,name,val)
    switch nargin
        case {0 1 2}
            throwAsCaller(MException('bdSetPar:Syntax','Not enough input arguments'));
        case 3
            if ~isfield(sys,'pardef')
                throwAsCaller(MException('bdSetPar:InvalidSys','Invalid system structure'));
            end
            try
                sys.pardef = bdSetValue(sys.pardef,name,val);
            catch ME
                throwAsCaller(MException('bdSetPar:NotFound',['Name ''' name ''' not found in sys.pardef']));
            end
        otherwise
            throwAsCaller(MException('bdSetPar:Syntax','Too many input arguments'));
    end
end
