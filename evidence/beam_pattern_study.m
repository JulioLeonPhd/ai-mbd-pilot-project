% Ideal azimuth array-factor study for a 16x4 half-wavelength planar array.
% At zero elevation, the four vertical elements have a common factor;
% this study plots the azimuth response of the 16 horizontal elements.
% Azimuth is measured from broadside, with 0 deg elevation in the horizontal
% plane. Elements are isotropic and uncoupled; no element pattern is modeled.
thetaDeg = -90:0.01:90;
steerDeg = [0 45 60];
elementIndex = (0:15).';
weightSets = [ones(16,1), 0.54 - 0.46*cos(2*pi*elementIndex/15)];
weightNames = {'Uniform', 'Hamming'};

fig = figure('Visible','off','Color','white','Position',[100 100 1100 480]);
tiles = tiledlayout(fig,1,2,'Padding','compact','TileSpacing','compact');
for weightIndex = 1:2
    ax = nexttile(tiles);
    ax.Color = 'white';
    ax.XColor = 'black';
    ax.YColor = 'black';
    ax.GridColor = [0.75 0.75 0.75];
    hold(ax,'on');
    weights = weightSets(:,weightIndex);
    for steerIndex = 1:numel(steerDeg)
        steer = steerDeg(steerIndex);
        response = abs(weights.' * exp(1j*pi*elementIndex * ...
            (sind(thetaDeg)-sind(steer))));
        responseDb = 20*log10(max(response/max(response),1e-4));
        plot(ax,thetaDeg,responseDb,'LineWidth',1.7, ...
            'DisplayName',sprintf('Steer %+d deg',steer));

        [~,peakIndex] = min(abs(thetaDeg-steer));
        above3dB = responseDb >= -3;
        leftIndex = find(~above3dB(1:peakIndex),1,'last');
        rightOffset = find(~above3dB(peakIndex:end),1,'first');
        if isempty(leftIndex) || isempty(rightOffset)
            fprintf('%s steer %+d deg: 3-dB width extends beyond +/-90 deg\n', ...
                weightNames{weightIndex},steer);
        else
            rightIndex = peakIndex+rightOffset-1;
            fprintf('%s steer %+d deg: approximate 3-dB width %.2f deg\n', ...
                weightNames{weightIndex},steer, ...
                thetaDeg(rightIndex)-thetaDeg(leftIndex));
        end
    end
    lgd = legend(ax,'show','Location','southoutside','Orientation','horizontal', ...
        'AutoUpdate','off');
    lgd.Color = 'white';
    lgd.TextColor = 'black';
    xline(ax,-45,':k');
    xline(ax,45,':k');
    hold(ax,'off');
    xlim(ax,[-90 90]);
    ylim(ax,[-40 1]);
    grid(ax,'on');
    xlabel(ax,'Azimuth (deg)');
    ylabel(ax,'Normalized array gain (dB)');
    heading = title(ax,sprintf('%s weights, 16 horizontal elements',weightNames{weightIndex}));
    heading.Color = 'black';
end
heading = title(tiles,'Ideal 16x4 half-wavelength array: azimuth cut at 0 deg elevation');
heading.Color = 'black';
exportgraphics(fig,fullfile(fileparts(mfilename('fullpath')), ...
    'beam-pattern-study.png'),'Resolution',180);
close(fig);
