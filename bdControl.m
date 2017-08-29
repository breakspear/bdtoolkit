classdef bdControl < handle
    %bdControl  Control panel for the Brain Dynamics Toolbox.
    %  Internal toolbox object not intended to be called by end-users.
    % 
    %AUTHORS
    %  Stewart Heitmann (2016a,2017a-c)

    % Copyright (C) 2016,2017 QIMR Berghofer Medical Research Institute
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
        sys         % user-supplied system definition
        sol = []    % solution struct returned by the matlab solver
        sox = []    % auxiliary variables (computed by sys.auxfun)
        solvermap   % maps the solver functions to name and type strings
        solveridx   % index of the active solver
        halt = 0    % state of the HALT button
    end
    
    properties (Access=private)
        fig         % handle of parent figure
        hld         % handle to HOLD button
        %hlt         % handle to HALT button
        cpustart    % cpu start time
        cpu         % handle to cpu clock
        pro         % handle to progress counter
%        listeners   % array of listeners
    end
    
    events
        recompute   % signals that sol must be recomputed
        redraw      % signals that sol must be replotted
        refresh     % signals the widgets to refresh their values
        closefig    % tell all child figures to close
    end
    
    methods
        function this = bdControl(panel,sys)
            % Check the contents of sys and fill any missing fields with
            % default values. Rethrow any problems back to the caller.
            try
                sys = bd.syscheck(sys);
            catch ME
                throwAsCaller(MException('bdtoolkit:bdControl',ME.message));
            end
            
            % init the sol struct
            this.sol.x=[];
            this.sol.y=[];
            this.sol.yp=[];
            this.sol.stats.nsteps=0;
            this.sol.stats.nfailed=0;
            this.sol.stats.nfevals=0;
            
            % take a working copy of the system struct
            this.sys = sys;
            
            % init the listener array
            %this.listeners = event.listener.empty(0);
            
            % contrsuct the solver map
            this.solvermap = bd.solverMap(sys); 
            
            % currently active solver
            this.solveridx = 1;            
            
            % remember the parent figure
            this.fig = ancestor(panel,'figure');
            
            % get parent geometry
            panelw = panel.Position(3);
            panelh = panel.Position(4);

            % Begin placing widgets at the top left of parent.
            % We use the UserData field of each widget to remember its
            % preferred vertical position. It makes resizing easier.
            yoffset = 0;
            posw = panelw - 10;
            boxw = 50;
            boxh = 20;
            rowh = 22;            
                                 
            % next row
            yoffset = yoffset + rowh;                                    
            
            % parameter title
            uicontrol('Style','text', ...
                'String','Parameters', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'FontWeight','bold', ...
                'Parent', panel, ...
                'UserData', yoffset, ...
                'Tag', 'bdControlWidget', ...
                'Position',[0 panelh-yoffset posw boxh]);
            
            % ODE parameter widgets
            for parindx=1:numel(sys.pardef)
                parstr = sys.pardef(parindx).name;    % parameter name (string)
                parval = sys.pardef(parindx).value;   % parameter value (vector)
       
                % switch depending on parval being a scalar, vector or matrix
                switch ScalarVectorMatrix(parval)
                    case 1  % parval is a scalar              
                        % next row
                        yoffset = yoffset + rowh;
            
                        % construct edit box for the scalar
                        uiobj = uicontrol('Style','edit', ...
                            'String',num2str(parval,'%0.4g'), ...
                            'Value',parval, ...
                            'HorizontalAlignment','right', ...
                            'FontUnits','pixels', ...
                            'FontSize',12, ...
                            'Parent', panel, ...
                            'UserData', yoffset, ...
                            'Tag', 'bdControlWidget', ...
                            'Callback', @(hObj,~) this.ScalarParameter(hObj,parindx), ...
                            'Position',[0 panelh-yoffset boxw boxh]);
                        
                        % listen to the control panel for widget refresh events
                        %this.listeners(end+1) = addlistener(this,'parwidget',@(~,~) this.UpdateParWidgets(parindx,uiobj));    
                        addlistener(this,'refresh',@(~,~) this.ScalarParameterRefresh(parindx,uiobj));    

                        % string label
                        uicontrol('Style','text', ...
                            'String',parstr, ...
                            'HorizontalAlignment','left', ...
                            'FontUnits','pixels', ...
                            'FontSize',12, ...
                            'Parent', panel, ...
                            'UserData', yoffset, ...
                            'Tag', 'bdControlWidget', ...
                            'Position',[boxw+5 panelh-yoffset posw-boxw-10 boxh]);
                        
                    case 2  % parval is a vector
                        % next row
                        yoffset = yoffset + rowh;

                        % construct bar graph widget for the vector
                        ax = axes('parent', panel, ...
                            'Units','pixels', ...
                            'Position',[0 panelh-yoffset boxw boxh]);
                        barobj = bar(ax,parval, ...
                            'ButtonDownFcn', @(~,~) bdControlVector(this,'pardef',parstr,['Parameters: ',parstr]) );
                        xlim([0.5 numel(parval)+0.5]);
                        set(ax,'Tag','bdControlWidget', 'UserData',yoffset);
                        axis 'off';

                        % listen to the control panel for widget refresh events
                        addlistener(this,'refresh',@(~,~) this.VectorParameterRefresh(parindx,barobj));    

                        % string label
                        uicontrol('Style','text', ...
                            'String',parstr, ...
                            'HorizontalAlignment','left', ...
                            'FontUnits','pixels', ...
                            'FontSize',12, ...
                            'Parent', panel, ...
                            'UserData', yoffset, ...
                            'Tag', 'bdControlWidget', ...
                            'Position',[boxw+5 panelh-yoffset posw-boxw-10 boxh]);

                    case 3  % parval is a matrix
                        % next row
                        yoffset = yoffset + boxw + 2;

                        % construct image widget for the matrix
                        ax = axes('parent', panel, ...
                            'Units','pixels', ...
                            'Position',[0 panelh-yoffset boxw boxw]);
                        imObj = imagesc(parval(:,:,1), 'Parent',ax, ...
                            'ButtonDownFcn', @(~,~) bdControlMatrix(this,'pardef',parstr,['Parameters: ',parstr]) );
                        axis off;
                        set(ax,'Tag','bdControlWidget', 'UserData',yoffset); 

                        % listen to the control panel for widget refresh events
                        addlistener(this,'refresh',@(~,~) this.MatrixParameterRefresh(parindx,imObj));    

                        % string label
                        uicontrol('Style','text', ...
                            'String',parstr, ...
                            'HorizontalAlignment','left', ...
                            'FontUnits','pixels', ...
                            'FontSize',12, ...
                            'Parent', panel, ...
                            'UserData', yoffset-15, ...
                            'Tag', 'bdControlWidget', ...
                            'Position',[boxw+5 panelh-(yoffset-15) posw-boxw-10 boxh]);
                end
            end
                       
            % SDE random-hold widgets (if applicable)
            if isfield(sys,'sdeF')
                % next row
                yoffset = yoffset + 1.5*rowh;                    
                
                 % lag title
                uicontrol('Style','text', ...
                    'String','Noise Samples', ...
                    'HorizontalAlignment','left', ...
                    'FontUnits','pixels', ...
                    'FontSize',12, ...
                    'FontWeight','bold', ...
                    'Parent', panel, ...
                    'UserData', yoffset, ...
                    'Tag', 'bdControlWidget', ...
                    'Position',[0 panelh-yoffset posw boxh]);

                % next row
                yoffset = yoffset + 0.9*rowh;                    

                % HOLD button
                this.hld = uicontrol('Style','radio', ...
                    'String','Hold', ...
                    'Value', (isfield(sys.sdeoption,'randn') && ~isempty(sys.sdeoption.randn) ), ...
                    'HorizontalAlignment','left', ...
                    'FontUnits','pixels', ...
                    'FontSize',12, ...
                    'FontWeight','normal', ...
                    'ForegroundColor', 'k', ...
                    'Parent', panel, ...
                    'UserData', yoffset, ...
                    'Tag', 'bdControlWidget', ...
                    'ToolTipString', 'Hold the random samples fixed', ...
                    'Callback', @(~,~) this.HoldCallback(), ...
                    'Position',[0 panelh-yoffset 2*boxw+5 boxh]);  
            end
            
            % DDE lag widgets (if applicable)
            if isfield(sys,'lagdef')
                % next row
                yoffset = yoffset + 1.5*rowh;                                    

                % lag title
                uicontrol('Style','text', ...
                    'String','Time Lags', ...
                    'HorizontalAlignment','left', ...
                    'FontUnits','pixels', ...
                    'FontSize',12, ...
                    'FontWeight','bold', ...
                    'Parent', panel, ...
                    'UserData', yoffset, ...
                    'Tag', 'bdControlWidget', ...
                    'Position',[0 panelh-yoffset posw boxh]);

                % for each lagdef entry
                for lagindx=1:numel(sys.lagdef)
                    lagstr = sys.lagdef(lagindx).name;    % lag name (string)
                    lagval = sys.lagdef(lagindx).value;   % lag value (vector)

                    % switch depending on lagval being a scalar, vector or matrix
                    switch ScalarVectorMatrix(lagval)
                        case 1  % lagval is a scalar              
                            % next row
                            yoffset = yoffset + rowh;

                            % construct edit box for the scalar
                            uiobj = uicontrol('Style','edit', ...
                                'String',num2str(lagval,'%0.4g'), ...
                                'Value',lagval, ...
                                'HorizontalAlignment','right', ...
                                'FontUnits','pixels', ...
                                'FontSize',12, ...
                                'Parent', panel, ...
                                'UserData', yoffset, ...
                                'Tag', 'bdControlWidget', ...
                                'Callback', @(hObj,~) this.ScalarLag(hObj,lagindx), ...
                                'Position',[0 panelh-yoffset boxw boxh]);
                           
                            % listen to the control panel for widget refresh events
                            addlistener(this,'refresh',@(~,~) this.ScalarLagRefresh(lagindx,uiobj));    

                            % string label
                            uicontrol('Style','text', ...
                                'String',lagstr, ...
                                'HorizontalAlignment','left', ...
                                'FontUnits','pixels', ...
                                'FontSize',12, ...
                                'Parent', panel, ...
                                'UserData', yoffset, ...
                                'Tag', 'bdControlWidget', ...
                                'Position',[boxw+5 panelh-yoffset posw-boxw-10 boxh]);

                        case 2  % lagval is a vector
                            % next row
                            yoffset = yoffset + rowh;

                            % construct bar graph widget for the vector
                            ax = axes('parent', panel, ...
                                'Units','pixels', ...
                                'Position',[0 panelh-yoffset boxw boxh]);
                            barobj = bar(ax,lagval, ...
                                'ButtonDownFcn', @(~,~) bdControlVector(this,'lagdef',lagstr,['Time Lags: ',lagstr]) );
                            xlim([0.5 numel(lagval)+0.5]);
                            set(ax,'Tag','bdControlWidget', 'UserData',yoffset);
                            axis 'off';

                            % listen to the control panel for widget refresh events
                            addlistener(this,'refresh',@(~,~) this.VectorLagRefresh(lagindx,barobj));    

                            % string label
                            uicontrol('Style','text', ...
                                'String',lagstr, ...
                                'HorizontalAlignment','left', ...
                                'FontUnits','pixels', ...
                                'FontSize',12, ...
                                'Parent', panel, ...
                                'UserData', yoffset, ...
                                'Tag', 'bdControlWidget', ...
                                'Position',[boxw+5 panelh-yoffset posw-boxw-10 boxh]);

                        case 3  % parval is a matrix
                            % next row
                            yoffset = yoffset + boxw + 2;

                            % construct image widget for the matrix
                            ax = axes('parent', panel, ...
                                'Units','pixels', ...
                                'Position',[0 panelh-yoffset boxw boxw]);
                            imObj = imagesc(lagval, 'Parent',ax, ...
                                'ButtonDownFcn', @(~,~) bdControlMatrix(this,'lagdef',lagstr,['Time Lags: ',lagstr]) );
                            
                            axis off;
                            set(ax,'Tag','bdControlWidget', 'UserData',yoffset); 

                            % listen to the control panel for widget refresh events
                            addlistener(this,'refresh',@(~,~) this.MatrixLagRefresh(lagindx,imObj));    

                            % string label
                            uicontrol('Style','text', ...
                                'String',lagstr, ...
                                'HorizontalAlignment','left', ...
                                'FontUnits','pixels', ...
                                'FontSize',12, ...
                                'Parent', panel, ...
                                'UserData', yoffset-15, ...
                                'Tag', 'bdControlWidget', ...
                                'Position',[boxw+5 panelh-(yoffset-15) posw-boxw-10 boxh]);
                    end
                end                
            end            
            
            % next row
            yoffset = yoffset + 1.5*rowh;

            % variable title
            uicontrol('Style','text',...
                'String','Initial Conditions', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'FontWeight','bold', ...
                'Parent', panel, ...
                'UserData', yoffset, ...
                'Tag', 'bdControlWidget', ...
                'Position',[0 panelh-yoffset posw boxh]);
            
            % ODE variable widgets (initial conditions)
            for varindx=1:numel(sys.vardef)
                varstr = sys.vardef(varindx).name;    % variable name (string)
                varval = sys.vardef(varindx).value;   % variable initial value (vector)

                % switch depending on varval being a scalar, vector or matrix
                switch ScalarVectorMatrix(varval)
                    case 1  % varval is a scalar              
                        % next row
                        yoffset = yoffset + rowh;
                
                        % construct edit box for the scalar
                        uiobj = uicontrol('Style','edit', ...
                            'String',num2str(varval,'%0.4g'), ...
                            'Value',varval, ...
                            'HorizontalAlignment','right', ...
                            'FontUnits','pixels', ...
                            'FontSize',12, ...
                            'Parent', panel, ...
                            'UserData', yoffset, ...
                            'Tag', 'bdControlWidget', ...
                            'Callback', @(hObj,~) this.ScalarVariable(hObj,varindx), ...
                            'Position',[0 panelh-yoffset boxw boxh]);
                        
                        % listen to the control panel for widget refresh events
                        addlistener(this,'refresh',@(~,~) this.ScalarVariableRefresh(varindx,uiobj));    

                        % string label
                        uicontrol('Style','text', ...
                            'String',varstr, ...
                            'HorizontalAlignment','left', ...
                            'FontUnits','pixels', ...
                            'FontSize',12, ...
                            'Parent', panel, ...
                            'UserData', yoffset, ...
                            'Tag', 'bdControlWidget', ...
                            'Position',[boxw+5 panelh-yoffset posw-boxw-10 boxh]);
                        
                    case 2  % varval is a vector
                        % next row
                        yoffset = yoffset + rowh;
                        
                        % construct bar graph widget for thr vector
                        ax = axes('parent', panel, ...
                            'Units','pixels', ... 
                            'Position',[0 panelh-yoffset boxw boxh]);
                        barobj = bar(ax,varval, ...
                            'ButtonDownFcn', @(~,~) bdControlVector(this,'vardef',varstr,['Initial Conditions: ',varstr]) );
                        xlim([0.5 numel(varval)+0.5]);
                        set(ax,'Tag','bdControlWidget', 'UserData',yoffset);
                        axis 'off';

                        % listen to the control panel for widget refresh events
                        addlistener(this,'refresh',@(~,~) this.VectorVariableRefresh(varindx,barobj));    

                        % string label
                        uicontrol('Style','text', ...
                            'String',varstr, ...
                            'HorizontalAlignment','left', ...
                            'FontUnits','pixels', ...
                            'FontSize',12, ...
                            'Parent', panel, ...
                            'UserData', yoffset, ...
                            'Tag', 'bdControlWidget', ...
                            'Position',[boxw+5 panelh-yoffset posw-boxw-10 boxh]);
                        
                    case 3  % varval is a matrix
                        % next row
                        yoffset = yoffset + boxw + 5;
                        
                        % construct image widget for the matrix
                        ax = axes('parent', panel, ...
                            'Units','pixels', ...
                            'Position',[0 panelh-yoffset+2.5 boxw boxw]);
                        imObj = imagesc(varval, 'Parent',ax, ...
                            'ButtonDownFcn', @(~,~) bdControlMatrix(this,'vardef',varstr,['Initial Conditions: ',varstr]) );
                        axis off;
                        set(ax,'Tag','bdControlWidget', 'UserData',yoffset);                         
                        
                        % listen to the control panel for widget refresh events
                        addlistener(this,'refresh',@(~,~) this.MatrixVariableRefresh(varindx,imObj));    

                        % string label
                        uicontrol('Style','text', ...
                            'String',varstr, ...
                            'HorizontalAlignment','left', ...
                            'FontUnits','pixels', ...
                            'FontSize',12, ...
                            'Parent', panel, ...
                            'UserData', yoffset+17.5, ...
                            'Tag', 'bdControlWidget', ...
                            'Position',[boxw+5 panelh-yoffset+17.5 posw-boxw-10 boxh]);                        
                end

            end
            
            % next row
            yoffset = yoffset + 1.5*rowh;                        

            % time domain
            uicontrol('Style','text',...
                'String','Time Domain', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'FontWeight','bold', ...
                'Parent', panel, ...
                'UserData', yoffset, ...
                'Tag', 'bdControlWidget', ...
                'Position',[0 panelh-yoffset posw boxh]);
            
            % next row
            yoffset = yoffset + rowh;

            % start time
            uicontrol('Style','edit', ...
                'String',num2str(sys.tspan(1),'%0.4g'), ...
                'Value', sys.tspan(1), ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', panel, ...
                'UserData', yoffset, ...
                'Tag', 'bdControlWidget', ...
                'Callback', @(src,~) this.ScalarTspan(src,1), ...
                'Position',[0 panelh-yoffset boxw boxh]);
            
            % end time
            uicontrol('Style','edit', ...
                'String',num2str(sys.tspan(2),'%0.4g'), ...
                'Value', sys.tspan(2), ...
                'HorizontalAlignment','center', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'Parent', panel, ...
                'UserData', yoffset, ...
                'Tag', 'bdControlWidget', ...
                'Callback', @(src,~) this.ScalarTspan(src,2), ...
                'Position',[boxw+5 panelh-yoffset boxw boxh]);
          
            % next row
            yoffset = yoffset + 1.5*rowh;                        

            % Solver Heading
            uicontrol('Style','text', ...
                'String','CPU Time', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'FontWeight','bold', ...
                'Parent', panel, ...
                'UserData', yoffset, ...
                'Tag', 'bdControlWidget', ...
                'Position',[0 panelh-yoffset 2*boxw+5 boxh]);

            % listen to the control panel for widget refresh events
            addlistener(this,'refresh',@(~,~) this.CPUrefresh());    

            % next row
            yoffset = yoffset + boxh;                        

            % CPU time 
            this.cpu = uicontrol('Style','text',...
                'String','0.0s', ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',14, ...
                'FontWeight','normal', ...
                'Parent', panel, ...
                'UserData', yoffset, ...
                'Tag', 'bdControlWidget', ...
                'ToolTipString','CPU time (secs)', ...
                'Position',[0 panelh-yoffset boxw boxh]);

            % Progress counter  
            this.pro = uicontrol('Style','text',...
                'String','0%', ...
                'HorizontalAlignment','right', ...
                'FontUnits','pixels', ...
                'FontSize',14, ...
                'FontWeight','normal', ...
                'ForegroundColor', [0.5 0.5 0.5], ...
                'Parent', panel, ...
                'UserData', yoffset, ...
                'Tag', 'bdControlWidget', ...
                'ToolTipString','solver progress', ...
                'Position',[boxw+5 panelh-yoffset boxw boxh]);

            % next row
            yoffset = yoffset + 1.25*boxh;                        

            % HALT button
            %this.hlt = uicontrol('Style','radio', ...
            haltbutton = uicontrol('Style','radio', ...
                'String','HALT', ...
                'Value',this.halt, ...
                'HorizontalAlignment','left', ...
                'FontUnits','pixels', ...
                'FontSize',12, ...
                'FontWeight','bold', ...
                'ForegroundColor', 'r', ...
                'Parent', panel, ...
                'UserData', yoffset, ...
                'Tag', 'bdControlWidget', ...
                'ToolTipString', 'Halt the solver', ...
                'Callback', @(src,~) this.HaltCallback(src), ...
                'Position',[0 panelh-yoffset 2*boxw+5 boxh]);
            
            % listen to the control panel for widget refresh events
            addlistener(this,'refresh',@(~,~) this.HALTrefresh(haltbutton));    
            
            % register a callback for resizing the panel
            set(panel,'SizeChangedFcn', @(~,~) SizeChanged(this,panel));
            
            % listen for recompute events
            addlistener(this,'recompute',@(~,~) RecomputeListener(this));
        end
        
    end
    
    
    methods (Access=private)  
        % Callback for panel resizing. This function relies on each
        % widget having its desired yoffset stored in its UserData field.
        function SizeChanged(this,panel)
            % get new parent geometry
            panelh = panel.Position(4);
            
            % find all widgets in the control panel
            objs = findobj(panel,'Tag','bdControlWidget');
            
            % for each widget, adjust its y position according to its preferred position
            for indx = 1:numel(objs)
                obj = objs(indx);                       % get the widget handle
                yoffset = obj.UserData;                 % retrieve the preferred y position from UserData.
                obj.Position(2) = panelh - yoffset;     % apply the preferred y position
            end            
        end
        
        % Callback for parameter edit box
        function ScalarParameter(this,editObj,parindx)
            this.ScalarCallback(editObj);
            this.sys.pardef(parindx).value = editObj.Value;
            notify(this,'recompute');
        end
        
        % Refresh listener for parameter edit box
        function ScalarParameterRefresh(this,parindx,uiobj)
            parval = this.sys.pardef(parindx).value;
            uiobj.Value = parval;
            uiobj.String = num2str(parval,'%0.4g');
        end
        
        % Callback for DDE lag edit box
        function ScalarLag(this,editObj,lagindx)
            this.ScalarCallback(editObj);
            this.sys.lagdef(lagindx).value = editObj.Value;
            notify(this,'recompute');
        end
        
        % Refresh listener for DDE lag edit box
        function ScalarLagRefresh(this,lagindx,uiobj)
            lagval = this.sys.lagdef(lagindx).value;
            uiobj.Value = lagval;
            uiobj.String = num2str(lagval,'%0.4g');
        end
        
        % Callback for variable edit box
        function ScalarVariable(this,editObj,varindx)
            this.ScalarCallback(editObj);
            this.sys.vardef(varindx).value = editObj.Value;
            notify(this,'recompute');
        end

        % Refresh listener for variable edit box
        function ScalarVariableRefresh(this,varindx,uiobj)
            varval = this.sys.vardef(varindx).value;
            uiobj.Value = varval;
            uiobj.String = num2str(varval,'%0.4g');
        end        
        
        % Callback for time domain edit box
        function ScalarTspan(this,hObj,tindx)
            this.ScalarCallback(hObj);
            this.sys.tspan(tindx) = hObj.Value;
            notify(this,'recompute');            
        end

        % Callback for generic scalar edit box
        function ScalarCallback(this,hObj)
            % ensure hObj is still valid
            if ~isvalid(hObj)
                % The object no longer exists. User must have closed the parent window.
                return
            end
            
            % get the incoming value
            val = str2double(hObj.String);
            if isnan(val)
                dlg = errordlg(['Invalid Number ''', hObj.String, ''''],'Invalid number','modal');
                val = hObj.Value;           % restore the previous value                
                uiwait(dlg);                % wait for dialog box to close
            else
                hObj.Value = val;           % remember the new value
            end            
            
            % update the edit box string
            hObj.String = num2str(val,'%0.4g');
        end
        
        % Refresh listener for vector parameter widget
        function VectorParameterRefresh(this,parindx,barObj)
            parval = this.sys.pardef(parindx).value;
            barObj.YData = parval;
        end
        
        % Refresh listener for DDE lag widget
        function VectorLagRefresh(this,lagindx,barObj)
            lagval = this.sys.lagdef(lagindx).value;
            barObj.YData = lagval;
        end

        % Refresh listener for vector variable widget
        function VectorVariableRefresh(this,varindx,barObj)
            varval = this.sys.vardef(varindx).value;
            barObj.YData = varval;
        end
        
%         % Callback for parameter matrix widget
%         function MatrixParameter(this,imObj,name,parindx)
%             % open dialog box for editing a matrix
%             this.sys.pardef(parindx).value = bdEditMatrix(this.sys.pardef(parindx).value,name);
%             % update the image data in the control panel
%             set(imObj,'CData',this.sys.pardef(parindx).value);
%             notify(this,'recompute');
%         end

        % Refresh listener for matrix parameter widget
        function MatrixParameterRefresh(this,parindx,imObj)
            parval = this.sys.pardef(parindx).value;
            imObj.CData = parval;
        end

%         % Callback for DDE lag matrix widget
%         function MatrixLag(this,imObj,name,lagindx)
%             % open dialog box for editing a matrix
%             this.sys.lagdef(lagindx).value = bdEditMatrix(this.sys.lagdef(lagindx).value,name);
%             % update the image data in the control panel
%             set(imObj,'CData',this.sys.lagdef(lagindx).value);
%             notify(this,'recompute');
%         end

        % Refresh listener for DDE lag matrix widget
        function MatrixLagRefresh(this,lagindx,imObj)
            lagval = this.sys.lagdef(lagindx).value;
            imObj.CData = lagval;
        end
        
%         % Callback for ODE variable matrix widget
%         function MatrixVariable(this,imObj,name,varindx)
%             % open dialog box for editing a matrix
%             this.sys.vardef(varindx).value = bdEditMatrix(this.sys.vardef(varindx).value,name);
%             % update the image data in the control panel
%             set(imObj,'CData',this.sys.vardef(varindx).value);
%             notify(this,'recompute');
%         end
        
        % Refresh listener for variable matrix widget
        function MatrixVariableRefresh(this,varindx,imObj)
            varval = this.sys.vardef(varindx).value;
            imObj.CData = varval;
        end

        % Listener for the compute flag
        function RecomputeListener(this)
            % Do nothing if the HALT button is active
            if this.halt
                return
            end
            
            % Change mouse cursor to hourglass
            set(this.fig,'Pointer','watch');
            drawnow;

            % determine the active solver
            solverfunc = this.solvermap(this.solveridx).solverfunc;
            solvertype = this.solvermap(this.solveridx).solvertype;
            
            % We use the ODE OutputFcn to track progress in our solver
            % and to detect halt events. We specify tspan so that OutputFcn
            % is called 11 times. These correspond to 0%, 10%, ... , 100%
            % progress of the solver.
            tspan = linspace(this.sys.tspan(1), this.sys.tspan(2), 11);
            switch solvertype
                case 'odesolver'
                    this.sys.odeoption = odeset(this.sys.odeoption, 'OutputFcn',@this.odeplot, 'OutputSel',[]);
                case 'ddesolver'
                    this.sys.ddeoption = ddeset(this.sys.ddeoption, 'OutputFcn',@this.odeplot, 'OutputSel',[]);
                case 'sdesolver'
                    this.sys.sdeoption.OutputFcn = @this.odeplot;
                    this.sys.sdeoption.OutputSel = [];      
             end

            % Call the solver
            [this.sol,this.sox] = bd.solve(this.sys,tspan,solverfunc,solvertype);
            
            % Hold the SDEnoise if the HOLD button is 'on'
            switch solvertype
                case 'sdesolver'
                    if this.hld.Value==1 && isempty(this.sys.sdeoption.randn) 
                         dt = this.sol.x(2) - this.sol.x(1);
                         this.sys.sdeoption.randn = this.sol.dW ./ sqrt(dt);
                    end
            end
            
            % notify all listeners that a redraw is required
            notify(this,'redraw');
            
            % Change mouse cursor to arrow
            set(this.fig,'Pointer','arrow');
        end
        
        % ODE solver callback function
        function status = odeplot(this,tspan,~,flag,varargin)
            switch flag
                case 'init'
                    this.cpustart = cputime;
                case ''
                    cpu = cputime - this.cpustart;
                    this.cpu.String = num2str(cpu,'%5.2fs');
                    this.pro.String = num2str(100*tspan(1)/this.sys.tspan(2),'%3.0f%%');
                    drawnow;
                case 'done'
                   if this.halt~=1
                        cpu = cputime - this.cpustart;
                        this.cpu.String = num2str(cpu,'%5.2fs');
                        this.pro.String = '100%';
                        drawnow;
                   end
            end   
            % return the state of the HALT button
            status = this.halt;
        end

        % HOLD button callback
        function HoldCallback(this)
            if this.hld.Value==1
                dt = this.sol.x(2) - this.sol.x(1);
                this.sys.sdeoption.randn = this.sol.dW ./ sqrt(dt);
            else
                this.sys.sdeoption.randn = [];
            end
        end
        
        % Refresh listener for CPU button
        function CPUrefresh(this)
            if this.halt
                this.cpu.ForegroundColor = [0.5 0.5 0.5];
            else
                this.cpu.ForegroundColor = [0 0 0];
            end
        end

        % Refresh listener for HALT button
        function HALTrefresh(this,haltbutton)
            %disp('HALTrefresh');
            haltbutton.Value = this.halt;
        end

        % HALT button callback
        function HaltCallback(this,haltbutton)
            this.halt = haltbutton.Value;
            if this.halt
                this.cpu.ForegroundColor = [0.5 0.5 0.5];
                notify(this,'refresh');             % notify widgets to refresh themselves
            else
                this.cpu.ForegroundColor = [0 0 0];
                notify(this,'refresh');             % notify widgets to refresh themselves
                notify(this,'recompute');           % recompute the new solution
            end
        end
    end               
end

% Utility function to classify X as
% scalar (1), vector (2) or matrix (3)
function val = ScalarVectorMatrix(X)
    [nr,nc] = size(X);
    if nr*nc==1
        val = 1;        % X is scalar (1x1)
    elseif nr==1 || nc==1
        val = 2;        % X is vector (1xn) or (nx1)
    else
        val = 3;        % X is matrix (mxn)
    end
end


