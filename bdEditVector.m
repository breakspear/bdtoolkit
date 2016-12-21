function outdata = bdEditVector(data,name,columnName)
    %bdEditVector Dialog box for editing vector data.
    %Usage:
    %    outdata = bdEditVector(indata,name,columnName)
    %where
    %    'indata' is the initial vector data (nx1)
    %    'name' is the title of the dialog box (text)
    %    'columnName' is the title of the data column (text)
    %Returns the edited data in 'outdata'. If the user cancels the operation
    %then the returned data is identical to the initial data. 
    %
    %AUTHORS
    %  Stewart Heitmann (2016a)

    % Copyright (c) 2016, Queensland Institute Medical Research (QIMR)
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

    % init return data (in case user cancels)
    outdata = data;

    % remember the orginal shape of our data
    orgsize = size(data);
    
    % ensure incoming data is a column vector
    data = reshape(data,[],1);
    
    % length of vector
    n = numel(data);
    
    % construct dialog box
    fig = figure('Units','pixels', ...
        'Position',[randi(300,1,1) randi(300,1,1), 400, 300], ...
        'MenuBar','none', ...
        'Name',name, ...
        'NumberTitle','off', ...
        'ToolBar', 'none', ...
        'Resize','off');

    % tab group
    tabgroup = uitabgroup('Units','pixels', 'Parent',fig, 'Position',[140 130 260 170]);
    tab1 = uitab('Parent',tabgroup,'title','Bar Graph');
    tab2 = uitab('Parent',tabgroup,'title','Histogram');
    
    % axes
    ax1 = axes('parent',tab1);      % axes for bar graph
    ax2 = axes('parent',tab2);      % axes for histogram

    % bar graph
    barg = bar(data, 'parent',ax1);
    xlim(ax1,[0.5 n+0.5]);
    xlabel('parent',ax1,'index');
    ylabel('parent',ax1,columnName);
    
    % histogram
    hist = histogram(data,'parent',ax2, 'Normalization','probability');
    xlabel('parent',ax2,columnName);
    ylabel('parent',ax2,'probability');
    
    % data table
    tbl = uitable(fig,'Position',[10 10 125, 275], ...
        'Data',data, ...
        'ColumnName',{columnName}, ...
        'ColumnWidth',{75}, ...
        'ColumnEditable',true, ...
        'CellSelectionCallback', @(src,~) CellSelectionCallback(src,barg,hist));

    % Number Generator panel
    panel = uipanel('Parent',fig, ...
        'Units','Pixels', ...
        'Position',[150 50 240 70], ...
        'Title','Number Generator', ...
        'FontSize', 12);
    
    % Distribution pop-up menu
    popup = uicontrol('Style','popupmenu', ...
        'String',{'Beta','Binomial','Constant','Exponential','Gamma','Generalized Pareto', 'Geometric', 'HalfNormal', 'InverseGaussian', 'Logistic', 'LogLogistic', 'LogNormal', 'Normal', 'Poisson', 'Uniform'}, ...
        'Value', 13, ...
        'Callback', @PopupCallback, ...
        'HorizontalAlignment','center', ...
        'ToolTipString', 'Probability Distribution Function (see random)', ...
        'FontUnits','pixels', ...
        'FontSize',12, ...
        'Parent', panel, ...
        'Position',[5 30 158 20]);            

    % 'parameter A' edit box
    editA = uicontrol('Style','edit', ...
        'String','0', ...
        'Value',0, ...
        'HorizontalAlignment','center', ...
        'ToolTipString', 'mean', ...
        'Callback', @EditCallback, ...
        'FontUnits','pixels', ...
        'FontSize',12, ...
        'Parent', panel, ...
        'Position',[10 5 45 20]);

    % 'parameter B' edit box
    editB = uicontrol('Style','edit', ...
        'String','1', ...
        'Value',1, ...
        'HorizontalAlignment','center', ...
        'ToolTipString', 'standard deviation', ...
        'Callback', @EditCallback, ...
        'FontUnits','pixels', ...
        'FontSize',12, ...
        'Parent', panel, ...
        'Position',[60 5 45 20]);

    % 'parameter C' edit box
    editC = uicontrol('Style','edit', ...
        'String','1', ...
        'Value',1, ...
        'Enable', 'off', ...
        'HorizontalAlignment','center', ...
        'ToolTipString', 'unused', ...
        'Callback', @EditCallback, ...
        'FontUnits','pixels', ...
        'FontSize',12, ...
        'Parent', panel, ...
        'Position',[110 5 45 20]);

    % 'APPLY' button
    uicontrol('Style','pushbutton', ...
        'String','Apply', ...
        'Callback', @(~,~) ApplyCallback(), ...
        'HorizontalAlignment','center', ...
        'FontUnits','pixels', ...
        'FontSize',12, ...
        'Parent', panel, ...
        'Position',[170 5 60 20]);
    
    % 'Cancel' button
    uicontrol('Style','pushbutton', ...
        'String','Cancel', ...
        'HorizontalAlignment','center', ...
        'FontUnits','pixels', ...
        'FontSize',12, ...
        'Parent', fig, ...
        'Callback', @(~,~) delete(fig), ...
        'Position',[260 10 60 20]);
    
    % 'OK' button
    uicontrol('Style','pushbutton', ...
        'String','OK', ...
        'HorizontalAlignment','center', ...
        'FontUnits','pixels', ...
        'FontSize',12, ...
        'Parent', fig, ...
        'Callback', @(~,~) OKCallback(), ...
        'Position',[330 10 60 20]);
    
    % wait for close button to delete the figure
    uiwait(fig);
    
    function CellSelectionCallback(tbl,barg,hist)
        %disp('CellSelectionCallback');
        data = get(tbl,'data');
        % update bar graph
        barg.YData = data;
        % update histogram
        hist.Data = data;
        hist.BinLimitsMode='auto';
    end

    function PopupCallback(popup,~)
        %disp('PopupCallback');
        switch popup.String{popup.Value}
            case 'Beta'
                editA.Enable = 'on';
                editB.Enable = 'on';
                editC.Enable = 'off';
                editA.TooltipString = 'first shape parameter';
                editB.TooltipString = 'second shape parameter';
                editC.TooltipString = 'unused';
            case 'Binomial'
                editA.Enable = 'on';
                editB.Enable = 'on';
                editC.Enable = 'off';
                editA.TooltipString = 'number of trials';
                editB.TooltipString = 'probability of success';
                editC.TooltipString = 'unused';
            case 'Constant'
                editA.Enable = 'on';
                editB.Enable = 'off';
                editC.Enable = 'off';
                editA.TooltipString = 'constant value to apply';
                editB.TooltipString = 'unused';
                editC.TooltipString = 'unused';
            case 'Exponential'
                editA.Enable = 'on';
                editB.Enable = 'off';
                editC.Enable = 'off';
                editA.TooltipString = 'mean';
                editB.TooltipString = 'unused';
                editC.TooltipString = 'unused';
            case 'Gamma'
                editA.Enable = 'on';
                editB.Enable = 'on';
                editC.Enable = 'off';
                editA.TooltipString = 'shape parameter';
                editB.TooltipString = 'scale parameter';
                editC.TooltipString = 'unused';
            case 'Generalized Pareto'
                editA.Enable = 'on';
                editB.Enable = 'on';
                editC.Enable = 'on';
                editA.TooltipString = 'shape parameter';
                editB.TooltipString = 'scale parameter';
                editC.TooltipString = 'location parameter';
            case 'Geometric'
                editA.Enable = 'on';
                editB.Enable = 'off';
                editC.Enable = 'off';
                editA.TooltipString = 'probability parameter';
                editB.TooltipString = 'unused';
                editC.TooltipString = 'unused';
            case 'HalfNormal'
                editA.Enable = 'on';
                editB.Enable = 'on';
                editC.Enable = 'off';
                editA.TooltipString = 'location parameter';
                editB.TooltipString = 'scale parameter';
                editC.TooltipString = 'unused';
            case 'InverseGaussian'
                editA.Enable = 'on';
                editB.Enable = 'on';
                editC.Enable = 'off';
                editA.TooltipString = 'scale parameter';
                editB.TooltipString = 'shape parameter';
                editC.TooltipString = 'unused';
            case 'Logistic'
                editA.Enable = 'on';
                editB.Enable = 'on';
                editC.Enable = 'off';
                editA.TooltipString = 'mean';
                editB.TooltipString = 'scale parameter';
                editC.TooltipString = 'unused';
            case 'LogLogistic'
                editA.Enable = 'on';
                editB.Enable = 'on';
                editC.Enable = 'off';
                editA.TooltipString = 'log mean';
                editB.TooltipString = 'log scale parameter';
                editC.TooltipString = 'unused';
            case 'LogNormal'
                editA.Enable = 'on';
                editB.Enable = 'on';
                editC.Enable = 'off';
                editA.TooltipString = 'log mean';
                editB.TooltipString = 'log standard deviation';
                editC.TooltipString = 'unused';
            case 'Normal'
                editA.Enable = 'on';
                editB.Enable = 'on';
                editC.Enable = 'off';
                editA.TooltipString = 'mean';
                editB.TooltipString = 'standard deviation';
                editC.TooltipString = 'unused';
            case 'Poisson'
                editA.Enable = 'on';
                editB.Enable = 'off';
                editC.Enable = 'off';
                editA.TooltipString = 'mean';
                editB.TooltipString = 'unused';
                editC.TooltipString = 'unused';
            case 'Uniform'
                editA.Enable = 'on';
                editB.Enable = 'on';
                editC.Enable = 'off';
                editA.TooltipString = 'lower';
                editB.TooltipString = 'upper';
                editC.TooltipString = 'unused';
        end
    end

    function ApplyCallback()
        %disp('ApplyCallback');
        name = popup.String{popup.Value};
        A = editA.Value;
        B = editB.Value;
        C = editC.Value;
        switch name
            % special case
            case 'Constant'
                data = A*ones(n,1);
            % one-parameter distributions
            case {'Exponential','Geometric','Poisson'}
                data = random(name,A,[n 1]);
            % two-parameter distributions
            case {'Beta','Binomial','Gamma','HalfNormal','InverseGaussian','Logistic','LogLogistic','LogNormal','Normal','Uniform'}
                data = random(name,A,B,[n 1]);
            % three-parameter distributions
            case 'Generalized Pareto'
                data = random(name,A,B,C,[n 1]);
        end
        % update uitable
        tbl.Data = data;
        % update bar graph
        barg.YData = data;
        % update histogram
        hist.Data = data;
        hist.BinLimitsMode='auto';
        
    end

    % Callback for OK button
    function OKCallback()
        outdata = reshape(data,orgsize);    % return the new data in it original shape
        delete(fig);                        % close the dialog box
    end

    % Callback for edit box
    function EditCallback(hObj,~)
        % get the incoming value
        val = str2double(hObj.String);
        if isnan(val)
            dlg = errordlg(['''', hObj.String, ''' is not a valid number'],'Invalid Number','modal');
            val = hObj.Value;           % restore the previous value                
            uiwait(dlg);                % wait for dialog box to close
        else
            hObj.Value = val;           % remember the new value
        end            

        % update the edit box string
        hObj.String = num2str(val,'%g');
    end

end
        

