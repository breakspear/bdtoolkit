classdef bdControlScalarDialog < handle
    %bdControlScalarDialog  Dialog box for editing a scalar control widget
    %   This class is used by the bdGUI control panel.
    %   It should not be called directly by the user. 
    % 
    %AUTHORS
    %  Stewart Heitmann (2018a)

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
    
    properties (Access=private)
        control         % handle to control panel
        dialogfig       % handle to dialog box figure
        minbox          % handle to minbox
        maxbox          % handle to maxbox
        valbox          % handel to valbox
        listener1       % handle to listener1
        listener2       % handle to listener2
    end
    
    methods
        % Constructs a bdControlScalarDialog dialog box where 
        % control = handle to the bdControl object
        % xxxdef = 'pardef' or 'vardef' or 'lagdef' (string).
        % xxxindx is an index of the sys.xxxdef array.
        % titlestr is the title of the dialog box
        function this = bdControlScalarDialog(control,xxxdef,xxxindx,titlestr)
            % remember the control panel handle
            this.control = control; 

            % extract the relevant fields from control.sys.xxxdef
            xxxname  = control.sys.(xxxdef)(xxxindx).name;
            xxxvalue = control.sys.(xxxdef)(xxxindx).value;
            xxxlim   = control.sys.(xxxdef)(xxxindx).lim;

            % define widget geometry
            colw = 50;
            col1 = 5;
            col2 = col1 + colw + 5;
            col3 = col2 + colw + 5;
            rowh = 20;
            row1 = 5;
            row2 = row1 + rowh + 4;
            row3 = row2 + rowh + 4;
            row4 = row3 + rowh + 4;
            
            % construct dialog box (at the current mouse position)
            xypos = get(groot,'PointerLocation'); 
            this.dialogfig = figure('Units','pixels', ...
                'Position',[xypos(1), xypos(2), col3, row4], ...
                'MenuBar','none', ...
                'Name',titlestr, ...
                'NumberTitle','off', ...
                'ToolBar', 'none', ...
                'Resize','off', ...
                'DeleteFcn', @(~,~) delete(this) );

            % val box
            this.valbox = uicontrol('Parent',this.dialogfig, ...
                'Style', 'edit', ...
                'Units','pixels',...
                'Position',[col1 row3 colw rowh], ...
                'String',num2str(xxxvalue,'%0.4g'), ...
                'Value',xxxvalue, ...
                'HorizontalAlignment','center', ...
                'FontWeight','bold', ...
                'Visible','on', ...
                'Callback', @(~,~) this.valboxCallback(xxxdef,xxxindx), ...
                'ToolTipString',['current value of ''',xxxname,'''']);
            
            % label
            uicontrol('Parent',this.dialogfig, ...
                'Style', 'text', ...
                'Units','pixels',...
                'Position',[col2 row3+2 colw rowh], ...
                'FontSize',14, ...
                'String',xxxname, ...
                'HorizontalAlignment','center', ...
             ...'BackgroundColor','g', ...
                'FontWeight', 'bold');

            % min box
            this.minbox = uicontrol('Parent',this.dialogfig, ...
                'Style', 'edit', ...
                'Units','pixels',...
                'Position',[col1 row2 colw rowh], ...
                'String',num2str(xxxlim(1),'%0.4g'), ...
                'Value',xxxlim(1), ...
                'HorizontalAlignment','center', ...
                'ForegroundColor','b', ...
                'Visible','on', ...
                'Callback', @(~,~) this.minboxCallback(xxxdef,xxxindx), ...
                'ToolTipString',['lower limit for ''',xxxname,'''']);

            % max box
            this.maxbox = uicontrol('Parent',this.dialogfig, ...
                'Style', 'edit', ...
                'Units','pixels',...
                'Position',[col2 row2 colw rowh], ...
                'String',num2str(xxxlim(2),'%0.4g'), ...
                'Value',xxxlim(2), ...
                'HorizontalAlignment','center', ...
                'ForegroundColor','b', ...
                'Visible','on', ...
                'Callback', @(~,~) this.maxboxCallback(xxxdef,xxxindx), ...
                'ToolTipString',['upper limit for ''',xxxname,'''']);

            % 'PERB' button
            uicontrol('Style','pushbutton', ...
                'String','PERB', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', this.dialogfig, ...
                'Callback', @(~,~) this.PerbCallback(xxxdef,xxxindx), ...
                'Position',[col1 row1 colw rowh], ...
                'ToolTipString','Perturb');            
            
            % 'RAND' button
            uicontrol('Style','pushbutton', ...
                'String','RAND', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', this.dialogfig, ...
                'Callback', @(~,~) this.RandCallback(xxxdef,xxxindx), ...
                'Position',[col2 row1 colw rowh], ...
                'ToolTipString','Uniform random');            

            % listen to the control panel for widget refresh events (incuding those generate by this dialog box)
            this.listener1 = addlistener(control,'refresh',@(~,~) this.refresh(xxxdef,xxxindx));
            this.listener2 = addlistener(control,xxxdef,@(~,~) this.refresh(xxxdef,xxxindx));
        end
        
        % Destructor (called when the object is no longer referenced)
        function delete(this)
            delete(this.listener2);
            delete(this.listener1);
            delete(this.dialogfig);
        end
        
        % Make the dialog box visible/invisible
        function visible(this,flag)
            figure(this.dialogfig);
            this.dialogfig.Visible = flag;
        end
        
        % Refresh the widgets from the control panel
        function refresh(this,xxxdef,xxxindx)
            %disp(['bdControlScalarDialog.refresh:' xxxdef])         

            % extract the data from control.sys.xxxdef
            xxxvalue = this.control.sys.(xxxdef)(xxxindx).value;
            xxxlim = this.control.sys.(xxxdef)(xxxindx).lim;

            % update the val box
            this.valbox.Value = xxxvalue;
            this.valbox.String = num2str(xxxvalue,'%0.4g');

            % update the min box
            this.minbox.Value = xxxlim(1);
            this.minbox.String = num2str(xxxlim(1),'%0.4g');
           
            % update the max box
            this.maxbox.Value = xxxlim(2);
            this.maxbox.String = num2str(xxxlim(2),'%0.4g');
        end

    end

    methods (Access=private)

        % RAND button callback. Replaces the current value with a uniform
        % random number drawn from the limits specified in xxxdef.
        function RandCallback(this,xxxdef,xxxindx)
            % determine the limits of the random values
            xxxlim = this.control.sys.(xxxdef)(xxxindx).lim;
            lo = xxxlim(1);
            hi = xxxlim(2);
            
            % update the control panel.
            valsize = size(this.control.sys.(xxxdef)(xxxindx).value);
            this.control.sys.(xxxdef)(xxxindx).value = (hi-lo)*rand(valsize) + lo;
            
            % notify all widgets (which includes ourself) that sys.xxxdef has changed
            notify(this.control,xxxdef);

            % tell the solver to recompute the solution
            if ~this.control.halt
                notify(this.control,'recompute');
            end
        end

        % PERB button callback. Applies a random perturbation to
        % the current value. The perturbation is drawn from a uniform
        % distribution that spans 5% of the limits specified in xxxdef.
        function PerbCallback(this,xxxdef,xxxindx)
            % determine the limits of the random values
            xxxlim = this.control.sys.(xxxdef)(xxxindx).lim;
            lo = xxxlim(1);
            hi = xxxlim(2);
            
            % update the control panel with a perturned version of the data
            valsize = size(this.control.sys.(xxxdef)(xxxindx).value);
            this.control.sys.(xxxdef)(xxxindx).value =  ...
                this.control.sys.(xxxdef)(xxxindx).value + ...
                0.05*(hi-lo)*(rand(valsize)-0.5);
            
            % notify all widgets (which includes ourself) that sys.xxxdef has changed
            notify(this.control,xxxdef);
            
            % tell the solver to recompute the solution
            if ~this.control.halt
                notify(this.control,'recompute');
            end
        end

        % val box callback function
        function valboxCallback(this,xxxdef,xxxindx)
            % read the valbox string and convert to a number
            str = this.valbox.String;
            val = str2double(str);
            if isnan(val)
                hndl = errordlg(['Invalid number: ',str], 'Invalid Number', 'modal');
                uiwait(hndl);
                % restore the valbox string to its previous value
                this.valbox.String = num2str(this.valbox.Value,'%0.4g');                 
            else           
                % update control.sys
                this.control.sys.(xxxdef)(xxxindx).value = val;
                
                % notify all widgets (which includes ourself) that sys.xxxdef has changed
                %notify(this.control,'refresh');
                notify(this.control,xxxdef);

                % tell the control panel to recompute the solution
                notify(this.control,'recompute');
            end
        end        
        
        % min box callback function
        function minboxCallback(this,xxxdef,xxxindx)
            % read the minbox string and convert to a number
            str = this.minbox.String;
            minval = str2double(str);
            if isnan(minval)
                hndl = errordlg(['Invalid number: ',str], 'Invalid Number', 'modal');
                uiwait(hndl);
                % restore the minbox string to its previous value
                this.minbox.String = num2str(this.minbox.Value,'%0.4g');                 
            else           
                % adjust the max box if necessary
                maxval = max(this.maxbox.Value, minval);
                
                % update control.sys
                this.control.sys.(xxxdef)(xxxindx).lim = [minval maxval];
                
                % notify all widgets (which includes ourself) that sys.xxxdef has changed
                %notify(this.control,'refresh');
                notify(this.control,xxxdef);

                % notify all display panels to redraw themselves
                notify(this.control,'redraw');
            end
        end        
        
        % max box callback function
        function maxboxCallback(this,xxxdef,xxxindx)
            % read the maxbox string and convert to a number
            str = this.maxbox.String;
            maxval = str2double(str);
            if isnan(maxval)
                hndl = errordlg(['Invalid number: ',str], 'Invalid Number', 'modal');
                uiwait(hndl);
                % restore the minbox string to its previous value
                this.maxbox.String = num2str(this.maxbox.Value,'%0.4g');                 
            else           
                % adjust the min box if necessary
                minval = min(this.minbox.Value, maxval);
                
                % update control.sys
                this.control.sys.(xxxdef)(xxxindx).lim = [minval maxval];
                
                % notify all widgets (which includes ourself) that sys.xxxdef has changed
                %notify(this.control,'refresh');
                notify(this.control,xxxdef);

                % notify all display panels to redraw themselves
                notify(this.control,'redraw');
            end
        end
        
    end
    
end

