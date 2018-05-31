macOS 10.13
python 2.7
Turi Create 4.3.2
ChromeDriver 2.39
simple_image_annotator and googleimagesdownload dont have a release version
iOS 11.4
Xcode 9.4



The aim of this project is to create a mlmodel file to be used on an iOS app. We use turi software (github.com/apple/turicreate) for this. The model created is a neural network trained with a set of guitar images. These are the steps and technologies used for that. Inspiration taken from github.com/ichibod

1. Gather images with googleimagesdownload (github.com/hardikvasa/google-images-download). If you want to download more than 100 images (the more the better the model will be), you must install chromedriver (chromedriver.chromium.org). Run the first commad for every term (guitar type in this case) that needs to be downloaded.

	sudo googleimagesdownload -k "Telecaster" -l 30  -o /path-to-MLGuitarIdentifier/dataset/images/ -cd /Applications/chromedriver -s medium
	sudo chown -R yourUser dataset/

2. Frame and label these images with simple_image_annotator (github.com/sgp715/simple_image_annotator). If you have problems with any image (corrupt file etc.), delete it because otherwise it will create problems further down the line:

	python app.py ../MLGuitarIdentifier/dataset/images/ --out ../MLGuitarIdentifier/images-data.csv

3.  Create the mlmodel file by running main.py:

	python main.py && mv GuitarClassifier.mlmodel ../GuitarIdentifier/

4. Open the app on xcode and run it. It uses the camera therefore needs to run on a real device