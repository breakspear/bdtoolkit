%bdGetVar  Read a state variable from a system structure
%Usage:
%   [val,idx,solidx] = bdGetVar(sys,'name')
%where
%   sys is the system structure containing the state variable definition.
%   'name' is the string name of the state variable (sys.vardef(idx).name).
%   val is its corresponding value (sys.vardef(idx).value).
%   idx is its index in the vardef array.
%   solidx is the corresponding indices of the variable in the sol.y structure.
%   All output parameters are returned empty if no matching name was found.
%
%bdGetVar(sys) displays the names of all state variables in sys.
%bdGetVar(sys,'name') is equivalent to bdGetValue(sys.vardef,'name').
%  
%SEE ALSO
%  bdGetPar, bdGetLag, bdGetValue, bdGetValues
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
function [val,idx,solidx] = bdGetVar(sys,name)
    switch nargin
        case 0
            throwAsCaller(MException('bdGetVar:Syntax','Not enough input arguments'));
            
        case 1
            if isfield(sys,'vardef')
                disp({sys.vardef.name});
            end
            
        case 2
            val = [];
            solidx = 0;
            nvar = numel(sys.vardef);
            for idx=1:nvar
                val = sys.vardef(idx).value;
                len = numel(val);
                if strcmp(sys.vardef(idx).name,name)==1
                    % match found
                    solidx = solidx + [1:len];
                    return
                end
                solidx = solidx + len;
            end

            % no match found
            val = [];
            idx = [];
            solidx = [];

        otherwise
            throwAsCaller(MException('bdGetVar:Syntax','Too many input arguments'));
    end
end
