%% Enter inputs

% Select file path to the image volume
im_path = "/Users/kellyclingo/Library/CloudStorage/OneDrive-JohnsHopkins/MLSP/Results/Final/Test_Images/eye_5.tiff";
% Select the ID you would like to give to your image volume (e.g., "Eye_1")
img_id = "Test_Images_eye_5";
num_slices = 24;

% Select Save File Location/Name
results_folder = "./Results/";
savefile = results_folder+img_id+".mat";

% If you want the polynomial order to be low enough to smooth the BM
% and CS when curve fitting the predicted markings, set to true. If
% not, set to false.
low_poly = true;

% If the image hasn't already undergone guided image filtering and had the icon zeroed out,
% set to true.  If it has, set to false.  Note: CLAHE-Gamma correction
% should have already been performed in Fiji.
filter = true;

% Adjust size of markings
markersize = 5;
%% Load models
savenet = "most_updated_model.mat";
variables = {"net1","net2_after"};
load(savenet,variables{:})
net2 = net2_after;
net2_before = net2;
current_img = results_folder+"current_img.png";
current_mask = results_folder+"current_mask.png";
classes = [
    "bruch_op"
    "bruch_mem"
    "chor_scl"
    "ant_lam_lim"
    "other"];
labelIDs = [1,2,3,4,0];

for j = 1:num_slices
    clear roi
    % Read image as one-channel image
    I = imread(im_path,j);
    I = I(:,:,1);
    original_image{j} = I;
    if filter == true
        % Zero out the little icon in the bottom left and filter image
        I(434:end,1:60) = 0;
        I = imguidedfilter(I);
    end
    [nrows,ncols] = size(I);

    % Predict segmentation using each model
    [C1,score1,allScores1] = semanticseg(I,net1);
    [C2,score2,allScores2] = semanticseg(I,net2);
    % Average probabilities of each pixel being assigned to each label
    % between models
    allScores = (allScores1+allScores2)./2;
    % Assign label with maximum average probability to each pixel
    [~,C] = max(allScores,[],3);

    % Convert from mask to label coordinates and differentiate between
    % left and right BM and CS
    center = floor(ncols/2)+1;
    for i = 1:numel(classes)-1
        weight_mat = allScores(:,:,labelIDs(i));
        D = zeros(nrows,ncols);
        D(C==labelIDs(i)) = weight_mat(C==labelIDs(i));
        [Wmax,row] = max(D);
        col = any(D);
        col = find(col);
        row = row(col);
        Wmax = Wmax(col);
        if i<4
            if i==1
                [row,col] = find(C(:,1:center-1)==labelIDs(i));
                ind = sub2ind(size(weight_mat),row,col);
                weight = weight_mat(ind);
                mark_labels_seg_test.(classes(i)+"_left") = [col,row,weight];
                [row,col] = find(C(:,center+1:end)==labelIDs(i));
                ind = sub2ind(size(weight_mat),row,col+center);
                weight = weight_mat(ind);
                mark_labels_seg_test.(classes(i)+"_right") = [col+center,row,weight];
            else
                colL = col(col<center);
                rowL = row(col<center);
                weightL = Wmax(col<center);
                mark_labels_seg_test.(classes(i)+"_left") = [colL.',rowL.',weightL.'];
                colR = col(col>center);
                rowR = row(col>center);
                weightR = Wmax(col>center);
                mark_labels_seg_test.(classes(i)+"_right") = [colR.',rowR.',weightR.'];
            end
        else
            mark_labels_seg_test.(classes(i)) = [col.',row.',Wmax.'];
        end
    end

    % Find BMOL and BMOR by finding location with highest confidence
    BMOL = mark_labels_seg_test.bruch_op_left;
    BMOR = mark_labels_seg_test.bruch_op_right;
    [~,ind] = max(BMOL(:,3));
    BMOL = BMOL(ind,1:2);
    BMOL = mean(BMOL,1);
    [~,ind] = max(BMOR(:,3));
    BMOR = BMOR(ind,1:2);
    BMOR = mean(BMOR,1);

    % Allow the user to correct the BMO markings first
    figure
    imshow(I)
    roi.BMO{1} = images.roi.Point(gca,'Position',[BMOL(1) BMOL(2)],'Color','red','MarkerSize',markersize);
    roi.BMO{2} = images.roi.Point(gca,'Position',[BMOR(1) BMOR(2)],'Color','red','MarkerSize',markersize);

    disp("Press any key to continue after correcting BMO markings.")
    pause

    BMOL = roi.BMO{1}.Position;
    BMOR = roi.BMO{2}.Position;
    close all

    % Set the weights of the BMO locations to 1 for 100% confidence
    mark_labels_seg_test.bruch_op_left = [BMOL,1];
    mark_labels_seg_test.bruch_op_right = [BMOR,1];

    % Determine marking locations for top boundaries (not for training)
    if j==1
        G = I;
    end
    I2 = imguidedfilter(I,G);
    top_edge = top_boundary_marking(I,BMOL,BMOR);

    % Fit curves to predicted markings and corrected BMO
    alg_line = linefind_v2(mark_labels_seg_test,ncols,low_poly);

    % Create mask of curve-fit predicted markings, excluding markings
    % outside of image dimensions
    mask = zeros(nrows,ncols);
    fields = fieldnames(alg_line);
    fieldIDs = [1,1,2,2,3,3,4];
    for k = 1:numel(fields)
        for l = 1:length(alg_line.(fields{k})(:,1))
            idx = alg_line.(fields{k})(l,:);
            idx = round(idx);
            if idx(1)>0 && idx(1)<=ncols && idx(2)>0 && idx(2)<=nrows
                mask(idx(2),idx(1)) = fieldIDs(k);
            end
        end
    end

    % Display image with movable markings
    figure
    imshow(I);
    [row,col] = find(mask==1);
    for i = 1:length(row)
        roi.BMO{i} = images.roi.Point(gca,'Position',[col(i) row(i)],'Color','red','MarkerSize',markersize);
    end
    [row,col] = find(mask==2);
    for i = 1:length(row)
        roi.BM{i} = images.roi.Point(gca,'Position',[col(i) row(i)],'Color','blue','MarkerSize',markersize);
    end
    [row,col] = find(mask==3);
    for i = 1:length(row)
        roi.CS{i} = images.roi.Point(gca,'Position',[col(i) row(i)],'Color','green','MarkerSize',markersize);
    end
    [row,col] = find(mask==4);
    for i = 1:length(row)
        roi.ALC{i} = images.roi.Point(gca,'Position',[col(i) row(i)],'Color','magenta','MarkerSize',markersize);
    end
    for i = 1:length(top_edge(:,1))
        roi.TE{i} = images.roi.Point(gca,'Position',[top_edge(i,1) top_edge(i,2)],'Color','yellow','MarkerSize',markersize);
    end

    disp("Press any key to continue after correcting markings.")
    pause

     %%
        F = getframe;
        if j==1
            imwrite(uint8(F.cdata),char(results_folder+"Corrected Markings\"+img_id+".tiff"))
        else
            imwrite(uint8(F.cdata),char(results_folder+"Corrected Markings\"+img_id+".tiff"),"WriteMode","append")
        end
        %%

    % Save new marking coordinates
    for i = 1:length(roi.BMO)
        BMO(i,:) = roi.BMO{i}.Position;
    end
    for i = 1:length(roi.BM)
        BM(i,:) = roi.BM{i}.Position;
    end
    for i = 1:length(roi.CS)
        CS(i,:) = roi.CS{i}.Position;
    end
    for i = 1:length(roi.ALC)
        ALC(i,:) = roi.ALC{i}.Position;
    end
    for i = 1:length(roi.TE)
        TE(i,:) = roi.TE{i}.Position;
    end

    % Divide BM and CS into left and right
    L = find(BM(:,1)<center);
    R = find(BM(:,1)>center);
    BML = BM(L,:);
    BMR = BM(R,:);
    L = find(CS(:,1)<center);
    R = find(CS(:,1)>center);
    CSL = CS(L,:);
    CSR = CS(R,:);

    %Create mask with linear interpolations between markings of each tissue
    corr_mask = boundary_marking(I,BMO,BML,BMR,ALC,CSL,CSR);

    % Save markings in cell array of structs
    markings{j}.BMO = BMO;
    markings{j}.BML = BML;
    markings{j}.BMR = BMR;
    markings{j}.CSL = CSL;
    markings{j}.CSR = CSR;
    markings{j}.ALC = ALC;
    markings{j}.top_edge = TE;
    masks{j} = corr_mask;
    filtered_image{j} = I;

    % Convert grayscale input image into RGB for use with network, which
    % requires RGB image input.
    I = repmat(I,1,1,3);

    % Data Augmentation
    imwrite(I,current_img)
    imwrite(corr_mask,current_mask)
    pxds = pixelLabelDatastore(current_mask,classes,labelIDs);
    imds = imageDatastore(current_img);
    dsTrain = combine(imds, pxds);
    xTrans = [-10 10];
    yTrans = [-10 10];
    dsTrain = transform(dsTrain, @(data)augmentImageAndLabel(data,xTrans,yTrans));

    % Define training options.
    options = trainingOptions('sgdm', ...
        'LearnRateSchedule','piecewise',...
        'LearnRateDropPeriod',10,...
        'LearnRateDropFactor',0.3,...
        'Momentum',0.9, ...
        'InitialLearnRate',1e-4, ...
        'L2Regularization',0.005, ...
        'MaxEpochs',1, ...
        'MiniBatchSize',1, ...
        'Shuffle','every-epoch', ...
        'CheckpointPath', tempdir, ...
        'VerboseFrequency',1,...
        'Plots','none');
    % Continue training net2
    [net2, info] = trainNetwork(dsTrain,layerGraph(net2),options);
    close all
end

% Save variables
net2_after = net2;
save(savefile, "markings", "masks", "im_path", "savenet", "filtered_image", "net1", "net2_before", "net2_after","original_image")
save(savenet, "net1", "net2_before", "net2_after")

function data = augmentImageAndLabel(data, xTrans, yTrans)
% Augment images and pixel label images using random reflection and
% translation.

for i = 1:size(data,1)

    tform = randomAffine2d(...
        'XReflection',true,...
        'XTranslation', xTrans, ...
        'YTranslation', yTrans);

    % Center the view at the center of image in the output space while
    % allowing translation to move the output image out of view.
    rout = affineOutputView(size(data{i,1}), tform, 'BoundsStyle', 'centerOutput');

    % Warp the image and pixel labels using the same transform.
    data{i,1} = imwarp(data{i,1}, tform, 'OutputView', rout);
    data{i,2} = imwarp(data{i,2}, tform, 'OutputView', rout);

end
end