%% load one example dataset
clear all
load 10

%% parse responses to different image sets

%*** pre-processing: shift by 50ms to account for response latency
latency=50;
tmp = resp_train;
tmp(:,:,:,1:end-latency) = resp_train(:,:,:,latency+1:end);
tmp(:,:,:,end-latency+1:end) = resp_train_blk(:,:,:,1:latency);
resp_train = tmp;

%*** compute spike count per stimulus presentation
resp = nansum(resp_train,4); % [#neurons #stimuli #repeats]
reps = 20; %number of repeats

%*** create separate variables to store responses to different image subsets
clear resp_nat  resp_sf  resp_ori resp_as
tmp = squeeze(resp(:,1:(2*9*30),:));
tmp = reshape(tmp,size(tmp,1),2,9,30,reps);
resp_nat(:,1,:,:,:) = tmp(:,1,:,:,:); % small natural images
resp_nat(:,2,:,:,:) = tmp(:,2,:,:,:); % large natural images
% Note: there are 9 categories x 30 instances
% the categories include (in this order):
% - strong orientation content, mainly 0, 45, 90 or 135 degrees
% - weak orientation content, mainly 0, 45, 90 or 135 degrees
% - no dominant orientation

tmp = squeeze(resp(:,[1:128]+(2*9*30),:)); % gratings for spatial frequency tuning
resp_sf = reshape(tmp,size(tmp,1),4,4,8,reps); % [#neurons #phases #orientations #s.f. #repeats]

tmp = squeeze(resp(:,[1:64]+(128+2*9*30),:)); % gratings for orientation tuning
resp_ori = reshape(tmp,size(tmp,1),4,16,reps); % [#neurons #phases #orientations #repeats]

tmp = squeeze(resp(:,[1:224]+(64+128+2*9*30),:)); % gratings for size tuning
resp_as = reshape(tmp,size(tmp,1),4,2,7,4,reps); % [#neurons #phases #categories #sizes #orientations #repeats]
% Note: 2 categories, 1=circular patch (donut hole), 2=annular patch (donut).

%% Example: surround suppression strength across natural images

%*** select well-centered neurons
ineu = find(INDCENT);

%*** compute surround suppression index, for all images
SI = squeeze(nanmean(resp_nat(ineu,2,:,:,:),5) ./ nanmean(resp_nat(ineu,1,:,:,:),5));
SI = SI(:,:);
%*** compute surround suppression index, for homogeneous images only and heterogeneous images only
SIhom = NaN(size(SI));
SIhet = NaN(size(SI));
for i=1:size(SIhom,1)
    indsmall = P_HOMOG(ineu(i),1:2:540)<.25; %small heterogeneous images
    indlarge = P_HOMOG(ineu(i),2:2:540)>=.5; %large homogeneous images
    SIhom(i,indsmall & indlarge) = SI(i,indsmall & indlarge);
    SIhet(i,indsmall & ~indlarge) = SI(i,indsmall & ~indlarge);
end

%*** plot average suppression index for homogeneous vs heterogeneous images, per neuron
SIhet(~isfinite(SIhet)|(SIhet==0)) = NaN;
SIhom(~isfinite(SIhom)|(SIhom==0)) = NaN;
figure; hold on
plot([-2 2],[-2 2],':k','LineWidth',2);
tmphet = nanmean(log10(SIhet),2);
tmphom = nanmean(log10(SIhom),2);
plot(tmphom,tmphet,'o')
set(gca,'Xlim',[-1 .5],'Ylim',[-1 .5]);


%% Example: plot tuning of one neuron to grating sets

%*** select a well-centered neuron
ineu = find(INDCENT);
ineu = ineu(2);

%*** Spatial Frequency tuning at preferred ori
xsf = 2.^[-2:.7:3.5]; %cycles/deg
tmp=squeeze(nanmean(resp_sf,5)); %trials
tmp=squeeze(nanmean(tmp,2)); %phases
[m ind] = nanmax(nanmax(tmp,[],3),[],2); % find preferred orientation
Y = squeeze(tmp(ineu,ind(ineu),:));
figure;
plot(xsf,Y,'-o')
xlabel('Spatial frequency (cycles/degree)')
ylabel('Mean spike count')

%*** Orientation tuning
xori = [90:-11.25:-78.75];
tmp=squeeze(nanmean(resp_ori,4)); %trials
tmp=squeeze(nanmean(tmp,2)); %phases
Y = squeeze(tmp(ineu,:));
figure
plot(xori,Y,'-o')
xlabel('Orientation')
ylabel('Mean spike count')


%*** Size tuning at preferred ori
xas = round(2.^[-1.56:.7:2.64] * 48);
tmp=squeeze(nanmean(resp_as,6)); %trials
tmp=squeeze(nanmean(tmp,2)); %phases
tmp=squeeze(tmp(:,1,:,:)); %remove annulus
[m ind] = nanmax(nanmax(tmp,[],2),[],3); % find preferred orientation
Y = squeeze(tmp(ineu,:,ind(ineu)));
figure
plot(xas,Y,'-o')
xlabel('Radius (pixels)')
ylabel('Mean spike count')

