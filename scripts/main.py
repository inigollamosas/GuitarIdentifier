import turicreate as tc
from turicreate import SArray
import pandas as pd
import os, sys, math, time, datetime

start = time.time()

# Load images info from the googleimagesdownload output file
csv = pd.read_csv('images-data.csv', names = ["image", "id", "label", "xMin", "xMax", "yMin", "yMax"])

# Load images
data = tc.image_analysis.load_images('images', with_path=True)

# the data is in no particular order, so we have to loop it to match
annotations, labels = [], []
for j, item in enumerate(data):
    found = False
    for i, row in csv.iterrows():
        if str(row['image']) == str(os.path.split(item['path'])[1]):
            height = csv.iat[i, 6] - csv.iat[i, 5]
            width = csv.iat[i, 4] - csv.iat[i, 3]
            props = {'label': csv.iat[i, 2], 'type': 'rectangle'}
            props['coordinates'] = {'height': height, 'width': width, 'x': csv.iat[i, 3] + math.floor(width / 2), 'y': csv.iat[i, 5] + math.floor(height / 2)}
            labels.append(str(row['label']))
            annotations.append([props])
            found = True
            break
    if found == False:
    	annotations.append([])
    	labels.append('')

# make an array from labels and annotations, matching the data order
data['annotations'] = SArray(data=annotations, dtype=list)
data['label'] = SArray(data=labels)

# Explore interactively
# data['image_with_ground_truth'] = tc.object_detector.util.draw_bounding_boxes(data["image"], data["annotations"])
# data.explore()

# Make a train-test split
train_data, test_data = data.random_split(0.9)

# Create a model
model = tc.object_detector.create(train_data, feature='image', annotations='annotations', max_iterations=2000)

# Mean average Precision
scores = model.evaluate(test_data)

# Export for use in Core ML
model.export_coreml('GuitarClassifier.mlmodel')

print 'Total time: ', str(datetime.timedelta(seconds=int(round(time.time() - start)))), ', Accuracy: ', scores['mean_average_precision']
