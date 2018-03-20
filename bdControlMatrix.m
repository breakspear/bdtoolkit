classdef bdControlMatrix < handle
    %bdControlMatrix  Control panel widget for matrix values in bdGUI.
    %  This class is specialised for use with bdControlPanel.
    %  It is not intended to be called directly by users.
    % 
    %AUTHORS
    %  Stewart Heitmann (2017d,2018a)

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

    properties (Constant)
        rowh = 54;
        roww = 220;
    end

    properties (Access=private)
        parent
        panel
        minbox
        maxbox
        plusbtn
        minusbtn
        randbtn
        peyebtn
        meyebtn
        imgaxes
        imgplot
        labelbtn
        listener1
        listener2
        dialog
    end
    
    methods
        function this = bdControlMatrix(control,xxxdef,xxxindx,parent,ypos,modecheckbox)
            %disp('bdControlMatrix()');
            
            % init empty handle to dialog box
            this.dialog = bdControlMatrixDialog.empty(0);

            % extract the relevant fields from control.sys.xxxdef
            xxxname  = control.sys.(xxxdef)(xxxindx).name;
            xxxvalue = control.sys.(xxxdef)(xxxindx).value;
            xxxlim   = control.sys.(xxxdef)(xxxindx).lim;

            % remember our parent and the vertical offset
            this.parent = parent;
            
            % define widget geometry
            colw = 22.5;                  % column width
            gap = 5;                    % column gap
            boxh = 20;                  % box height
            col1 = 2;
            col2 = ceil(col1 + colw + gap);
            col3 = floor(col2 + colw + gap);
            col4 = ceil(col3 + colw + gap);
            col5 = floor(col4 + colw + gap);
            col6 = ceil(col5 + colw + gap);
            col7 = floor(col6 + colw + gap);
            col8 = ceil(col7 + colw + gap);
            col9 = floor(col8 + colw + gap);
            row1 = 4;
            row1b = 17;
            row2 = row1 + boxh + 4;
            row3 = row2 + boxh + 4;
            
            % Construct the panel container
            this.panel = uipanel('Parent',parent, ...
                'Units','pixels', ...
                'Position',[2 ypos this.roww this.rowh], ...
                'BorderType','none', ...
                'DeleteFcn', @(~,~) delete(this.dialog) );
                
            % Construct the min box
            this.minbox = uicontrol('Parent',this.panel, ...
                'Style', 'edit', ...
                'Units','pixels',...
                'Position',[col1 row1b col3-col1-gap boxh], ...
                'String',num2str(xxxlim(1),'%0.4g'), ...
                'Value',xxxlim(1), ...
                'HorizontalAlignment','center', ...
                'Visible','off', ...
                'Callback', @(~,~) this.minboxCallback(control,xxxdef,xxxindx), ...
                'ToolTipString',['lower limit for ''' xxxname '''']);

            % Construct the max box
            this.maxbox = uicontrol('Parent',this.panel, ...
                'Style', 'edit', ...
                'Units','pixels',...
                'Position',[col3 row1b col5-col3-gap boxh], ...
                'String',num2str(xxxlim(2),'%0.4g'), ...
                'Value',xxxlim(2), ...
                'HorizontalAlignment','center', ...
                'Visible','off', ...
                'Callback', @(~,~) this.maxboxCallback(control,xxxdef,xxxindx), ...
                'ToolTipString',['upper limit for ''' xxxname '''']);
            
            % Construct the PLUS button
            this.plusbtn = uicontrol('Parent',this.panel, ...
                'Style','pushbutton', ...
                'Units','pixels', ...
                'Position',[col1 row2 col2-col1-gap boxh], ...
                'String','+', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Callback', @(~,~) this.PlusCallback(control,xxxdef,xxxindx), ...
                'ToolTipString',['Increment the values of ''' xxxname '''']);            

            % Construct the MINUS button
            this.minusbtn = uicontrol('Parent',this.panel, ...
                'Style','pushbutton', ...
                'Units','pixels', ...
                'Position',[col2 row2 col3-col2-gap boxh], ...
                'String','-', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Callback', @(~,~) this.MinusCallback(control,xxxdef,xxxindx), ...
                'ToolTipString',['Decrement the values of ''' xxxname '''']);            
            
            % Construct the RAND button
            this.randbtn = uicontrol('Parent',this.panel, ...
                'Style','pushbutton', ...
                'Units','pixels', ...
                'Position',[col3 row2 col5-col3-gap boxh], ...
                'String','RAND', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Callback', @(~,~) this.RandCallback(control,xxxdef,xxxindx), ...
                'ToolTipString',['Assign Uniform Random values to ''' xxxname '''']);            

            % Construct the +EYE button
            this.peyebtn = uicontrol('Parent',this.panel, ...
                'Style','pushbutton', ...
                'Units','pixels', ...
                'Position',[col1 row1 col3-col1-gap boxh], ...
                'String','+EYE', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Callback', @(~,~) this.PeyeCallback(control,xxxdef,xxxindx), ...
                'ToolTipString',['Increment the diagonal entries of ''' xxxname '''']);            

            % Construct the -EYE button
            this.meyebtn = uicontrol('Parent',this.panel, ...
                'Style','pushbutton', ...
                'Units','pixels', ...
                'Position',[col3 row1 col5-col3-gap boxh], ...
                'String','-EYE', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Callback', @(~,~) this.MeyeCallback(control,xxxdef,xxxindx), ...
                'ToolTipString',['Decrement the diagonal entries of ''' xxxname '''']);            

            % construct image widget for the matrix
            this.imgaxes = axes('Parent', this.panel, ...
                'Units','pixels', ...
                'Position',[col5+1 row1 col7-col5-gap-2 row3-row1-4]);
            this.imgplot = imagesc(xxxvalue(:,:,1), ...
                'Parent',this.imgaxes, ...
                xxxlim);
            axis off;

            % Construct the label button
            this.labelbtn = uicontrol('Parent',this.panel, ...
                'Style', 'pushbutton', ...
                'Units','pixels',...
                'Position',[col7 row1b col9-col7-gap boxh], ...
                'String',xxxname, ...
            ...    'BackgroundColor','g', ...
                'FontWeight','bold', ...
                'Callback', @(~,~) this.labelbtnCallback(control,xxxdef,xxxindx,xxxname), ...
                'ToolTipString',['More options for ''',xxxname,'''']);
            
            % listen for widget refresh events from the control panel 
            this.listener1 = addlistener(control,'refresh', @(~,~) this.refresh(control,xxxdef,xxxindx,modecheckbox));
            this.listener2 = addlistener(control,xxxdef, @(~,~) this.refresh(control,xxxdef,xxxindx,modecheckbox));
        end
        
        % Destructor
        function delete(this)
            delete(this.listener2);
            delete(this.listener1);
        end

        function mode(this,flag)            
            %disp('bdControlMatrix.mode()');
            if flag
                this.minbox.Visible = 'off';
                this.maxbox.Visible = 'off';
                this.plusbtn.Visible = 'on';
                this.minusbtn.Visible = 'on';
                this.randbtn.Visible = 'on';
                this.peyebtn.Visible = 'on';
                this.meyebtn.Visible = 'on';
            else
                this.minbox.Visible = 'on';
                this.maxbox.Visible = 'on';
                this.plusbtn.Visible = 'off';
                this.minusbtn.Visible = 'off';
                this.randbtn.Visible = 'off';
                this.peyebtn.Visible = 'off';
                this.meyebtn.Visible = 'off';
            end                        
        end

    end
   
    methods (Access=private)
        
        % min box callback function
        function minboxCallback(this,control,xxxdef,xxxindx)
            %disp('bdControlMatrix.minboxCallback()');
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
                control.sys.(xxxdef)(xxxindx).lim = [minval maxval];
                
                % notify all widgets (which includes ourself) that sys.xxxdef has changed
                %notify(this.control,'refresh');
                notify(this.control,xxxdef);

                % notify all display panels to redraw themselves
                notify(control,'redraw');
            end
        end        

        % max box callback function
        function maxboxCallback(this,control,xxxdef,xxxindx)
            %disp('bdControlMatrix.maxboxCallback()');
            % read the maxbox string and convert to a number
            str = this.maxbox.String; 
            maxval = str2double(str);
            if isnan(maxval)
                hndl = errordlg(['Invalid number: ',str], 'Invalid Number', 'modal');
                uiwait(hndl);
                % restore the maxbox string to its previous value
                this.maxbox.String = num2str(this.maxbox.Value,'%0.4g');                 
            else           
                % adjust the min box if necessary
                minval = min(this.minbox.Value, maxval);
                
                % update control.sys
                control.sys.(xxxdef)(xxxindx).lim = [minval maxval];
                
                % notify all widgets (which includes ourself) that sys.xxxdef has changed
                %notify(control,'refresh');
                notify(control,xxxdef);

                % notify all display panels to redraw themselves
                notify(control,'redraw');
            end
        end        
        
        % label button callback function
        function labelbtnCallback(this,control,xxxdef,xxxindx,xxxname)
            if isvalid(this.dialog)
                % a dialog box already exists, make it visible
                this.dialog.visible('on');
            else
                % contruct a new dialog box
                this.dialog = bdControlMatrixDialog(control,xxxdef,xxxindx,['Edit Matrix ',xxxname]);
            end      
        end
       
        % PLUS button callback. Increments the current values by 5 percent
        % of the limit specified in xxxdef.
        function PlusCallback(this,control,xxxdef,xxxindx)
            % determine the limits of the values
            xxxlim = control.sys.(xxxdef)(xxxindx).lim;
            lo = xxxlim(1);
            hi = xxxlim(2);
            
            % update the control panel with an incremented version of the data
            valsize = size(control.sys.(xxxdef)(xxxindx).value);
            control.sys.(xxxdef)(xxxindx).value =  ...
                control.sys.(xxxdef)(xxxindx).value + 0.05*(hi-lo);
            
            % notify all widgets (which includes ourself) that sys.xxxdef has changed
            notify(control,xxxdef);
            
            % tell the solver to recompute the solution
            notify(control,'recompute');
        end

        % MINUS button callback. Decrements the current values by 5 percent
        % of the limit specified in xxxdef.
        function MinusCallback(this,control,xxxdef,xxxindx)
            % determine the limits of the values
            xxxlim = control.sys.(xxxdef)(xxxindx).lim;
            lo = xxxlim(1);
            hi = xxxlim(2);
            
            % update the control panel with a decremented version of the data
            valsize = size(control.sys.(xxxdef)(xxxindx).value);
            control.sys.(xxxdef)(xxxindx).value =  ...
                control.sys.(xxxdef)(xxxindx).value - 0.05*(hi-lo);
            
            % notify all widgets (which includes ourself) that sys.xxxdef has changed
            notify(control,xxxdef);
            
            % tell the solver to recompute the solution
            notify(control,'recompute');
        end
        
        % RAND button callback. Replaces the current value with a uniform
        % random number drawn from the limits specified in xxxdef.
        function RandCallback(this,control,xxxdef,xxxindx)
            % determine the limits of the random values
            xxxlim = control.sys.(xxxdef)(xxxindx).lim;
            lo = xxxlim(1);
            hi = xxxlim(2);
            
            % update the control panel.
            valsize = size(control.sys.(xxxdef)(xxxindx).value);
            control.sys.(xxxdef)(xxxindx).value = (hi-lo)*rand(valsize) + lo;
            
            % notify all widgets (which includes ourself) that sys.xxxdef has changed
            notify(control,xxxdef);

            % tell the solver to recompute the solution
            notify(control,'recompute');
        end

        % +EYE button callback. Increments the diagonal values by 5 percent
        % of the limit specified in xxxdef.
        function PeyeCallback(this,control,xxxdef,xxxindx)
            % determine the limits of the values
            xxxlim = control.sys.(xxxdef)(xxxindx).lim;
            lo = xxxlim(1);
            hi = xxxlim(2);

            % determine the size of the matrix
            valsize = size(control.sys.(xxxdef)(xxxindx).value);

            % increment the diagonal
            control.sys.(xxxdef)(xxxindx).value =  ...
                control.sys.(xxxdef)(xxxindx).value + 0.05*(hi-lo)*eye(valsize);
            
            % notify all widgets (which includes ourself) that sys.xxxdef has changed
            notify(control,xxxdef);
            
            % tell the solver to recompute the solution
            notify(control,'recompute');
        end
        
        % -EYE button callback. Decrements the diagonal values by 5 percent
        % of the limit specified in xxxdef.
        function MeyeCallback(this,control,xxxdef,xxxindx)
            % determine the limits of the values
            xxxlim = control.sys.(xxxdef)(xxxindx).lim;
            lo = xxxlim(1);
            hi = xxxlim(2);

            % determine the size of the matrix
            valsize = size(control.sys.(xxxdef)(xxxindx).value);

            % increment the diagonal
            control.sys.(xxxdef)(xxxindx).value =  ...
                control.sys.(xxxdef)(xxxindx).value - 0.05*(hi-lo)*eye(valsize);
            
            % notify all widgets (which includes ourself) that sys.xxxdef has changed
            notify(control,xxxdef);
            
            % tell the solver to recompute the solution
            notify(control,'recompute');
        end
                
        % Update the widgets according to the values in control.sys.xxxdef
        function refresh(this,control,xxxdef,xxxindx,modecheckbox) 
            %disp(['bdControlMatrix.refresh:' xxxdef]);
            
            % extract the relevant fields from control.sys.xxxdef
            xxxvalue = control.sys.(xxxdef)(xxxindx).value;
            xxxlim   = control.sys.(xxxdef)(xxxindx).lim;

            % update the min box widget
            this.minbox.Value = xxxlim(1);
            this.minbox.String = num2str(xxxlim(1),'%0.4g');
            
            % update the max box widget
            this.maxbox.Value = xxxlim(2);
            this.maxbox.String = num2str(xxxlim(2),'%0.4g');

            % update the contents of the image widget
            this.imgplot.CData = xxxvalue(:,:,1);
            
            % update the colour scale limits of the image
            this.imgaxes.CLim = [this.minbox.Value, this.maxbox.Value] + [-1e-6, 1e-6];
            
            % show/hide the slider widget according to the state of the caller's modecheckbox
            this.mode(modecheckbox.Value);
        end
        
    end
    
end

