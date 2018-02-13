classdef bdControlVector < handle
   %bdControlVector  Control panel widget for vector values in bdGUI.
    %  This class is specialised for use with bdControlPanel.
    %  It is not intended to be called directly by users.
    % 
    %AUTHORS
    %  Stewart Heitmann (2017d,2018a)

    % Copyright (C) 2017-2018 QIMR Berghofer Medical Research Institute
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
        rowh = 24;
        roww = 220;
    end

    properties (Access=private)
        parent
        panel
        minbox
        maxbox
        perbbtn
        randbtn        
        baxes
        bgraph
        labelbtn
        listener1
        listener2
        dialog
    end
    
    methods
        function this = bdControlVector(control,xxxdef,xxxindx,parent,ypos,modecheckbox)
            %disp('bdControlVector()');

            % init empty handle to dialog box
            this.dialog = bdControlVectorDialog.empty(0);

            % extract the relevant fields from control.sys.xxxdef
            xxxname  = control.sys.(xxxdef)(xxxindx).name;
            xxxvalue = control.sys.(xxxdef)(xxxindx).value;
            xxxlim   = control.sys.(xxxdef)(xxxindx).lim;

            % remember our parent and the vertical offset
            this.parent = parent;
            
            % define widget geometry
            colw = 50;
            col1 = 2;
            col2 = col1 + colw + 5;
            col3 = col2 + colw + 5;
            col4 = col3 + colw + 5;
            labelw = 50;
            
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
                'Position',[col1 2 colw this.rowh-4], ...
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
                'Position',[col2 2 colw this.rowh-4], ...
                'String',num2str(xxxlim(2),'%0.4g'), ...
                'Value',xxxlim(2), ...
                'HorizontalAlignment','center', ...
                'Visible','off', ...
                'Callback', @(~,~) this.maxboxCallback(control,xxxdef,xxxindx), ...
                'ToolTipString',['upper limit for ''' xxxname '''']);
                        
            % Construct the PERB button
            this.perbbtn = uicontrol('Parent',this.panel, ...
                'Style','pushbutton', ...
                'Units','pixels', ...
                'Position',[col1 2 colw this.rowh-4], ...
                'String','PERB', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Callback', @(~,~) this.PerbCallback(control,xxxdef,xxxindx), ...
                'ToolTipString',['Perturb the values of ''' xxxname ''' by 5% of axis limits']);            

            % Construct the RAND button
            this.randbtn = uicontrol('Parent',this.panel, ...
                'Style','pushbutton', ...
                'Units','pixels', ...
                'Position',[col2 2 colw this.rowh-4], ...
                'String','RAND', ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Callback', @(~,~) this.RandCallback(control,xxxdef,xxxindx), ...
                'ToolTipString',['Apply Uniform Random values to ''' xxxname '''']);            

            % construct bar graph widget for the vector
            this.baxes = axes('Parent', this.panel, ...
                'Units','pixels', ...
                'Position',[col3+1 3 colw-2 this.rowh-6]);
            this.bgraph = bar(this.baxes,xxxvalue);
            xlim(this.baxes,[0.5 numel(xxxvalue)+0.5]);
            ylim(this.baxes,xxxlim);
            this.baxes.XTick=[];
            this.baxes.YTick=[];
            this.baxes.XColor =[0.7 0.7 0.7];
            this.baxes.YColor =[0.7 0.7 0.7];

            % Construct the label button
            this.labelbtn = uicontrol('Parent',this.panel, ...
                'Style', 'pushbutton', ...
                'Units','pixels',...
                'Position',[col4 2 labelw this.rowh-5], ...
                'String',xxxname, ...
            ...    'BackgroundColor','g', ...
                'FontWeight','bold', ...
                'Callback', @(~,~) this.labelbtnCallback(control,xxxdef,xxxindx,xxxname), ...
                'ToolTipString',['more options for ''',xxxname,'''']);

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
            disp('bdControlVector.mode()');
            if flag
                this.minbox.Visible = 'off';
                this.maxbox.Visible = 'off';
                this.perbbtn.Visible = 'on';
                this.randbtn.Visible = 'on';
            else
                this.minbox.Visible = 'on';
                this.maxbox.Visible = 'on';
                this.perbbtn.Visible = 'off';
                this.randbtn.Visible = 'off';
            end                        
        end

    end
   
    methods (Access=private)
        
        % min box callback function
        function minboxCallback(this,control,xxxdef,xxxindx)
            %disp('bdControlVector.minboxCallback()');
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
                %notify(control,'refresh');
                notify(control,xxxdef);

                % notify all display panels to redraw themselves
                notify(control,'redraw');
            end
        end        

        % max box callback function
        function maxboxCallback(this,control,xxxdef,xxxindx)
            %disp('bdControlVector.maxboxCallback()');
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
        
        % PERB button callback. Applies a random perturbation to
        % the current value. The perturbation is drawn from a uniform
        % distribution that spans 5% of the limits specified in xxxdef.
        function PerbCallback(this,control,xxxdef,xxxindx)
            % determine the limits of the random values
            xxxlim = control.sys.(xxxdef)(xxxindx).lim;
            lo = xxxlim(1);
            hi = xxxlim(2);
            
            % update the control panel with a perturned version of the data
            valsize = size(control.sys.(xxxdef)(xxxindx).value);
            control.sys.(xxxdef)(xxxindx).value =  ...
                control.sys.(xxxdef)(xxxindx).value + ...
                0.05*(hi-lo)*(rand(valsize)-0.5);
            
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

        
        % label button callback function
        function labelbtnCallback(this,control,xxxdef,xxxindx,xxxname)
            if isvalid(this.dialog)
                % a dialog box already exists, make it visible
                this.dialog.visible('on');
            else
                % contruct a new dialog box
                this.dialog = bdControlVectorDialog(control,xxxdef,xxxindx,['Edit Vector ',xxxname]);
            end      
        end

        % Update the widgets according to the values in control.sys.xxxdef
        function refresh(this,control,xxxdef,xxxindx,modecheckbox) 
            disp(['bdControlVector.refresh:' xxxdef]);
            
            % extract the relevant fields from control.sys.xxxdef
            xxxvalue = control.sys.(xxxdef)(xxxindx).value;
            xxxlim   = control.sys.(xxxdef)(xxxindx).lim;

            % update the min box widget
            this.minbox.Value = xxxlim(1);
            this.minbox.String = num2str(xxxlim(1),'%0.4g');
            
            % update the max box widget
            this.maxbox.Value = xxxlim(2);
            this.maxbox.String = num2str(xxxlim(2),'%0.4g');

            % update the bar graph
            this.bgraph.YData = xxxvalue;
            this.baxes.YLim = xxxlim + [-1e-6 1e-6];
            
            % show/hide the slider widget according to the state of the caller's modecheckbox
            this.mode(modecheckbox.Value)
        end
        
    end
    
end

