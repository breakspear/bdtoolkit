classdef bdControlTime < handle
   %bdControlTime  Control panel widget for the time domain.
    %  This class implements the control panel widgets for the time domain.
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
        redrawflag
        timer 
    end
    
    methods
        % Constructor
        function this = bdControlTime(control,parent,ypos,modecheckbox)
            %disp('bdControlTime()');
            
            % init the redraw flag
            this.redrawflag = false;

            % remeber our parent
            this.parent = parent;
            
            % extract the time domain values from control.sys
            tspan = control.sys.tspan;
            tval = control.sys.tval;
            
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
                'BorderType','none');
                
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
            this.jslider.StateChangedCallback = @(~,~) this.sliderCallback(control);
            this.jslider.ToolTipText = 'time slider';

            % update the value in the slider widget
            this.sliderUpdate(tspan(1),tspan(2),tval);

            % Construct the min box
            this.minbox = uicontrol('Parent',this.panel, ...
                'Style', 'edit', ...
                'Units','pixels',...
                'Position',[col1 2 colw this.rowh-4], ...
                'String',num2str(tspan(1),'%0.4g'), ...
                'Value',tspan(1), ...
                'HorizontalAlignment','center', ...
                'ForegroundColor', 'b', ...
                'Visible','off', ...
                'Callback', @(~,~) this.minboxCallback(control), ...
                'ToolTipString',['start time']);

            % Construct the max box
            this.maxbox = uicontrol('Parent',this.panel, ...
                'Style', 'edit', ...
                'Units','pixels',...
                'Position',[col2 2 colw this.rowh-4], ...
                'String',num2str(tspan(2),'%0.4g'), ...
                'Value',tspan(2), ...
                'HorizontalAlignment','center', ...
                'ForegroundColor', 'b', ...
                'Visible','off', ...
                'Callback', @(~,~) this.maxboxCallback(control), ...
                'ToolTipString','end time');
                  
            % Construct the val box
            this.valbox = uicontrol('Parent',this.panel, ...
                'Style', 'edit', ...
                'Units','pixels',...
                'Position',[col3 2 colw this.rowh-4], ...
                'String',num2str(tval,'%0.4g'), ...
                'Value',tval, ...
                'HorizontalAlignment','center', ...
                'FontWeight','bold', ...
                'Visible','on', ...
                'Callback', @(~,~) this.valboxCallback(control), ...
                'ToolTipString','end of transient window');
            
            % Construct the time label 
            uicontrol('Parent',this.panel, ...
                'Style', 'text', ...
                'Units','pixels',...
                'Position',[col4 2 labelw this.rowh-5], ...
                'String','time', ...
                'HorizontalAlignment', 'left', ...
            ...    'BackgroundColor','g', ...
                'FontWeight','bold');
       
            % listen for widget refresh events from the control panel 
            addlistener(control,'refresh', @(~,~) this.refresh(control,modecheckbox));
            
            % init the timer object and start it.           
            this.timer = timer('BusyMode','drop', ...
                'ExecutionMode','fixedSpacing', ...
                'Period',0.05, ...
                'TimerFcn', @(~,~) this.TimerFcn(control));
            start(this.timer);            
        end
  
        function mode(this,flag)            
            %disp('bdControlTime.mode()');
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

        % Destructor
        function delete(this)
            stop(this.timer);
            delete(this.timer);
        end
  end
   
    methods (Access=private)
        
        % min box callback function
        function minboxCallback(this,control)
            %disp('bdControlTime.minboxCallback()');
            % read the minbox string and convert to a number
            str = this.minbox.String;
            minval = str2double(str);
            if isnan(minval)
                hndl = errordlg(['Invalid number: ',str], 'Invalid Number', 'modal');
                uiwait(hndl);
                % restore the minbox string to its previous value
                this.minbox.String = num2str(this.minbox.Value,'%0.4g');                 
            else           
                % update the minbox value
                this.minbox.Value = minval;

                % update the maxbox widget if necessary
                if this.maxbox.Value < minval
                    this.maxbox.Value = minval;
                    this.maxbox.String = num2str(minval,'%0.4g');                
                end
                
                % update the valbox widget if necessary
                if this.valbox.Value < minval
                    this.valbox.Value = minval;
                    this.valbox.String = num2str(minval,'%0.4g');                
                end
                
                % update the slider widget
                this.sliderUpdate(this.minbox.Value, this.maxbox.Value, this.valbox.Value);
                            
                % update control.sys
                control.sys.tspan = [this.minbox.Value this.maxbox.Value];
                control.sys.tval = this.valbox.Value;

                % notify the solver to recompute the solution because the time domain has changed
                notify(control,'recompute');
            end
        end        

        % max box callback function
        function maxboxCallback(this,control)
            %disp('bdControlTime.maxboxCallback()');
            % read the maxbox string and convert to a number
            str = this.maxbox.String; 
            maxval = str2double(str);
            if isnan(maxval)
                hndl = errordlg(['Invalid number: ',str], 'Invalid Number', 'modal');
                uiwait(hndl);
                % restore the maxbox string to its previous value
                this.maxbox.String = num2str(this.maxbox.Value,'%0.4g');                 
            else           
                % update the maxbox value
                this.maxbox.Value = maxval;

                % update the minbox widget if necessary
                if this.minbox.Value > maxval
                    this.minbox.Value = maxval;
                    this.minbox.String = num2str(maxval,'%0.4g');                
                end
                     
                % update the valbox widget if necessary
                if this.valbox.Value > maxval
                    this.valbox.Value = maxval;
                    this.valbox.String = num2str(maxval,'%0.4g');                
                end
                
                % update the slider widget
                this.sliderUpdate(this.minbox.Value, this.maxbox.Value, this.valbox.Value);

                % update control.sys
                control.sys.tspan = [this.minbox.Value this.maxbox.Value];
                control.sys.tval = this.valbox.Value;

                % notify the solver to recompute the solution because the time domain has changed
                notify(control,'recompute');
            end
        end        

        % val box callback function
        function valboxCallback(this,control)
            %disp('bdControlTime.valboxCallback()');
            % read the valbox string and convert to a number
            str = this.valbox.String; 
            val = str2double(str);
            if isnan(val)
                hndl = errordlg(['Invalid number: ',str], 'Invalid Number', 'modal');
                uiwait(hndl);
                % restore the valbox string to its previous value
                this.valbox.String = num2str(this.valbox.Value,'%0.4g');                 
            else           
                % update the valbox value
                this.valbox.Value = val;

                % recompute flag
                recomputeflag = false;
                
                % update the minbox widget if necessary
                if this.minbox.Value > val
                    this.minbox.Value = val;
                    this.minbox.String = num2str(val,'%0.4g');
                    recomputeflag = true;
                end
                
                % update the maxbox widget if necessary
                if this.maxbox.Value < val
                    this.maxbox.Value = val;
                    this.maxbox.String = num2str(val,'%0.4g');
                    recomputeflag = true;
                end
                
                % update the slider widget
                this.sliderUpdate(this.minbox.Value, this.maxbox.Value, this.valbox.Value);

                % update control.sys
                control.sys.tspan = [this.minbox.Value this.maxbox.Value];
                control.sys.tval = this.valbox.Value;

                if recomputeflag
                    % notify the solver to recompute the solution because the time domain has changed
                    notify(control,'recompute');
                else
                    % update the indicies of the non-tranient time steps in sol.x
                    control.tindx = (control.sol.x >= control.sys.tval);
                    
                    % notify all display panels to redraw themselves
                    notify(control,'redraw');
                end
            end
        end        
        
        % jslider callback function
        function sliderCallback(this,control,xxxdef,xxxindx)
            %disp('bdControlTime.sliderCallback()');
            % get the slider value (0..100)
            sliderval = get(this.jslider,'Value');
            
            % convert the slider value to (min..max) range 
            minval = this.minbox.Value;
            maxval = this.maxbox.Value;
            val = (maxval-minval)*sliderval/100.0 + minval;
            
            % assign the new value to the edit box
            this.valbox.Value = val;
            this.valbox.String = num2str(val,'%0.4g');

            % update control.sys
            control.sys.tval = val;
                    
            % update the indicies of the non-tranient time steps in sol.x
            control.tindx = (control.sol.x >= control.sys.tval);
            
            % have the timer function notify all display panels to redraw themselves
            this.redrawflag = true;
            %notify(control,'redraw');            
        end
        
        % update the jslider widget
        function sliderUpdate(this,minval,maxval,val)
            % disable the slider callback function
            jslidercallback = this.jslider.StateChangedCallback;
            this.jslider.StateChangedCallback = [];
            
            % update the slider value (0..100)
            if minval==maxval
                sliderval = minval;
            else
                sliderval = 100*(val - minval)/(maxval - minval);
            end
            set(this.jslider,'Value',sliderval);
            
            % re-enable the slider callback
            this.jslider.StateChangedCallback = jslidercallback;
        end
        
        % Update the widgets according to the values in control
        function refresh(this,control,modecheckbox) 
            %disp('bdControlTime.refresh');
            
            % extract the relevant fields from control.sys
            tspan = control.sys.tspan;
            tval = control.sys.tval;
            
            % update the min box widget
            this.minbox.Value = tspan(1);
            this.minbox.String = num2str(tspan(1),'%0.4g');
            
            % update the max box widget
            this.maxbox.Value = tspan(2);
            this.maxbox.String = num2str(tspan(2),'%0.4g');
            
            % update the val box widget
            this.valbox.Value = tval;
            this.valbox.String = num2str(tval,'%0.4g');

            % update the slider widget
            this.sliderUpdate(tspan(1), tspan(2), tval);
            
            % show/hide the slider widget according to the state of the caller's modecheckbox
            this.mode(modecheckbox.Value)
        end
        
        % Timer function. It throttles the number of redraw events issued from the slider.        
        function TimerFcn(this,control)
            %disp('bdControlTim.TimerFcn');
            
            % if the parent object (ie the control panel) is gone then... 
            if ~ishghandle(this.parent)
                stop(this.timer);       % stop the timer
                return
            end
            
            % issue a redraw event if required
            if this.redrawflag
                this.redrawflag = false;
                notify(control,'redraw');
            end
        end

    end
    
end

