%bdGetValues  Read all values from a pardef/vardef/lagdef cell array. 
%   Returns all values in xxxdef as one monolithic column vector
%Usage:
%   Y = bdGetValues(xxxdef)
%where
%   xxxdef is a pardef, vardef, lagdef or auxdef cell array.
%
%EXAMPLE
%  vardef = {'a',1; 'b',[2 3 4]; 'c',5};
%  Y0 = bdGetValues(vardef)
%
%  Y0 =
%     1
%     2
%     3
%     4
%     5
%
%AUTHORS
%  Stewart Heitmann (2016a)

% Copyright (C) 2016, QIMR Berghofer Medical Research Institute
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
    % extract the second column of vardef
    vec = xxxdef(:,2);

    % convert each cell entry to a column vector
    for indx=1:numel(vec)
        vec{indx} = reshape(vec{indx},[],1);
    end

    % concatenate the column vectors to a simple vector
    vec = cell2mat(vec);
end
