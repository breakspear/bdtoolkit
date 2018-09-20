%bdSetValues  Write all values in a pardef/vardef/lagdef cell array.
%Usage:
%   yyydef = bdSetValues(xxxdef,vec)
%where
%   xxxdef is the incoming pardef, vardef or lagdef cell array.
%   vec is an array of new values.
%   yyydef is the returned cell array.
%
%EXAMPLE
%  pardef = [ struct('name','a', 'value', 1);
%             struct('name','b', 'value',[2,3,4]);
%             struct('name','c', 'value',[5 6; 7 8]) ];
%  bdGetValues(pardef)
%
%  ans =
%    1 2 3 4 5 6 7 8
%
%  pardef = bdSetValues(pardef,[8 7 6 5 4 3 2 1]);
%  bdGetValues(pardef)
%
%  ans =
%     8 7 6 5 4 3 2 1
%  
%AUTHORS
%  Stewart Heitmann (2018b)

% Copyright (C) 2016-2018 QIMR Berghofer Medical Research Institute
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
function yyydef = bdSetValues(xxxdef,vec)

    % Verify that vec is the correct size for xxxdef
    if numel(vec) ~= numel(bdGetValues(xxxdef))
        yyydef = [];
        throwAsCaller(MException('bdtoolkit:bdSetValues','Number of new values must match the number of values in xxxdef'));
    end

    % Piecewise copy of vec entries into xxxdef.value entries
    yyydef = xxxdef;
    nvar = numel(yyydef);
    offset = 0;
    for indx=1:nvar
        len = numel(yyydef(indx).value);
        yyydef(indx).value(:) = vec([1:len]+offset);
        offset = offset+len;
    end
end
