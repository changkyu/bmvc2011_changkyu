function prediction = ck_RVMclassifyLikelihood(values)
%% value

%szFILE_ModelDAT =   '.\svm\model_art.txt';
%szFILE_ModelDAT =   '.\svm\bak\3rank\model_all_likelihood_3rank.txt';
szFILE_ModelDAT =   '.\svm\bak\3rank\model_all_dist_sq_3rank.txt';
%szFILE_ModelDAT =   '.\svm\bak\3rank\model_3_4_dist_sq_3rank.txt';
%szFILE_ModelDAT =   '.\svm\bak\3rank\model_2_4_dist_sq_3rank.txt';
szFILE_TestDAT =    '.\svm\test.txt';
szFILE_PredicDAT =  '.\svm\predictions.txt';
szTestDAT = '';

%% function

cnt_set    = size(values,1);
cnt_values = size(values,2);

values_sort = values;
% for s=1:cnt_set
%     values_sort(s,:) = sortrows( values(s,:)',1 )';
% end

for idx_s=1:cnt_set
    szTestDAT = strcat(szTestDAT,'0 qid:1');
    for idx_v=1:cnt_values
        szTestDAT = strcat( szTestDAT,sprintf(' %d:%f',idx_v,values_sort(idx_s,idx_v)) );    
    end
    szTestDAT = strcat(szTestDAT,'\r\n');
end
    
fTestDAT = fopen( szFILE_TestDAT , 'w' );
fprintf(fTestDAT,szTestDAT);
fclose(fTestDAT);

% for windows
% mexSVMrank_classify( sprintf('svm_classify %s %s %s ',szFILE_TestDAT,szFILE_ModelDAT,szFILE_PredicDAT) );
expression = ['!','svm\svm_rank_classify.exe',' ',szFILE_TestDAT,' ',szFILE_ModelDAT,' ',szFILE_PredicDAT,' '];
eval(expression);
% for linux
% Execute( sprintf('svm_rank_classify %s %s %s ',szFILE_TestDAT,szFILE_ModelDAT,szFILE_PredicDAT) );

fPredDAT = fopen( szFILE_PredicDAT );
ret_pred = textscan( fPredDAT, '%f\r\n', cnt_set );
fclose( fPredDAT );

prediction = ret_pred{1};