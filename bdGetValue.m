% bdGetValue  Get the value of a named entry in xxxdef 
function val = bdGetValue(xxxdef,name)
    val = [];
    nvar = size(xxxdef,1);
    for indx=1:nvar
        if strcmp(xxxdef{indx,1},name)==1
            val = xxxdef{indx,2};
            return
        end
    end
    warning('bdUtils.getValue() failed to find a matching name');
end
