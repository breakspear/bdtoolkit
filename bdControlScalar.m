classdef bdControlScalar < handle
   %bdControlScalar  Control panel widget for scalar values.
    %  This class implements the control panel widgets for scalar values.
    %  It is not intended to be called directly by users.
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
    
    properties (Constant)
        rowh = 24;
        roww = 220;
    end
    
    properties (Access=private)
        parent
        panel
        minbox
        maxbox
        jslider
        valbox
        labelbtn
        listener1
        listener2
        dialog
    end
    
    methods
        % Constructor
        function this = bdControlScalar(control,xxxdef,xxxindx,parent,ypos,modecheckbox)
            %disp('bdControlScalar()');
            
            % init empty handle to dialog box
            this.dialog = bdControlScalarDialog.empty(0);
            
            % extract the relevant fields from control.sys.xxxdef
            xxxname  = control.sys.(xxxdef)(xxxindx).name;
            xxxvalue = control.sys.(xxxdef)(xxxindx).value;
            xxxlim   = control.sys.(xxxdef)(xxxindx).lim;

            % remember our parent
            this.parent = parent;
            
            % define widget geometry
            colw = 50;
            gap = 5;
            col1 = 2;
            col2 = col1 + colw + gap;
            col3 = col2 + colw + gap;
            col4 = col3 + colw + gap;
            col5 = col4 + colw + gap;
            
            % Construct the panel container
            this.panel = uipanel('Parent',parent, ...
                'Units','pixels', ...
                'Position',[2 ypos this.roww this.rowh], ...
                'BorderType','none', ...
                'DeleteFcn', @(~,~) delete(this.dialog) );
                
            % Get the backgorund colour of our panel
            bgcolor = this.panel.BackgroundColor;
            
            % Construct the slider. I use a java slider because on OS/X the
            % matlab uicontrol slider ignoes its specified height/width.
            % See Yair Altman's Undocumented Matlab for the use of java
            % swing components in matlab.
            jsliderobj = javax.swing.JSlider;
            jsliderobj.setBackground(java.awt.Color(bgcolor(1),bgcolor(2),bgcolor(3)));
            javacomponent(jsliderobj,[col1 2 col3-col1 this.rowh-4],this.panel);
            this.jslider = handle(jsliderobj,'CallbackProperties');
            this.jslider.StateChangedCallback = @(~,~) this.sliderCallback(control,xxxdef,xxxindx);
            this.jslider.ToolTipText = ['slider for ''',xxxname,''''];

            % update the value in the slider widget
            this.sliderUpdate(xxxlim(1), xxxlim(2), xxxvalue);

            % Construct the min box
            this.minbox = uicontrol('Parent',this.panel, ...
                'Style', 'edit', ...
                'Units','pixels',...
                'Position',[col1 2 colw this.rowh-4], ...
                'String',num2str(xxxlim(1),'%0.3g'), ...
                'Value',xxxlim(1), ...
                'HorizontalAlignment','center', ...
                'ForegroundColor', 'b', ...
                'Visible','off', ...
                'Callback', @(~,~) this.minboxCallback(control,xxxdef,xxxindx), ...
                'ToolTipString',['lower limit for ''' xxxname '''']);

            % Construct the max box
            this.maxbox = uicontrol('Parent',this.panel, ...
                'Style', 'edit', ...
                'Units','pixels',...
                'Position',[col2 2 colw this.rowh-4], ...
                'String',num2str(xxxlim(2),'%0.3g'), ...
                'Value',xxxlim(2), ...
                'HorizontalAlignment','center', ...
                'ForegroundColor', 'b', ...
                'Visible','off', ...
                'Callback', @(~,~) this.maxboxCallback(control,xxxdef,xxxindx), ...
                'ToolTipString',['upper limit for ''' xxxname '''']);
                  
            % Construct the val box
            this.valbox = uicontrol('Parent',this.panel, ...
                'Style', 'edit', ...
                'Units','pixels',...
                'Position',[col3 2 colw this.rowh-4], ...
                'String',num2str(xxxvalue,'%0.3g'), ...
                'Value',xxxvalue, ...
                'HorizontalAlignment','center', ...
                'FontWeight','bold', ...
                'Visible','on', ...
                'Callback', @(~,~) this.valboxCallback(control,xxxdef,xxxindx), ...
                'ToolTipString',['current value of ''' xxxname '''']);
            
            % Construct the label button
            this.labelbtn = uicontrol('Parent',this.panel, ...
                'Style', 'pushbutton', ...
                'Units','pixels',...
                'Position',[col4 2 colw this.rowh-4], ...
                'String',xxxname, ...
            ...    'BackgroundColor','g', ...
                'FontWeight','bold', ...
                'Callback', @(~,~) this.labelbtnCallback(control,xxxdef,xxxindx,xxxname), ...
                'ToolTipString',['More options for ''',xxxname,'''']);
       
            % Listen for widget refresh events from the control panel.
            this.listener1 = addlistener(control,'refresh', @(~,~) this.refresh(control,xxxdef,xxxindx,modecheckbox));
            this.listener2 = addlistener(control,xxxdef, @(~,~) this.refresh(control,xxxdef,xxxindx,modecheckbox));
        end
        
       % Destructor
        function delete(this)
            delete(this.listener2);
            delete(this.listener1);
        end

        function mode(this,flag)            
            %disp('bdControlScalar.mode()');
            if flag
                set(this.minbox,'Visible','off');
                set(this.maxbox,'Visible','off');
                set(this.jslider,'Visible',1);
            else
                set(this.jslider,'Visible',0);
                set(this.minbox,'Visible','on');
                set(this.maxbox,'Visible','on');
            end                        
        end

    end
   
    methods (Access=private)
        
        % min box callback function
        function minboxCallback(this,control,xxxdef,xxxindx)
            %disp('bdControlScalar.minboxCallback()');
            % read the minbox string and convert to a number
            str = this.minbox.String;
            minval = str2double(str);
            if isnan(minval)
                hndl = errordlg(['Invalid number: ',str], 'Invalid Number', 'modal');
                uiwait(hndl);
                % restore the minbox string to its previous value
                this.minbox.String = num2str(this.minbox.Value,'%0.3g');                 
            else           
                % update the minbox value
                this.minbox.Value = minval;

                % update the maxbox widget if necessary
                if this.maxbox.Value < minval
                    this.maxbox.Value = minval;
                    this.maxbox.String = num2str(minval,'%0.3g');                
                end
                
                % update the slider widget
                this.sliderUpdate(this.minbox.Value, this.maxbox.Value, this.valbox.Value);
                            
                % update control.sys
                control.sys.(xxxdef)(xxxindx).lim(1) = minval;
                
                % update the dialog box (if it exists)
                if isvalid(this.dialog)
                    this.dialog.refresh(xxxdef,xxxindx);
                end

                % notify all display panels to redraw themselves
                notify(control,'redraw');
            end
        end        

        % max box callback function
        function maxboxCallback(this,control,xxxdef,xxxindx)
            %disp('bdControlScalar.maxboxCallback()');
            % read the maxbox string and convert to a number
            str = this.maxbox.String; 
            maxval = str2double(str);
            if isnan(maxval)
                hndl = errordlg(['Invalid number: ',str], 'Invalid Number', 'modal');
                uiwait(hndl);
                % restore the maxbox string to its previous value
                this.maxbox.String = num2str(this.maxbox.Value,'%0.3g');                 
            else           
                % update the maxbox value
                this.maxbox.Value = maxval;

                % update the minbox widget if necessary
                if this.minbox.Value > maxval
                    this.minbox.Value = maxval;
                    this.minbox.String = num2str(maxval,'%0.3g');                
                end
                     
                % update the slider widget
                this.sliderUpdate(this.minbox.Value, this.maxbox.Value, this.valbox.Value);

                % update control.sys
                control.sys.(xxxdef)(xxxindx).lim(2) = maxval;

                % update the dialog box (if it exists)
                if isvalid(this.dialog)
                    this.dialog.refresh(xxxdef,xxxindx);
                end
                
                % notify all display panels to redraw themselves
                notify(control,'redraw');
            end
        end        

        % val box callback function
        function valboxCallback(this,control,xxxdef,xxxindx)
            %disp('bdControlScalar.valboxCallback()');
            % read the valbox string and convert to a number
            str = this.valbox.String; 
            val = str2double(str);
            if isnan(val)
                hndl = errordlg(['Invalid number: ',str], 'Invalid Number', 'modal');
                uiwait(hndl);
                % restore the valbox string to its previous value
                this.valbox.String = num2str(this.valbox.Value,'%0.3g');                 
            else           
                % update the valbox value
                this.valbox.Value = val;

                % update the slider widget
                this.sliderUpdate(this.minbox.Value, this.maxbox.Value, this.valbox.Value);

                % update control.sys
                control.sys.(xxxdef)(xxxindx).value = val;

                % update the dialog box (if it exists)
                if isvalid(this.dialog)
                    this.dialog.refresh(xxxdef,xxxindx);
                end
                
                % tell the control panel to recompute the solution
                notify(control,'recompute');
            end
        end        
        
        % jslider callback function
        function sliderCallback(this,control,xxxdef,xxxindx)
            %disp('bdControlScalar.sliderCallback()');
            % get the slider value (0..100)
            sliderval = get(this.jslider,'Value');
            
            % convert the slider value to (min..max) range 
            minval = this.minbox.Value;
            maxval = this.maxbox.Value;
            val = (maxval-minval)*sliderval/100.0 + minval;
            
            % assign the new value to the edit box
            this.valbox.Value = val;
            this.valbox.String = num2str(val,'%0.3g');

            % update control.sys
            control.sys.(xxxdef)(xxxindx).value = val;

            % update the dialog box (if it exists)
            if isvalid(this.dialog)
                this.dialog.refresh(xxxdef,xxxindx);
            end

            % tell the control panel to recompute the solution
            notify(control,'recompute');
        end
        
        % update the jslider widget
        function sliderUpdate(this,minval,maxval,val)
            % disable the slider callback function
            jslidercallback = this.jslider.StateChangedCallback;
            this.jslider.StateChangedCallback = [];
            
            % update the slider value (0..100)
            sliderval = 100*(val - minval)/(maxval - minval);
            set(this.jslider,'Value',sliderval);
            
            % re-enable the slider callback
            this.jslider.StateChangedCallback = jslidercallback;
        end
        
        % label button callback function
        function labelbtnCallback(this,control,xxxdef,xxxindx,xxxname)
            if isvalid(this.dialog)
                % a dialog box already exists, make it visible
                this.dialog.visible('on');
            else
                % contruct a new dialog box
                this.dialog = bdControlScalarDialog(control,xxxdef,xxxindx,['''',xxxname,'''']);
            end      
        end
        
        % Update the widgets according to the values in control.sys.xxxdef
        function refresh(this,control,xxxdef,xxxindx,modecheckbox) 
            %disp(['bdControlScalar.refresh:' xxxdef]);
            
            % extract the relevant fields from control.sys.xxxdef
            xxxvalue = control.sys.(xxxdef)(xxxindx).value;
            xxxlim   = control.sys.(xxxdef)(xxxindx).lim;

            % update the min box widget
            this.minbox.Value = xxxlim(1);
            this.minbox.String = num2str(xxxlim(1),'%0.3g');
            
            % update the max box widget
            this.maxbox.Value = xxxlim(2);
            this.maxbox.String = num2str(xxxlim(2),'%0.3g');
            
            % update the val box widget
            this.valbox.Value = xxxvalue;
            this.valbox.String = num2str(xxxvalue,'%0.3g');

            % update the slider widget
            this.sliderUpdate(xxxlim(1), xxxlim(2), xxxvalue);
            
            % show/hide the slider widget according to the state of the caller's modecheckbox
            this.mode(modecheckbox.Value)
        end
        
    end
    
end

