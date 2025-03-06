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
ALC - boundary between anterior lamina cribrosa and prelaminar neuaral tissue
alg_line - structure containing curve fit markings
allScores - matrix of size (r,c,s), where (r,c) is the location of each pixel in the image and s is the confidence that pixel (r,c) belongs to class s
allScores1 - matrix of size (r,c,s), where (r,c) is the location of each pixel in the image and s is the confidence that pixel (r,c) belongs to class s as predicted by net1
allScores2 - same as allScores1 but for the predictions of net2
BM - Bruch's membrane
BML - Bruch's membrane left
BMO - Bruch's membrane opening
BMR - Bruch's membrane right
C - Averaged predicted segmentation mask, where a mask is a matrix the same size as the image where the image intensity is replaced by the tissue label of each pixel
C1 - Segmentation mask predicted by net1 
C2 - Segmentation mask predicted by net2
center - center column of image
classes - tissue labels (strings)
col - column index
corr_mask - corrected, interpolated mask
CS - choroid-sclera interface
CSL - choroid-sclera interface left
CSR - choroid-sclera interface right
current_img - filename of filtered image, replaced with each new image or slice, used to create image datastore for training
current_mask - filename of corrected, interpolated mask, replaced with each new image or slice, used to create pixel label datastore for training
dsTrain - augmented training dataset
fieldIDs - labelIDs used to combine right and left tissues to the same class
fields - field names of alg_line
filtered_image - image slice after having pixels at bottom left corner being set to 0 to eliminate watermark and being filtered with guided filter
i - looping variable
I - image
idx - coordinates of single marking
imds - image datastore containing current filtered image slice 
j - variable used to loop through all slices of current image stack
k - variable used to loop through all fields
l - variable used to loop through all marking coordinates in each alg_line field
L - indices of coordinates of BM or CS on left side of image
labelIDs - tissue labels (numbers)
mark_labels_seg_test - structure of coordinates of markings for each tissue from the averaged predicted mask
markings - tissue markings for entire stack saved as a cell array of structures
mask - mask (image where pixel intensity is replaced with pixel label) of curve-fit predicted markings
masks - saved masks for entire image stack
ncols - number of columns in image
net1 - neural network (DeepLabv3+ originally with weights from ResNet-50) trained on 46 stacks of 24 images each (1104 images total) and their linearly interpolated manual markings
net2 - same as net1, but trained further for 1 epoch on each new image slice and corrected, linearly interpolated markings (6 images stacks of 24 images each for a total of 144 images at the time of upload)
net2_after - net2 after most recent additional training
net2_before - net2 before most recent additional training
nrows - number of rows in image
options - training options
original_image - image before filtering (if filtered = true, otherwise this and filtered_image are the same)
pxds - pixel label datastore
R - indices of coordinates of BM or CS on right side of image
roi - structure containing moveable points
row - row index
savenet - location of trained networks
score1 - confidence scores of labels predicted by net1
score2 - confidence scores of labels predicted by net2
variables - variables to load from savenet
xTrans - maximum horizontal translation of image and mask for random augmentation
yTrans - maximum vertical translation of image and mask for random augmentation

Functions:
boundary_marking.m - creates a segmentation mask by linearly interpolating between markings for each tissue
linefind_v2.m - curve-fitting function

Other contents:
most_updated_model.mat - location of net1, most current net2 (net2_after), and second-most current net2 (net2_before)
