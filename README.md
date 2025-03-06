# ONH-segmentation
Semi-automatic segmentation of ONH tissue boundaries, allowing for user correction

This file contains a list of all variables and functions used in prediction_correction.m and a guide for how to use the script.

Purpose: 
Use trained deep learning model to predict locations of markings indicating tissue boundaries, including the Bruch's membrane opening, Bruch's membrane (left and right side), choroid-scleral interface (left and right side), and anterior lamina cribrosa, for each image slice in multitiff stack of radial optical coherence tomagrophy (OCT) images of the optic nerve head (ONH); allow users to correct predicted markers if needed; save markings and other selected variables to a .mat file; and continue training deep learning model to improve predictions.

To Use:
1. Enter your chosen inputs:
	im_path - path to image stack you wish to segment
	img_id - identifier used for .mat file script creates to store variables
	num_slices - number of slices in image stack
	results_folder - folder where you wish to save .mat file
	savefile - path and name of saved .mat file
	filter - set to true if images have not yet had logo zeroed out or been filtered using guided filter
2. The predictions of net1 and net2 are averaged.  The averaged predictions are fit to curves, with 15 points used to represent each tissue boundary 
3. If needed, drag the points marking each tissue boundary to the correct location (red = BMO, blue = BM, green = CS, magenta = ALC).  Once the markings are correct, press any key to continue.
4. The corrected markings for each tissue are interpolated linearly and used to continue training net2.
5. The process is repeated for num_slices.

Variables:
<br>ALC - boundary between anterior lamina cribrosa and prelaminar neuaral tissue
<br>alg_line - structure containing curve fit markings
<br>allScores - matrix of size (r,c,s), where (r,c) is the location of each pixel in the image and s is the confidence that pixel (r,c) belongs to class s
<br>allScores1 - matrix of size (r,c,s), where (r,c) is the location of each pixel in the image and s is the confidence that pixel (r,c) belongs to class s as predicted by net1
<br>allScores2 - same as allScores1 but for the predictions of net2
<br>BM - Bruch's membrane
<br>BML - Bruch's membrane left
<br>BMO - Bruch's membrane opening
<br>BMR - Bruch's membrane right
<br>C - Averaged predicted segmentation mask, where a mask is a matrix the same size as the image where the image intensity is replaced by the tissue label of each pixel
<br>C1 - Segmentation mask predicted by net1 
<br>C2 - Segmentation mask predicted by net2
<br>center - center column of image
<br>classes - tissue labels (strings)
<br>col - column index
<br>corr_mask - corrected, interpolated mask
<br>CS - choroid-sclera interface
<br>CSL - choroid-sclera interface left
<br>CSR - choroid-sclera interface right
<br>current_img - filename of filtered image, replaced with each new image or slice, used to create image datastore for training
<br>current_mask - filename of corrected, interpolated mask, replaced with each new image or slice, used to create pixel label datastore for training
<br>dsTrain - augmented training dataset
<br>fieldIDs - labelIDs used to combine right and left tissues to the same class
<br>fields - field names of alg_line
<br>filtered_image - image slice after having pixels at bottom left corner being set to 0 to eliminate watermark and being filtered with guided filter
<br>i - looping variable
<br>I - image
<br>idx - coordinates of single marking
<br>imds - image datastore containing current filtered image slice 
<br>j - variable used to loop through all slices of current image stack
<br>k - variable used to loop through all fields
<br>l - variable used to loop through all marking coordinates in each alg_line field
<br>L - indices of coordinates of BM or CS on left side of image
<br>labelIDs - tissue labels (numbers)
<br>mark_labels_seg_test - structure of coordinates of markings for each tissue from the averaged predicted mask
<br>markings - tissue markings for entire stack saved as a cell array of structures
<br>mask - mask (image where pixel intensity is replaced with pixel label) of curve-fit predicted markings
<br>masks - saved masks for entire image stack
<br>ncols - number of columns in image
<br>net1 - neural network (DeepLabv3+ originally with weights from ResNet-50) trained on 46 stacks of 24 images each (1104 images total) and their linearly interpolated manual markings
<br>net2 - same as net1, but trained further for 1 epoch on each new image slice and corrected, linearly interpolated markings (6 images stacks of 24 images each for a total of 144 images at the time of upload)
<br>net2_after - net2 after most recent additional training
<br>net2_before - net2 before most recent additional training
<br>nrows - number of rows in image
<br>options - training options
<br>original_image - image before filtering (if filtered = true, otherwise this and filtered_image are the same)
<br>pxds - pixel label datastore
<br>R - indices of coordinates of BM or CS on right side of image
<br>roi - structure containing moveable points
<br>row - row index
<br>savenet - location of trained networks
<br>score1 - confidence scores of labels predicted by net1
<br>score2 - confidence scores of labels predicted by net2
<br>variables - variables to load from savenet
<br>xTrans - maximum horizontal translation of image and mask for random augmentation
<br>yTrans - maximum vertical translation of image and mask for random augmentation

Functions:
<br>boundary_marking.m - creates a segmentation mask by linearly interpolating between markings for each tissue
<br>linefind_v2.m - curve-fitting function

Other contents:
<br>most_updated_model.mat - location of net1, most current net2 (net2_after), and second-most current net2 (net2_before)
