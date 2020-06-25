function rsvmTarget = ck_RVMlearnLikelihood(qid, map_aff, sz_T, aff_samples, n_sample, eta_1)

%% value
szFILE_TrainDAT = '.\svm\train.txt';
szTrainDAT = '';

szFILE_ModelDAT = '.\svm\model.txt';


%% function
fprintf('[cksong] prepare training set\n');

% calculate overlapping area between samples and the initial template (1/2)
template_rect = round(aff2image(map_aff', sz_T));
template_area = polyarea(   [template_rect(1),template_rect(3),template_rect(7),template_rect(5),template_rect(1)], ...
                            [template_rect(2),template_rect(4),template_rect(8),template_rect(6),template_rect(2)]      );
%~calculate overlapping area between samples and the initial template (1/2)

rsvmTarget = zeros(1,n_sample);
for i=1:n_sample

    % calculate overlapping area between samples and the initial template(2/2)
    sample_rect= aff2image(aff_samples(i,1:6)', sz_T);

    template_x = [ template_rect(1) , template_rect(3), template_rect(7), template_rect(5), template_rect(1) ];
    template_y = [ template_rect(2) , template_rect(4), template_rect(8), template_rect(6), template_rect(2) ];

    sample_x = [ sample_rect(1) , sample_rect(3), sample_rect(7), sample_rect(5), sample_rect(1) ];
    sample_y = [ sample_rect(2) , sample_rect(4), sample_rect(8), sample_rect(6),sample_rect(2) ];

    [x1,y1] = poly2cw(template_x, template_y);
    [x2,y2] = poly2cw(sample_x, sample_y);
    [overlap_xa, overlap_ya] = polybool('intersection', x1,y1, x2,y2 );
    overlap_area = polyarea(overlap_xa,overlap_ya);            
    %~calculate overlapping area between samples and the initial
    %template(2/2)

    rsvmTarget(i) = ceil( 100 * (overlap_area / template_area) );

    rsvmQID = 1;%qid;
    rsvmValue1 = eta_1(i);

    if( rsvmTarget(i) > 0 )
        szTrainDAT = strcat( szTrainDAT, sprintf( '%d qid:%d 1:%f', rsvmTarget(i),rsvmQID,rsvmValue1 ), '\r\n' );
    end

end

fTrainDAT = fopen( szFILE_TrainDAT, 'w' );
fprintf(fTrainDAT,szTrainDAT);
fclose(fTrainDAT);

% for windows
mexSVMrank_learn( sprintf('svm_rank_learn -c 3 %s %s ',szFILE_TrainDAT,szFILE_ModelDAT) );
% for linux
$ Execute( sprintf('svm_rank_learn -c 3 %s %s ',szFILE_TrainDAT,szFILE_ModelDAT) );

fprintf('[cksong]~prepare training set\n');