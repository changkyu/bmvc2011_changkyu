function ratio = IntersectionAreaRatio( map_aff, sz_T, aff_samples )

n_sample = size(aff_samples,1);

%% function

% calculate overlapping area between samples and the initial template (1/2)
template_rect = aff2image(map_aff', sz_T);
template_area = polyarea(   [template_rect(1),template_rect(3),template_rect(7),template_rect(5),template_rect(1)], ...
                            [template_rect(2),template_rect(4),template_rect(8),template_rect(6),template_rect(2)]      );
%~calculate overlapping area between samples and the initial template (1/2)

ratio = zeros(n_sample,1);

for i=1:n_sample
    % calculate overlapping area between samples and the initial template(2/2)
    sample_rect = aff2image(aff_samples(i,1:6)', sz_T);
    sample_area = polyarea(  [sample_rect(1),sample_rect(3),sample_rect(7),sample_rect(5),sample_rect(1)], ...
                             [sample_rect(2),sample_rect(4),sample_rect(8),sample_rect(6),sample_rect(2)]       );               

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

    ratio(i) = (overlap_area / (template_area+sample_area)) * 2;
end

