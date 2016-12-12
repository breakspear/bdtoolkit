% Returns all values in xxxdef as one monolithic column vector
% where xxxdef is a cell array of {'name',value} pairs. 
% It applies to pardef, vardef, lagdef and auxdef arrays.
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