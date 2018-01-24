classdef bdControlMatrix < handle
    %bdControlMatrix  Control panel widget for matrix values in bdGUI.
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
        rowh = 54;
        roww = 220;
    end

    properties (Access=private)
        parent
        panel
        minbox
        maxbox
        imgaxes
        imgplot
        labelbtn
        listener1
        listener2
        dialog
    end
    
    methods
        function this = bdControlMatrix(control,xxxdef,xxxindx,parent,ypos)
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
            boxh = 20;
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
                'Position',[col1 17 colw boxh], ...
                'String',num2str(xxxlim(1),'%0.4g'), ...
                'Value',xxxlim(1), ...
                'HorizontalAlignment','center', ...
                'Visible','on', ...
                'Callback', @(~,~) this.minboxCallback(control,xxxdef,xxxindx), ...
                'ToolTipString',['lower limit for ''' xxxname '''']);

            % Construct the max box
            this.maxbox = uicontrol('Parent',this.panel, ...
                'Style', 'edit', ...
                'Units','pixels',...
                'Position',[col2 17 colw boxh], ...
                'String',num2str(xxxlim(2),'%0.4g'), ...
                'Value',xxxlim(2), ...
                'HorizontalAlignment','center', ...
                'Visible','on', ...
                'Callback', @(~,~) this.maxboxCallback(control,xxxdef,xxxindx), ...
                'ToolTipString',['upper limit for ''' xxxname '''']);
                        
            % construct image widget for the matrix
            this.imgaxes = axes('Parent', this.panel, ...
                'Units','pixels', ...
                'Position',[col3+1 3 colw-2 colw-2]);
            this.imgplot = imagesc(xxxvalue(:,:,1), ...
                'Parent',this.imgaxes, ...
                xxxlim);
            axis off;

            % Construct the label button
            this.labelbtn = uicontrol('Parent',this.panel, ...
                'Style', 'pushbutton', ...
                'Units','pixels',...
                'Position',[col4 17 labelw boxh], ...
                'String',xxxname, ...
            ...    'BackgroundColor','g', ...
                'FontWeight','bold', ...
                'Callback', @(~,~) this.labelbtnCallback(control,xxxdef,xxxindx,xxxname), ...
                'ToolTipString','Click to edit');
            
            % listen for widget refresh events from the control panel 
            this.listener1 = addlistener(control,'refresh', @(~,~) this.refresh(control,xxxdef,xxxindx));
            this.listener2 = addlistener(control,xxxdef, @(~,~) this.refresh(control,xxxdef,xxxindx));
        end
        
        % Destructor
        function delete(this)
            delete(this.listener2);
            delete(this.listener1);
        end

        function mode(this,flag)            
            %disp('bdControlMatrix.mode()');
            if flag
                set(this.minbox,'Visible','off');
                set(this.maxbox,'Visible','off');
            else
                set(this.minbox,'Visible','on');
                set(this.maxbox,'Visible','on');
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
       
        % Update the widgets according to the values in control.sys.xxxdef
        function refresh(this,control,xxxdef,xxxindx) 
            disp(['bdControlMatrix.refresh:' xxxdef]);
            
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
        end
        
    end
    
end

