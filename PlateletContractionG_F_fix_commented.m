function PlateletContractionG_F_fix(CONVFACTOR)

% Code takes an image or series of images, prompts user to choose post
% pairs to analyze (both contracting platelet and reference), and outputs
% the pinch distance to be used in calculating force.

% Inputs:
    % CONVFACTOR = conversion factor (type double, in x units/pixel format)

% Outputs:
    % Excel file containing pinch distance (units).

% Prompt user to choose whether they want to analyze one image or a folder
% of images.
FILETYPE = input('Choose ''1'' to analyze one image, choose ''2'' to analyze a folder of images.');

% If the user wants to analyze a single image:
if FILETYPE == 1
    % Prompt user to choose an image.
    LIST = uigetfile;
    % Create naming convention for excel file (names after image or folder of images analyzed).
    NAMING = ['ContractionData_' LIST(1:(end-4)) '.xlsx'];
end

% If the user wants to analyze a folder of images:
if FILETYPE == 2
    % Promput user to choose a folder.
    FOLDER = uigetdir;
    % Change directory to that folder.
    cd(FOLDER)
    % Create a list of all of the file names within that folder.
    LIST = ls('*.png');
    % Create naming convention for excel file (named after folder.)
    NAME = [];
    for x = 1:length(FOLDER)
        if FOLDER(x) == '\'
            NAME = [];
        else
            NAME = [NAME FOLDER(x)];
        end
    end

    NAMING = ['ContractionData_' NAME '.xlsx'];
end

% Code to set threshold - moved before choosing number of regions to
% analyze from previous versions
if FILETYPE == 1 % If it's a single image, show  that image.
        H_BW_CHECK = imread(LIST(1, :));
elseif FILETYPE == 2 % If it's a folder, show the last image.
        H_BW_CHECK = imread(LIST(end, :)); 
end

% Show image
figure; imshow(H_BW_CHECK(:, :, :))

% Promput user to indicate if they'd like to analyze for P-selectin.
COLORSELECT = input('Would you like to analyze for a marker (blue)? Choose 0 if no, 1 if yes.');

OKAY = 0; % Initialize
% Section: set threshold - while loop
while OKAY == 0

% GREEN-POSTS
    % Prompt user to choose a value to try:
    TRY_G = input('Input a GREEN threshold value to try (between 0 and 1)');
    % Apply that threshold (and a filter) to the first image - GREEN LAYER.
    H_TRY_G = im2bw(H_BW_CHECK(:,:,2), TRY_G);
    H_TRY_G = medfilt2(H_TRY_G,[3 3]);
    % Show the image.
    imshow(H_TRY_G)
    % Is the image ok?
    OKAY = input('Is the image ok - GREEN? Select 0 for ''no'', 1 for ''yes''.');

    % If it's good, set the threshold and move on. If not, try
    % again.
    if OKAY == 1
        THRESHOLD_G = TRY_G;
    end
end


% BLUE-MARKER
if COLORSELECT == 1
    OKAY = 0; % Initialize
    % Section: set threshold - while loop
    while OKAY == 0

        % Prompt user to choose a value to try:
        TRY_B = input('Input a BLUE threshold value to try (between 0 and 1)');
        % Apply that threshold (and a filter) to the first image - GREEN LAYER.
        H_TRY_B = im2bw(H_BW_CHECK(:,:,3), TRY_B);
        H_TRY_B = medfilt2(H_TRY_B,[3 3]);
        % Show the image.
        WHITE = uint8(H_TRY_B .* 255);
        WHITE = cat(3, WHITE, WHITE, WHITE);
        H_TRY_B = WHITE + H_BW_CHECK;
        imshow(H_TRY_B)
        % Is the image ok?
        OKAY = input('Is the image ok - BLUE? Select 0 for ''no'', 1 for ''yes''.');

        % If it's good, set the threshold and move on. If not, try
        % again.
        if OKAY == 1
            THRESHOLD_B = TRY_B;
        end
    end
end


% Prompt user to input how many contracting platelet regions to analyze.
NUMPLATELET = input('How many contracting platelets do you want to analyze? (num)');

% Prompt user to input how many reference regions to analyze.
NUMREFERENCE = input('How many reference areas do you want to analyze? (num)');

% Determine how many images there are - for for loop.
[NUMIMAGES, ~] = size(LIST);

% Set up array for storing platelet contraction data.
PLATELETDATA = [{'Area Number'} {'Image Number'} {'Post-Post Distance (um)'}...
    {'Post 1 Area (um^2)'} {'Post 1 Coordinate - R (pixel)'} {'Post 2 Coordinate - C (pixel)'}...
    {'Post 2 Area (um^2)'} {'Post 2 Coordinate - R (pixel)'} {'Post 2 Coordinate - C (pixel)'}];

% If the user to also analyzing for P-selectin, create additional array
% slots.
if COLORSELECT == 1
    PLATELETDATA = [PLATELETDATA, {'P-selectin area (pixel)'} {'P-selectin area (um)'} {'Total Intensity of P-selectin (uint8)'} {'P-selectin average intensity (uint8/pixel)'}...
        {'P-selectin average intensity (uint8/um)'}];
end

% Set up a save array for ROIs.
EACHROI = [];
IMPORTANTCENTROID = [];
% For each platelet contraction area - for loop.
for A = 1:NUMPLATELET
            
    % For each image given - for loop.
    for B = 1:NUMIMAGES
        
        % Read image.
        H = imread(LIST(B, :));
        
        % For first image - steps to choose a threshold/region of interest from the
        % image.
        if B == 1
            
            % Prompts user to choose a region of interest from the image.
            % If it's a single image, choose from the first image. If it's
            % a folder, choose from the last.
            if FILETYPE == 1
                imshow(H)
            elseif FILETYPE == 2
                imshow(imread(LIST(NUMIMAGES, :)));
            end
            ROI = imrect;

            % Return coordinates from the region of interest.
            % OUTPUTS: 1 x 4 array - [xmin ymin width height]
            pos = getPosition(ROI); 
            Y1 = pos(2); % Y min
            Y2 = Y1 + pos(4); % Y max
            X1 = pos(1); % X min
            X2 = X1 + pos(3); % X max
            
            % Save coordinates to ROI save matrix
            LINEROI{1, 1} = ['Contracting Platelet' num2str(A)];
            LINEROI{1, 2} = X1; LINEROI{1, 3} = X2; LINEROI{1, 4} = Y1; LINEROI{1, 5} = Y2;
            EACHROI = [EACHROI; LINEROI];
        end

        % Crop image to the chosen region of interest
        HROI = H(round(Y1):round(Y2), round(X1):round(X2), :); 

        % Take out individual frames from the image. Remember, green = posts, red =
        % platelets, blue = p-selectin.
        HROI_G = HROI(:, :, 2); % POST ARRAY
        HROI_B = HROI(:, :, 3); % P-SELECTIN
        
        % Convert to B/W using a threshold (second input.)
        HG = im2bw(HROI_G, THRESHOLD_G);
        HG = medfilt2(HG,[3 3]);
       
        % Perform blob analysis
        RLL = bwlabel(HG, 4); % Finds blobs.
        STATS = regionprops(RLL,'Area','Centroid'); % Computes properties of blobs.
        
        % Determine how many blobs are found.
        [RSTATS ~] = size(STATS);
        
        % If the blob analysis finds more than 2 blobs (noise), choose the
        % largest two (posts.)
        AREAVEC = [];
        for Q = 1:RSTATS
            AREAVEC = [AREAVEC STATS(Q).Area];   
        end

        SORTED = sort(AREAVEC, 'descend');  
        THINGS = SORTED(1:2);

        for R = 1:2
            for S = 1:RSTATS
                if THINGS(R) == AREAVEC(S)
                   NEWSTATS(R) = STATS(S);
                end
            end
        end
           
        STATS = []; STATS = NEWSTATS;
        
   
        % Create data row for that platelet for that image.
        PLATELET{1,1} = A; % Area number.
        PLATELET{1,2} = B; % Image number.
        PLATELET{1,4} = STATS(1).Area .* (CONVFACTOR ./ 1000) .^ 2; % Area of post 1 (converted to um).
        PLATELET{1,5} = STATS(1).Centroid(1); % Row location of post 1.
        PLATELET{1,6} = STATS(1).Centroid(2); % Column location of post 1.
        PLATELET{1,7} = STATS(2).Area .* (CONVFACTOR ./ 1000) .^ 2; % Area of post 2 (converted to um).
        PLATELET{1,8} = STATS(2).Centroid(1); % Row location of post 2.
        PLATELET{1,9} = STATS(2).Centroid(2); % Column location of post 2.
        PLATELET{1,3} = sqrt((PLATELET{1,8} - PLATELET{1,5})^2 + (PLATELET{1,9} - PLATELET{1,6})^2) * CONVFACTOR / 1000;
        
        % If the user is analyzing for P-selectin, covert the blue layer to
        % BW/perform blob analysis/pull out data.
        if COLORSELECT == 1
            H_PSELECTIN = medfilt2(im2bw(HROI_B, THRESHOLD_B), [3, 3]); % Converts to BW/applies filter.
            RLL = bwlabel(H_PSELECTIN, 4); % Finds blob.
            STATS_PSELECTIN = regionprops(RLL, 'Area'); % Computes properties of blob.
            [R_STATS_P ~] = size(STATS_PSELECTIN); % Should just find one blob - check.
            if R_STATS_P >= 2 % If too many blobs are found, cut out all small noisy ones (like above).
                AREAVEC = [];
                for X = 1:R_STATS_P
                    AREAVEC = [AREAVEC STATS_PSELECTIN(X).Area];
                end
                [Y I] = max(AREAVEC);
                STATS_HOLD(1).Area = STATS_PSELECTIN(I).Area; STATS_PSELECTIN = []; STATS_PSELECTIN = STATS_HOLD;
            elseif R_STATS_P == 0
                STATS_PSELECTIN = []; STATS_PSELECTIN(1).Area = 0;
            else
            end
          PLATELET{1, 10} = STATS_PSELECTIN(1).Area; % Area of P-selectin staining (pixel).
          PLATELET{1, 11} = STATS_PSELECTIN(1).Area .* (CONVFACTOR ./ 1000) .^2; % " " (converted to um).
          % Multiply (scalar) BW image (actually a map of logicals) by the
          % original ROI's blue layer - will create a map where everything
          % not deemed to be a part of the P-selectin staining will be
          % zero.
          INTENSITYMAP = double(RLL) .* double(HROI_B);
          % Sum all of the values within this for the total intensity for
          % that platelet's P-selectin/total. 
          INTENSITYSUM = sum(sum(INTENSITYMAP, 1));
          % Assign this to the data array.
          PLATELET{1, 12} = INTENSITYSUM;
          % Divide this by pixel/um area to get an average.
          PLATELET{1, 13} = INTENSITYSUM./PLATELET{1, 10};
          PLATELET{1, 14} = INTENSITYSUM./PLATELET{1, 11};
        end
                
        % If the image is the first of a series, save the centroid
        % for that platelet.
        if B == 1
            CENTROID(1,1) = PLATELET{1,5}; CENTROID(1,2) = PLATELET{1,6}; CENTROID(1,3) = PLATELET{1,8}; CENTROID(1,4) = PLATELET{1,9};
            IMPORTANTCENTROID = [IMPORTANTCENTROID; CENTROID];
        end
        
        % Add that data to the running array.
        PLATELETDATA = [PLATELETDATA; PLATELET];
        
    end
end

REFERENCEDATA = [{'Area Number'} {'Image Number'} {'Weighted Post-Post Distance (um)'}...
    {'Post 1 Area (um^2)'} {'Weighted Post 1 Coordinate - R (pixel)'} {'Weighted Post 2 Coordinate - C (pixel)'}...
    {'Post 2 Area (um^2)'} {'Weighted Post 2 Coordinate - R (pixel)'} {'Weighted Post 2 Coordinate - C (pixel)'}];

% For each reference area - for loop.
for C = 1:NUMREFERENCE
    
    % For each image given - for loop.
    for D = 1:NUMIMAGES
        
        % Read image.
        H = imread(LIST(D, :));
        
        % For first image - steps to choose a region of interest from the
        % image.
        if D == 1
            
            % Prompts user to choose a region of interest from the image.
                        % If it's a single image, choose from the first image. If it's
            % a folder, choose from the last.
            if FILETYPE == 1
                imshow(H)
            elseif FILETYPE == 2
                imshow(imread(LIST(NUMIMAGES, :)));
            end
            ROI = imrect

            % Return coordinates from the region of interest.
            % OUTPUTS: 1 x 4 array - [xmin ymin width height]
            pos = getPosition(ROI); 
            Y1 = pos(2); % Y min
            Y2 = Y1 + pos(4); % Y max
            X1 = pos(1); % X min
            X2 = X1 + pos(3); % X max
            
            % Save ROI to running variable for replotting later.
            LINEROI{1, 1} = ['Reference' num2str(A)];
            LINEROI{1, 2} = X1; LINEROI{1, 3} = X2; LINEROI{1, 4} = Y1; LINEROI{1, 5} = Y2;
            EACHROI = [EACHROI; LINEROI]                      ;
        end

        % Crop image to the chosen region of interest
        HROI = H(round(Y1):round(Y2), round(X1):round(X2), :); 

        % Take out individual frames from the image. Remember, green = posts, red =
        % platelets, blue = p-selectin.
        HROI_G = HROI(:, :, 2); % POST ARRAY
        HROI_B = HROI(:, :, 3); % P-SELECTIN
        
        % Convert to B/W using a threshold (second input.)
        H = im2bw(HROI_G, THRESHOLD_G);
        H = medfilt2(H,[3 3]);
            
        % Perform blob analysis
        RLL = bwlabel(H, 4); % Finds blobs.
        STATS = [];
        STATS = regionprops(RLL,'Area','Centroid'); % Computes properties of blobs.
        
        % Determine how many blobs are found.
        [RSTATS ~] = size(STATS);
        
        % If the blob analysis finds more than 2 blobs (noise), choose the
        % largest two (posts.)
                
        % If the blob analysis finds more than 2 blobs (noise), choose the
        % largest two (posts.)
        AREAVEC = [];
        for Q = 1:RSTATS
            AREAVEC = [AREAVEC STATS(Q).Area];   
        end

        SORTED = sort(AREAVEC, 'descend');  
        THINGS = SORTED(1:2);

        for R = 1:2
            for S = 1:RSTATS
                if THINGS(R) == AREAVEC(S)
                   NEWSTATS(R) = STATS(S)
                end
            end
        end
           
        STATS = []; STATS = NEWSTATS;
                
        % Create data row for that platelet for that image.
        REFERENCE{1,1} = C; % Area number.
        REFERENCE{1,2} = D; % Image number.
        REFERENCE{1,4} = STATS(1).Area .* (CONVFACTOR ./ 1000) .^ 2; % Area of post 1 (um).
        REFERENCE{1,5} = STATS(1).Centroid(1); % Row location of post 1.
        REFERENCE{1,6} = STATS(1).Centroid(2); % Column location of post 1.
        REFERENCE{1,7} = STATS(2).Area .* (CONVFACTOR ./ 1000) .^ 2; % Area of post 2 (um).
        REFERENCE{1,8} = STATS(2).Centroid(1); % Row location of post 2.
        REFERENCE{1,9} = STATS(2).Centroid(2); % Column location of post 2.
        REFERENCE{1,3} = sqrt((REFERENCE{1,8} - REFERENCE{1,5})^2 + (REFERENCE{1,9} - REFERENCE{1,6})^2) * CONVFACTOR / 1000;
        
        % If the image is the first of a series, save the centroid
        % for that platelet.
        if D == 1
            CENTROID(1,1) = REFERENCE{1,5}; CENTROID(1,2) = REFERENCE{1,6}; CENTROID(1,3) = REFERENCE{1,8}; CENTROID(1,4) = REFERENCE{1,9};
            IMPORTANTCENTROID = [IMPORTANTCENTROID; CENTROID];
        end
        
        % Add that data to the running array.
        REFERENCEDATA = [REFERENCEDATA; REFERENCE];
        
    end
end
        
% SECTION: Write data to an excel file.

% Write platelet data array.
xlswrite(NAMING, PLATELETDATA, 'Contracting Platelet Regions');

% Write reference data array.
xlswrite(NAMING, REFERENCEDATA, 'Reference Platelet Regions');

% Create summary data array
SUMMARYDATA = [{'Type of Area'} {'Area Number'} {'Average Distance Between Posts (um)'}...
    {'Average Post Size (um^2)'} {'Minimum Distance Between Posts (um)'} {'Max dist. Img Number'}]; % Data labels.
PLTSUMMARYDATA = []; % For platelet summary data.
REFSUMMARYDATA = []; % For reference summary data.

% Sort through platelet area data.
% For each platelet area - for loop.
for E = 1:NUMPLATELET

    % Index out that area's data from the platelet data array.
    PLTDATA = cell2mat(PLATELETDATA(((E - 1) .* NUMIMAGES + 2):(E .* NUMIMAGES + 1), :));

    % Index out relevant variables into vectors. (Makes searching for
    % min/max/etc. easier).
    ALLPOSTAREA = [PLTDATA(:, 4); PLTDATA(:, 7)]; % All post area sizes (um^2).
    IMGNUMBER = PLTDATA(:, 2); % Image number.
    POSTDISTANCE = PLTDATA(:, 3); % Post-post distance (um).

    % Find relevant data and add to a summary array.
    PLTSUMMARYLINE{1, 1} = 'Contracting Platelet'; % What type of area it is.
    PLTSUMMARYLINE{1, 2} = E; % What area number is it.
    PLTSUMMARYLINE{1, 3} = mean(POSTDISTANCE); % What is the average post distance (um).
    PLTSUMMARYLINE{1, 4} = mean(ALLPOSTAREA); % What is the average post size (um^2).
    [PLTSUMMARYLINE{1, 5} INDEX] = min(POSTDISTANCE); % Finds the maximum post distance and the index.
    PLTSUMMARYLINE{1, 6} = IMGNUMBER(INDEX); % Finds image number where max distance occurs.

    PLTSUMMARYDATA = [PLTSUMMARYDATA; PLTSUMMARYLINE];

end

% Sort through reference area data.
% For each reference area - for loop.
for F = 1:NUMREFERENCE

    % Index out that area's data from the platelet data array.
    REFDATA = cell2mat(REFERENCEDATA(((F - 1) .* NUMIMAGES + 2):(F .* NUMIMAGES + 1), :));

    % Index out relevant variables into vectors. (Makes searching for
    % min/max/etc. easier).
    ALLPOSTAREA = [REFDATA(:, 4); REFDATA(:, 7)]; % All post area sizes (um^2).
    IMGNUMBER = REFDATA(:, 2); % Image number.
    POSTDISTANCE = REFDATA(:, 3); % Post-post distance (um).

    % Find relevant data and add to a summary array.
    REFSUMMARYLINE{1, 1} = 'Reference'; % What type of area it is.
    REFSUMMARYLINE{1, 2} = F; % What area number is it.
    REFSUMMARYLINE{1, 3} = mean(POSTDISTANCE); % What is the average post distance (um).
    REFSUMMARYLINE{1, 4} = mean(ALLPOSTAREA); % What is the average post size (um^2).
    [REFSUMMARYLINE{1, 5} INDEX] = min(POSTDISTANCE); % Finds the maximum post distance and the index.
    REFSUMMARYLINE{1, 6} = IMGNUMBER(INDEX); % Finds image number where max distance occurs.

    REFSUMMARYDATA = [REFSUMMARYDATA; REFSUMMARYLINE];

end

% Combine summary data into one array.
SUMMARYDATA = [SUMMARYDATA; PLTSUMMARYDATA; REFSUMMARYDATA];

% Only write to the excel file if a folder of images was analyzed -
% redundant otherwise!

% Write the array into the excel file.
xlswrite(NAMING, SUMMARYDATA, 'Summary of Data');

if (NUMPLATELET + NUMREFERENCE) <= 28      
    
    % SECTION: Plotting ROI and centroids on the first/last image.

    % Create a list of color and line combinations to index out of for plotting.
    COLORS = [{'y-'} {'m-'} {'c-'} {'r-'} {'g-'} {'b-'} {'w-'}...
        {'y--'} {'m--'} {'c--'} {'r--'} {'g--'} {'b--'} {'w--'}...
        {'y:'} {'m:'} {'c:'} {'r:'} {'g:'} {'b:'} {'w:'}...
        {'y-.'} {'m-.'} {'c-.'} {'r-.'} {'g-.'} {'b-.'} {'w-.'}];
    % Create a corresponding list of color and line combinations to index out
    % for labeling.
    COLORSNAMES = [{'Yellow Solid Line'} {'Magenta Solid Line'} {'Cyan Solid Line'} {'Red Solid Line'}...
        {'Green Solid Line'} {'Blue Solid Line'} {'White Solid Line'}...
        {'Yellow Dashed Line'} {'Magenta Dashed Line'} {'Cyan Dashed Line'} {'Red Dashed Line'}...
        {'Green Dashed Line'} {'Blue Dashed Line'} {'White Dashed Line'}...
        {'Yellow Dotted Line'} {'Magenta Dotted Line'} {'Cyan Dotted Line'} {'Red Dotted Line'}...
        {'Green Dotted Line'} {'Blue Dotted Line'} {'White Dotted Line'}...
        {'Yellow Dash Dot Line'} {'Magenta Dash Dot Line'} {'Cyan Dash Dot Line'} {'Red Dash Dot Line'}...
        {'Green Dash Dot Line'} {'Blue Dash Dot Line'} {'White Dash Dot Line'}];

    LABELKEY = [{'Area Type'} {'Area Number'} {'Line type'}];

    H = imread(LIST(1,:));

    imshow(H)
    hold on
    
    % For each area analyzed - for loop.
    for I = 1:(NUMPLATELET + NUMREFERENCE)
    % For both if a single images was analyzed or a folder was analyzed.
    % Read image.
    % Pull out X coordinates from ROI vector (X1  X2 X2 X1 X1).
    XCOORD = [EACHROI{I, 2} EACHROI{I, 3} EACHROI{I, 3} EACHROI{I, 2} EACHROI{I, 2}];
    
    % Pull out Y coordinates from ROI vector (Y1 Y1 Y2 Y2 Y1).
    YCOORD = [EACHROI{I, 4} EACHROI{I, 4} EACHROI{I, 5} EACHROI{I, 5} EACHROI{I, 4}];
    
    % Plot these coordinates in a color.
    plot(XCOORD, YCOORD, COLORS{I});
    
    % Plot the centroid on top of the posts - color == white.
    plot((XCOORD(1) + IMPORTANTCENTROID(I, 1)), (YCOORD(1) + IMPORTANTCENTROID(I, 2)), 'w'); % Post 1
    plot((XCOORD(1) + IMPORTANTCENTROID(I, 1)), (YCOORD(1) + IMPORTANTCENTROID(I, 2)), 'wo'); % Post 1
    plot((XCOORD(1) + IMPORTANTCENTROID(I, 3)), (YCOORD(1) + IMPORTANTCENTROID(I, 4)), 'w'); % Post 2    
    plot((XCOORD(1) + IMPORTANTCENTROID(I, 3)), (YCOORD(1) + IMPORTANTCENTROID(I, 4)), 'wo'); % Post 2    
    
    % Create a color code.
    if I <= NUMPLATELET
        TYPE = 'Contracting Platelet';
        NUM = I;
    else
        TYPE = 'Reference Area';
        NUM = I - NUMPLATELET;
    end
    
    COLOR = COLORSNAMES(I);
    
    % Update label key
    LABELKEY = [LABELKEY; [{TYPE} {NUM} {COLORSNAMES{I}}]];
    
    end
    
end

% Add threshold information to be put in on label key.
if COLORSELECT == 0
    THRESHOLD_B = 'N/A';
end
LABELKEY = [LABELKEY; [{''} {''} {''}]; {'Threshold - Green'} {THRESHOLD_G} {''};...
    {'Threshold - Blue'} {THRESHOLD_B} {''}; {'Converstion Factor'} {CONVFACTOR} {''}];
% Write key to the excel file:

xlswrite(NAMING, LABELKEY, 'Label Key and Extra Info');
end

% MIT License

% Copyright (c) 2016 David Myers, Meredith Fay

% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:

% The above copyright notice and this permission notice shall be included in all
% copies or substantial portions of the Software.

% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
% SOFTWARE.

