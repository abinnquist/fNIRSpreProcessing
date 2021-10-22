clear

%% Set parameters for running here
labelPlots = 0; % Set to 0 to remove channel labels (1-108) on graphs
specificChannel = 0; % Set to 0 for all channels, 1-108 for specific channel

%% Main Code Body
% Select data to plot (Presumed to be 108 channel data)
[filename,filepath] = uigetfile('*.mat','Choose BEFORE PREPROC fNIRS .mat data File');
beforePre = load(fullfile(filepath,filename));

[filename,filepath] = uigetfile('*.mat','Choose AFTER PREPROC fNIRS .mat data File');
afterPre = load(fullfile(filepath,filename));

for looper = 1:2

    if looper == 1
        oxy = beforePre.oxy;
        figureName = 'Current Pipeline';
    elseif looper==2
        oxy = afterPre.oxy;
        figureName = 'Kurtosis Wavelet (3.2)';
    end
    
    numChannels = size(oxy,2);
    timepoints = size(oxy,1);

    if specificChannel == 0
        figure('Name',figureName)
        ha = tight_subplot(numChannels/6,6,[.001 .01],[.01 .01],[.01 .01]);
        for channel = 1:numChannels
            %subplot(numChannels/4,4,channel)
            curData = oxy(:,channel);
            axes(ha(channel))
            plot(oxy(:,channel), 'LineWidth',1)
            h = gca;
            axis on
            yl = ylabel(num2str(channel));
            if labelPlots == 0
                h.YLabel.Visible = 'off';
            end
            set(h,'YTickLabel',[]);
            h.XLabel.Visible = 'off';
            set(h,'XTickLabel',[]);
            xlim([0 timepoints])
        end
    else
        figure('Name',figureName)
        plot(oxy(:,specificChannel), 'LineWidth',1)
        title(['Channel ' num2str(specificChannel)])
        ylabel('Oxy')
        xlabel('Time')
    end
    % h = gca;
    % h.XAxis.Visible = 'on';
    % xlabel('Time')
end
