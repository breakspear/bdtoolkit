classdef bdTrapPanel < bdPanel
    %bdTrapPanel - Brain Dynamics Toolbox panel for debugging other panels.
    %   This panel constructs a dummy axis which it uses to detect (trap)
    %   erroneous drawing commands from other panels. Its purpose is to
    %   detect the most common programming error in display panels - that
    %   of drawing to the current graphics axes rather than a given axes handle.
    %
    %AUTHORS
    %  Stewart Heitmann (2017b,2018a)

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
        title = 'Trap';
    end
    
    properties
        ax              % Handle to the trap axes
    end

    properties (Access=private) 
        listener        % Handle to listener
    end

    methods        
        function this = bdTrapPanel(tabgroup,control)
            % Construct a new Trap Panel in the given tabgroup

            % initialise the base class (specifically this.menu and this.tab)
            this@bdPanel(tabgroup);
            
            % assign default values to missing options in sys.panels.bdTrapPanel
            control.sys.panels.bdTrapPanel = bdTrapPanel.syscheck(control.sys);

            % configure the pull-down menu
            this.menu.Label = control.sys.panels.bdTrapPanel.title;
            this.InitCloseMenu(control);

            % configure the panel graphics
            this.tab.Title = control.sys.panels.bdTrapPanel.title;
            this.InitSubpanel(control);

            % listen to the control panel for redraw events
            this.listener = addlistener(control,'redraw',@(~,~) this.redraw(control));
            
            % Set the current axis to this.ax. This is the honey in the trap.
            axes(this.ax);
        end
        
        function delete(this)
            % Destructor
            delete(this.listener)
        end
         
    end
    
    methods (Access = private)
        
        % Initialise the CLOSE menu item
        function InitCloseMenu(this,~)
            % construct the menu item
            uimenu(this.menu, ...
                   'Label','Close', ...
                   'Callback',@(~,~) this.close());
        end
        
        % Initialise the upper panel
        function InitSubpanel(this,control)
            % construct the subpanel
            [this.ax,~,spanel] = bdPanel.Subpanel(this.tab,[0 0 1 1],[0 0.35 1 0.6]);
            
            % Reset the axis properties to defaults
            cla(this.ax);
            reset(this.ax);

            % construct the message box
            msg = ['The Trap panel is useful for debugging user-defined GUI panels. ' ...
                   'It detects errant drawing commands in other panels by monitoring ' ...
                   'the decoy axis (above). The decoy axis should always appear blank. ' ...
                   'Any wayward drawing commands will trigger a warning dialog. ' ];
            uicontrol('Style','Text', ...
                'String',msg, ...
                'Parent',spanel, ...
                'Units','normal', ...
                'Position',[0.075 0 0.875 0.3], ...
          ...      'FontSize', 14, ...
                'HorizontalAlignment', 'left' );
        end
          
       % Check the trap axes for anything suspicious
       function redraw(this,control)
            %disp('bdTrapPanel.redraw()') 
            
            % Error messages are accumulated in this cell array.
            errmsgs = {};
            
            % Detect illegal drawing activity
            if ~isempty(this.ax.Children)
                errmsgs{end+1} = '* Plotting has been detected.';
            end            
            if ~isequal(this.ax.ALim,[0 1])
                errmsgs{end+1} = '* The ALIM property has been altered.';
            end            
            if ~strcmp(this.ax.Box,'off')
                errmsgs{end+1} = '* The BOX property has been altered';
            end            
            if ~isequal(this.ax.CLim,[0 1])
                errmsgs{end+1} = '* The CLIM property has been altered.';
            end            
            if ~strcmp(this.ax.Clipping,'on')
                errmsgs{end+1} = '* The CLIPPING property has been altered';
            end            
            if ~isequal(this.ax.Color,[1 1 1])
                errmsgs{end+1} = '* The COLOR property has been altered.';
            end            
            if ~strcmp(this.ax.FontAngle,'normal')
                errmsgs{end+1} = '* The FONTANGLE property has been altered';
            end            
            if ~strcmp(this.ax.FontName,'Helvetica')
                errmsgs{end+1} = '* The FONTNAME property has been altered';
            end            
            if this.ax.FontSize ~= 10
                errmsgs{end+1} = '* The FONTSIZE property has been altered';
            end            
            if ~strcmp(this.ax.FontUnits,'points')
                errmsgs{end+1} = '* The FONTUNITS property has been altered';
            end            
            if ~strcmp(this.ax.FontWeight,'normal')
                errmsgs{end+1} = '* The FONTWEIGHT property has been altered';
            end            
            if ~strcmp(this.ax.GridLineStyle,'-')
                errmsgs{end+1} = '* The GRIDLINESTYLE property has been altered';
            end            
            if ~strcmp(this.ax.Projection,'orthographic')
                errmsgs{end+1} = '* The ORTHOGRAPHIC property has been altered';
            end            
            if ~isempty(this.ax.Title.String)
                errmsgs{end+1} = '* The TITLE property has been altered';
            end
            if ~isempty(this.ax.UserData)
                errmsgs{end+1} = '* The USERDATA property has been altered.';
            end            
            if ~isequal(this.ax.View,[0 90])
                errmsgs{end+1} = '* The VIEW property has been altered';
            end
            if ~strcmp(this.ax.XGrid,'off')
                errmsgs{end+1} = '* The XGRID property has been altered';
            end            
            if ~isequal(this.ax.XLim,[0 1])
                errmsgs{end+1} = '* The XLIM property has been altered.';
            end            
            if ~strcmp(this.ax.XScale,'linear')
                errmsgs{end+1} = '* The XSCALE property has been altered';
            end            
            if ~strcmp(this.ax.YGrid,'off')
                errmsgs{end+1} = '* The YGRID property has been altered';
            end            
            if ~isequal(this.ax.YLim,[0 1])
                errmsgs{end+1} = '* The YLIM property has been altered';
            end            
            if ~strcmp(this.ax.YScale,'linear')
                errmsgs{end+1} = '* The YSCALE property has been altered';
            end               
            if ~strcmp(this.ax.ZGrid,'off')
                errmsgs{end+1} = '* The ZGRID property has been altered';
            end            
            if ~isequal(this.ax.ZLim,[0 1])
                errmsgs{end+1} = '* The ZLIM property has been altered.';
            end            
            if ~strcmp(this.ax.ZScale,'linear')
                errmsgs{end+1} = '* The ZSCALE property has been altered';
            end            
            
            if ~isempty(errmsgs)
                msg = ['Something has illegally drawn into the Trap axes.', ...
                       errmsgs, ...
                       'It is likely that one of the currently loaded display panels is to blame.', ...
                       'This usually happens when a panel draws into the current axes instead of its own axes handle.'];
                for indx = 1:numel(msg)
                    disp(msg{indx});
                end
                waitfor(warndlg(msg,'Trap Panel','modal'));
            end
            
            % Reset the axis properties to defaults
            cla(this.ax);
            reset(this.ax);

            % Ensure this.ax the current axis. This is the honey in the trap.
            axes(this.ax);     
       end
       
    end
    
    methods (Static)
        
        % Check the sys.panels struct
        function syspanel = syscheck(sys)
            % Default panel settings
            syspanel.title = bdTrapPanel.title;
            
            % Nothing more to do if sys.panels.bdTrapPanel is undefined
            if ~isfield(sys,'panels') || ~isfield(sys.panels,'bdTrapPanel')
                return;
            end
            
            % sys.panels.bdTrapPanel.title
            if isfield(sys.panels.bdTrapPanel,'title')
                syspanel.title = sys.panels.bdTrapPanel.title;
            end
        end   
        
    end
end

