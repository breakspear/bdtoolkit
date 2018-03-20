function outdata = bdLoadMatrix(name,info)
    %bdLoadMatrix Dialog box for loading matrix data from file.
    %Usage:
    %   outdata = bdLoadMatrix(name,msg)
    %where
    %   name is the title of the dialog box
    %   info is a multi-line string displayed to the user
    %
    %RETURNS 
    %   outdata the user-selected matrix or [] if the user cancels. 
    %
    %EXAMPLE
    %   name = 'mymodel';
    %   info = {'My Model','','Load the connectivity matrix, Kij'};
    %   Kij = bdLoadMatrix(name,info);
    %   if isempty(Kij)
    %      disp('User cancelled the operation');
    %   end
    %
    %AUTHORS
    %  Stewart Heitmann (2016a)

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

    % data storage
    datastruct = [];    % the data imported/loaded from file
    datafields = [];    % names of the fields in datastruct
    outdata = [];       % init output
    
    % construct dialog box
    fig = dialog('Units','pixels', ...
        'Position',[randi(300,1,1) randi(300,1,1), 600, 250], ...
        'MenuBar','none', ...
        'Name',name, ...
        'NumberTitle','off', ...
        'ToolBar', 'none', ...
        'Resize','off');
       
    % 'Load' button
    uicontrol('Style','pushbutton', ...
        'String','Load', ...
        'HorizontalAlignment','center', ...
        'FontUnits','pixels', ...
        'FontSize',12, ...
        'Parent', fig, ...
        'Callback', @(~,~) LoadCallback(), ...
        'TooltipString', 'load data from a mat file', ...
        'Position',[20 220 60 20]);

    % 'Import' button
    uicontrol('Style','pushbutton', ...
        'String','Import', ...
        'HorizontalAlignment','center', ...
        'FontUnits','pixels', ...
        'FontSize',12, ...
        'Parent', fig, ...
        'Callback', @(~,~) ImportCallback(), ...
        'TooltipString', 'import data from other file formats', ...
        'Position',[90 220 60 20]);
    
    % Data field panel
    FieldPanel = uipanel('Parent',fig, ...
        'Units','Pixels', ...
        'Position',[20 40 130 160], ...
        'Title','Data field', ...
        'FontSize', 12);
    
    % fieldnames popup menu
    FieldPopup = uicontrol('Parent',FieldPanel, ...
        'Style','popupmenu', ...
        'Units','pixels', ...
        'Position',[0 115 130 25], ...
        'String', 'select field', ...
        'HorizontalAlignment','left', ...
        'FontSize',12, ...
        'Enable','off', ...
        'TooltipString', 'select a field in your data', ...
        'Callback', @(~,~) RefreshDialog() );
    
    % data field text
    FieldText = uicontrol('Style','text', ...
        'String','No data loaded', ...
        'HorizontalAlignment','left', ...
        'FontUnits','pixels', ...
        'FontSize',12, ...
        'Enable','off', ...
        'Parent', FieldPanel, ...
        'Position',[10 10 130 100]);
        
    % data table
    DataTable = uitable(fig,'Position',[170 40 420 200], ...
        'Data', [], ...
        'ColumnWidth',{50}, ...
        'ColumnEditable',false );
    
    % custom text superiposed on the data table
    TableText = uicontrol('Style','text', ...
        'String',info, ...
        'HorizontalAlignment','center', ...
        'FontUnits','pixels', ...
        'FontSize',18, ...
        'BackgroundColor','w', ...
        'Parent', fig, ...
        'Position',[171 50 418 180]);
    
    % adjust the vertical position of TableText so that its extent is
    % vertically centered on the DataTable
    TableText.Position(4) = TableText.Extent(4);          % height
    TableText.Position(2) = 140 - TableText.Extent(4)/2;  % vertical pos
    
    % Hint text
    uicontrol('Style','text', ...
        'String','LOAD or IMPORT a data file then select a field within that data.', ...
        'HorizontalAlignment','left', ...
        'FontUnits','pixels', ...
        'FontSize',12, ...
        'ForegroundColor', [0.5 0.5 0.5], ...
        'Enable','on', ...
        'Parent', fig, ...
        'Position',[20 10 440 20]);

    % 'Cancel' button
    uicontrol('Style','pushbutton', ...
        'String','Cancel', ...
        'HorizontalAlignment','center', ...
        'FontUnits','pixels', ...
        'FontSize',12, ...
        'Parent', fig, ...
        'Callback', @(~,~) delete(fig), ...
        'Position',[460 10 60 20]);

    % 'OK' button
    OKbutton = uicontrol('Style','pushbutton', ...
        'String','OK', ...
        'HorizontalAlignment','center', ...
        'FontUnits','pixels', ...
        'FontSize',12, ...
        'Parent', fig, ...
        'Callback', @(~,~) OKCallback, ...
        'Enable','off', ...
        'Position',[530 10 60 20]);
       
    % wait for dialog box to be deleted
    uiwait(fig);
   
    % Callback for LOAD button
    function LoadCallback()
        % dialog box for user to select a file
        [filename,pathname] = uigetfile('*.mat');
        
        % if user did not cancel then...
        if filename~=0
            % load the data
            datastruct = load(fullfile(pathname,filename));
            
            % extract the field names 
            datafields = fieldnames(datastruct);
            
            % update the popup menu with the new field names
            set(FieldPopup, 'String',datafields, 'Enable','on');
            
            % refresh the dialog box widgets
            RefreshDialog();
        end
    end

    % Callback for IMPORT button
    function ImportCallback()
        % dialog box for user to import data
        impdata = uiimport('-file');
        if ~isempty(impdata)
            datastruct = impdata;
            datafields = fieldnames(impdata);
            set(FieldPopup, 'String',datafields, 'Enable','on');
            RefreshDialog();
        end
    end

    function RefreshDialog()
        %disp('RefreshDialog');
        switch FieldPopup.Enable
            case 'on'
                % read the field name from the popup menu
                fieldname = FieldPopup.String{FieldPopup.Value};
                
                % extract the field data from datastruct
                outdata = datastruct.(fieldname);

                % classify size of data
                datasize = size(outdata);
                if size(outdata,3)>1
                    datafmt = num2str([size(outdata,1),size(outdata,2),size(outdata,3)],'%d x %d x %d');
                else
                    datafmt = num2str([size(outdata,1),size(outdata,2)],'%d x %d');
                end
                
                % classify the data type and also update the DataTable
                if isnumeric(outdata)
                    datatype = 'numeric data';
                    TableText.Visible='off';
                    DataTable.Data = outdata(:,:,1);
                    FieldText.Enable='on';
                    OKbutton.Enable='on';
                elseif islogical(outdata)
                    datatype = 'logical data';
                    TableText.Visible='off';
                    DataTable.Data = outdata(:,:,1);
                    FieldText.Enable='on';
                    OKbutton.Enable='on';
                else
                    datatype = 'non-numeric data';
                    DataTable.Data = [];
                    TableText.Visible='on';
                    FieldText.Enable='on';
                    OKbutton.Enable='off';
                    outdata = [];
                end
               
                % update the info text
                FieldText.String = {datafmt, datatype};

            case 'off'
                DataTable.Data = [];
                TableText.Visible='on';
                OKbutton.Enable='off';    
                FieldText.Enable='off';
                FieldText.String = 'No data loaded';
        end
    end

    % Callback for OK button
    function OKCallback()
        delete(fig);                % close the dialog box
    end

    % Callback for CANCEL button
    function CancelCallback()
        outdata = [];               % return empty
        delete(fig);                % close the dialog box
    end

end
    


