% bdSetValue  Set the value of a named entry in xxxdef 
function yyydef = bdSetValue(xxxdef,name,val)
    yyydef = xxxdef;
    nvar = size(yyydef,1);
    for indx=1:nvar
        if strcmp(yyydef{indx,1},name)==1
            yyydef{indx,2} = val;
            return
        end
    end
    warning([name, ' not found in xxxdef']);
end
