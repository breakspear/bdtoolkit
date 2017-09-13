classdef bdControlVector < handle
    %bdControlVector Implements the control-panel Vector-Edit dialog box
    %   This class performs a similar job to bdEditVector but is
    %   specialised to work in tandem with the control panel (bdControl).
    %   It should not be called directly by the user. 
    %
    %AUTHORS
    %  Stewart Heitmann (2017c)

    % Copyright (C) 2017 QIMR Berghofer Medical Research Institute
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
    
    properties
        control         % handle to control panel
        dialogfig       % handle to dialog box figure
        datatable       % handle to the table widget
        bargraph        % handle to bar graph widget
        histogrm        % handle to histogram widget
        haltbutton      % handle to halt button
        listener        % handle to listener(s)
    end
    
    methods
        % Constructs a bdControlVector dialog box where 
        % control = handel to the bdControl object
        % xxxdef = 'pardef' or 'vardef' or 'lagdef' (string).
        % xxxindx is an index of the sys.xxxdef array.
        function this = bdControlVector(control,xxxdef,xxxname,titlestr)
            % init the listener array
            this.listener = event.listener.empty(0);

            % remember the control panel handle
            this.control = control; 

            % get the vector data from control.sys.xxxdef
            [data,xxxindx] = bdGetValue(this.control.sys.(xxxdef),xxxname);
            n = numel(data);
            
            % construct dialog box (at the current mouse position)
            xypos = get(groot,'PointerLocation'); 
            this.dialogfig = figure('Units','pixels', ...
                'Position',[xypos(1) xypos(2), 400, 300], ...
                'MenuBar','none', ...
                'Name',titlestr, ...
                'NumberTitle','off', ...
                'ToolBar', 'none', ...
                'Resize','off', ...
                'DeleteFcn', @(~,~) this.deletefig );

            % axes
            ax1 = axes('parent',this.dialogfig, 'Units','pixels', 'Position',[185 205 200 70]);      % axes for bar graph
            ax2 = axes('parent',this.dialogfig, 'Units','pixels', 'Position',[185  80 200 70]);      % axes for histogram
            
            % bar graph
            this.bargraph = bar(data, 'parent',ax1);
            xlim(ax1,[0.5 n+0.5]);
            xlabel('parent',ax1,'index');
            ylabel('parent',ax1,'value');
            title(ax1,['Values of ', xxxname]);

            % histogram
            this.histogrm = histogram(data,'parent',ax2, 'Normalization','probability');
            xlabel('parent',ax2,'value');
            ylabel('parent',ax2,'proportion');
            title(ax2,['Histogram of ', xxxname]);

            % data table 
            this.datatable = uitable(this.dialogfig,'Position',[10 10 125, 280], ...
                'Data',reshape(data,[],1), ...       % ensure data is column vector
                'ColumnName',{xxxname}, ...
        ...        'ColumnWidth',{75}, ...
                'ColumnEditable',true, ...
                'CellEditCallback', @(src,~) this.CellEditCallback(xxxdef,xxxindx));

            % HALT button
            this.haltbutton = uicontrol('Style','radio', ...
                'String','HALT', ...
                'Value',this.control.halt, ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'FontWeight','bold', ...
                'ForegroundColor', 'r', ...
                'Parent', this.dialogfig, ...
                'ToolTipString', 'Halt the solver', ...
                'Callback', @(src,~) this.HaltCallback(src), ...
                'Position',[175 10 60 20]);

            % 'Close' button
            uicontrol('Style','pushbutton', ...
                'String','Close', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', this.dialogfig, ...
                'Callback', @(~,~) delete(this.dialogfig), ...
                'Position',[325 10 60 20]);
            
            % listen to the control panel for widget refresh events (incuding those generate by this dialog box)
            this.listener = addlistener(control,'refresh',@(~,~) this.refreshListener(xxxdef,xxxname));   
            
            % litsen to the control panel for any closefig events
            this.listener(end+1) = addlistener(control,'closefig',@(~,~) delete(this.dialogfig));   
        end
        
        % Destructor (called when this object is no longer referenced)
        function delete(this)
            %disp('bdControlVector.destructor');
            delete(this.dialogfig);
        end
        
        % Figure Destructor (called when the dialog box is destroyed)
        function deletefig(this)
            %disp('deletefig');
            delete(this.listener);
        end        
        
        % HALT button callback
        function HaltCallback(this,haltbutton)
            this.control.halt = haltbutton.Value;    % get the HALT button state
            notify(this.control,'refresh');          % notify all widgets to refresh themselves
            if ~this.control.halt
                notify(this.control,'recompute');    % tell the solver to recompute
            end
        end
        
        % TABLE cell edit callback
        function CellEditCallback(this,xxxdef,xxxindx)
            %disp('CellEditCallback'); 
            % get the data from the table
            data = get(this.datatable,'data');
            
            % reshape the data to match the sys.xxxdef.value.
            data = reshape(data,size(this.control.sys.(xxxdef)(xxxindx).value));
            
            % update the control panel.
            this.control.sys.(xxxdef)(xxxindx).value = data;
            
            % notify all widgets (which includes ourself) to refresh
            notify(this.control,'refresh');
            
            % tell the solver to recompute the solution
            if ~this.control.halt
                notify(this.control,'recompute');
            end
        end

        % Listener for widget refresh events from the control panel
        function refreshListener(this,xxxdef,xxxname)
            %disp('bdControlVector.refreshListener')         
            
            % read the data from control.sys.xxxdef
            data = bdGetValue(this.control.sys.(xxxdef),xxxname);
           
            % rehsape it to a column vector
            data = reshape(data,[],1);
            
            % update the data table
            this.datatable.Data = data;
            
            % update bar graph
            this.bargraph.YData = data;
            
            % update histogram
            this.histogrm.Data = data;
            this.histogrm.BinLimitsMode='auto';

            % update the HALT button
            this.haltbutton.Value = this.control.halt; 
        end
        
    end
    
end

