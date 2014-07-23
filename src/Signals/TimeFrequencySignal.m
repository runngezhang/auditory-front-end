classdef TimeFrequencySignal < Signal
    % This children signal class regroups all signal that are some sort of
    % time frequency representation (e.g., spectrograms, filterbank
    % outputs, etc...)
    
    properties
        cfHz        % Center frequencies of the frequency channels
    end
       
    properties (GetAccess = protected)
%         isSigned    % True for representations that are multi-channel 
                    % waveforms (e.g., a filterbank output) as opposed to
                    % spectrograms. Used for plotting only.
    end
    
    methods 
        function sObj = TimeFrequencySignal(fs,name,cfHz,label,data,canal)
            %TimeFrequencySignal    Constructor for the "time-frequency
            %                       representation" children signal class
            %
            %USAGE 
            %     sObj = TimeFrequencySignal(fs,name)
            %     sObj = TimeFrequencySignal(fs,name,cfHz,label,data,canal)
            %
            %INPUT ARGUMENTS
            %       fs : Sampling frequency (Hz)
            %     name : Name tag of the signal, should be compatible with
            %            variable name syntax.
            %     cfHz : Center frequencies of the channels in Hertz.
            %    label : Label for the signal, to be used in e.g. figures
            %            (default: label = name)
            %     data : Data matrix to construct an object from existing 
            %            data. Time should span lines and frequency spans
            %            columns.
            %    canal : Flag indicating 'left', 'right', or 'mono'
            %            (default: canal = 'mono')
            %OUTPUT ARGUMENT
            %     sObj : Time-frequency representation signal object 
            %            inheriting the signal class
             
            if nargin>0     % Safeguard for Matlab empty calls
            
            % Check input arguments
            if nargin<2||isempty(name)
                name = 'tfRepresentation';
                warning(['A name tag should be assigned to the signal. '...
                    'The name %s was chosen by default'],name)
            end
            if nargin<6; canal = 'mono'; end
            if nargin<5||isempty(data); data = []; end
            if nargin<4||isempty(label)
                label = name;
            end
            if nargin<3||isempty(cfHz); cfHz = []; end
            if nargin<1||isempty(fs)
%                 error('The sampling frequency needs to be provided')
                fs = [];
            end
            
            % N.B: We are not checking the dimensionality of the provided
            % data and leave this to the user's responsibility. Assuming
            % for example that there should be more frequency bins than
            % time samples might not be compatible with processing in short
            % time chunks.
            
            % Populate object properties
            populateProperties(sObj,'Label',label,'Name',name,...
                'Dimensions','nSamples x nFilters','FsHz',fs);
            sObj.cfHz = cfHz;
            sObj.Data = data;
            sObj.Canal = canal;
            
            end
            
        end
        
        function h = plot(sObj,h0)
            % TO DO: h1 line
            
            % Decide if the plot should be on a linear or dB scale
            switch sObj.Name
                case {'gammatone','ild','ic_xcorr','itd_xcorr'}
                    do_dB = 0;
                case {'innerhaircell','ratemap_magnitude','ratemap_power'}
                    do_dB = 1;
                otherwise 
                    warning('Cannot plot this object')
            end
            
            if ~isempty(sObj.Data)
            
                % Get plotting parameters
                p = getDefaultParameters([],'plotting');

                if do_dB
                    % Get the data in dB
                    data = 20*log10(abs(sObj.Data.'));
                else
                    % Keep linear amplitude
                    data = sObj.Data.';
                end

                % Get a time vector
                t = 0:1/sObj.FsHz:(size(data,2)-1)/sObj.FsHz;

                h = figure;             % Generate a new figure


                % Managing frequency axis ticks for auditory filterbank
                %
                % Find position of y-axis ticks
                M = size(sObj.cfHz,2);  % Number of channels
                n_points = 500;         % Number of points in the interpolation
                interpolate_ticks = spline(1:M,sObj.cfHz,...
                    linspace(0.5,M+0.5,n_points));
                %
                % Restrain ticks to signal range (+/- a half channel)
                aud_ticks = p.aud_ticks;
                aud_ticks=aud_ticks(aud_ticks<=interpolate_ticks(end));
                aud_ticks=aud_ticks(aud_ticks>=interpolate_ticks(1));
                n_ticks = size(aud_ticks,2);        % Number of ticks
                ticks_pos = zeros(size(aud_ticks)); % Tick position
                %
                % Find index for each tick
                for ii = 1:n_ticks
                    jj = find(interpolate_ticks>=aud_ticks(ii),1);
                    ticks_pos(ii) = jj*M/n_points;
                end

                % Plot the figure
                imagesc(t,1:M,data)  % Plot the data
                axis xy                 % Use Cartesian coordinates
                colorbar                % Display a colorbar

                % Set up a title
                if ~strcmp(sObj.Canal,'mono')
                    pTitle = [sObj.Label ' - ' sObj.Canal];
                else
                    pTitle = sObj.Label;
                end
                
                % Set up axes labels
                xlabel('Time (s)','fontsize',p.fsize_label,'fontname',p.ftype)
                ylabel('Frequency (Hz)','fontsize',p.fsize_label,'fontname',p.ftype)
                title(pTitle,'fontsize',p.fsize_title,'fontname',p.ftype)

                % Set up plot properties
                set(gca,'YTick',ticks_pos,...
                    'YTickLabel',aud_ticks,'fontsize',p.fsize_axes,...
                    'fontname',p.ftype)

                % Scaling the plot
                switch sObj.Name
                    case {'innerhaircell','ratemap_magnitude','ratemap_power'}
                        m = max(data(:));    % Get maximum value for scaling
                        set(gca,'CLim',[m-p.dynrange m])

                    case {'gammatone','ild','itc_xcorr'}
                        m = max(abs(data(:)))+eps;
                        set(gca,'CLim',[-m m])

                    case 'ic_xcorr'
                        set(gca,'CLim',[0 1])

                end
            else
                warning('This is an empty signal, cannot be plotted')
            end
                
            
        end
    end
end