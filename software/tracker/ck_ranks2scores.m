function scores = ck_ranks2scores( rankings, indexes )

alpha = 30;

n_rankings = size( rankings, 1 );
scores     = zeros( n_rankings, 1 );

min_ranking = min(rankings(indexes));
max_ranking = max(rankings(indexes));

scores(indexes) = exp(    -alpha ...
                                * (rankings(indexes) - min_ranking) ...
                                / (max_ranking - min_ranking) ...
                            );
scores = scores / sum(scores);