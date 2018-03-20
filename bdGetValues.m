%bdGetValues  Read all values from a pardef/vardef/lagdef cell array. 
%   Returns the contents of all xxxdef.value fields as single monolithic
%   column vector
%Usage:
%   Y = bdGetValues(xxxdef)
%where
%   xxxdef is any array of structs that contains a field called 'value', 
%       such as sys.vardef, sys.pardef and sys.lagdef.
%
%EXAMPLE
%   vardef = [ struct('name','a', 'value',1);
%              struct('name','b', 'value',[2 3 4]);
%              struct('name','c', 'value',[5 7 9 11; 6 8 10 12]);
%              struct('name','d', 'value',13); ];
%   Y0 = bdGetValues(vardef)
%
%   Returns Y0 as the column vector [1:13]'
%
%AUTHORS
%  Stewart Heitmann (2016a,2017a)

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

function vec = bdGetValues(xxxdef)
    % extract the value fields of vardef as a cell array
    vec = {xxxdef.value}';

    % convert each cell entry to a column vector
    for indx=1:numel(vec)
        vec{indx} = reshape(vec{indx},[],1);
    end

    % concatenate the column vectors to a simple vector
    vec = cell2mat(vec);
end
