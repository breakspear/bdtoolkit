classdef bdControlRun < handle
    %bdControlRun  Custom RUN button for the control panel.
    %  This class implements the RUN button using a custom Java button.
    %  It is not intended to be called directly by users.
    % 
    %AUTHORS
    %  Stewart Heitmann (2019a)

    % Copyright (C) 2016-2019 QIMR Berghofer Medical Research Institute
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
    
    properties (Dependent)
        Enable
        Visible
    end
    
    properties (Access=private)
        jbutton
        hjbutton
        hcontainer
    end
    
    methods
        function this = bdControlRun(control,parent,position)
            %disp('bdControlRun(control,parent,position)');
            fontname = parent.FontName;
            fontsize = 12;
            jfont = java.awt.Font(fontname,java.awt.Font.PLAIN,fontsize);
            this.jbutton = javax.swing.JButton('RUN');
            this.jbutton.setFont(jfont);
            
            % adjust the margin of the text inside the button
            jmargin = this.jbutton.getMargin();
            jmargin.left=0;
            jmargin.right=0;
            jmargin.top=0;
            jmargin.bottom=0;
            this.jbutton.setMargin(jmargin);
            
            [this.hjbutton,this.hcontainer] = javacomponent(this.jbutton, position, parent);
            set(this.hjbutton,'ToolTipText','Run (evolve) the simulation once more');
            %set(this.hjbutton,'ActionPerformedCallback', @(src,~) notify(control,'recompute'));
            set(this.hcontainer,'Visible','off');
        end
        
        % Get Enable property
        function val = get.Enable(this)
            %disp('bdControlRun.get.Enable');
            val = get(this.jbutton,'Enabled');
        end
        
        % Set Enable property
        function set.Enable(this,val)
            %disp('bdControlRun.set.Enable');
            switch val
                case 'on'
                    set(this.jbutton,'Enabled',1);
                case 'off'
                    set(this.jbutton,'Enabled',0);
            end
        end
        
        % Get Visible property
        function val = get.Visible(this)
            %disp('bdControlRun.get.Visible');
            val = get(this.hcontainer,'Visible');
        end
        
        % Set Visible property
        function set.Visible(this,val)
            %disp('bdControlRun.set.Visible');
            set(this.hcontainer,'Visible',val);
        end
        
        % Get Armed property
        function val = isArmed(this)
            %disp('bdControlRun.isArmed');
            val = this.jbutton.getModel().isArmed();
        end        
    end
end

