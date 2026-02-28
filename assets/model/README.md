# PlantDoctor Model Assets

This folder contains the TensorFlow Lite model for plant disease classification.

## Required Model File

Place your trained TFLite model here with the following name:

- `plant_disease_model.tflite`

## How to Convert Your Model to TFLite

### From TensorFlow/Keras:

```python
import tensorflow as tf

# Load your trained Keras model
model = tf.keras.models.load_model('your_model.h5')

# Convert to TFLite
converter = tf.lite.TFLiteConverter.from_keras_model(model)

# Optional: Enable optimizations for smaller size
converter.optimizations = [tf.lite.Optimize.DEFAULT]

# Convert and save
tflite_model = converter.convert()
with open('plant_disease_model.tflite', 'wb') as f:
    f.write(tflite_model)
```

### From PyTorch (via ONNX):

```python
import torch
import onnx
from onnx_tf.backend import prepare
import tensorflow as tf

# Step 1: Export PyTorch model to ONNX
model = torch.load('your_model.pth')
model.eval()
dummy_input = torch.randn(1, 3, 224, 224)
torch.onnx.export(model, dummy_input, 'model.onnx', opset_version=11)

# Step 2: Convert ONNX to TensorFlow
onnx_model = onnx.load('model.onnx')
tf_rep = prepare(onnx_model)
tf_rep.export_graph('tf_model')

# Step 3: Convert TensorFlow to TFLite
converter = tf.lite.TFLiteConverter.from_saved_model('tf_model')
tflite_model = converter.convert()
with open('plant_disease_model.tflite', 'wb') as f:
    f.write(tflite_model)
```

## Model Specifications

The app expects the model to have:

- **Input shape**: `[1, 224, 224, 3]` (NHWC: batch, height, width, RGB channels)
- **Input type**: Float32 normalized to `[0, 1]`
- **Output shape**: `[1, 38]` (38 disease classes)
- **Output type**: Float32 logits (softmax applied in app)

## Input Preprocessing

Images are preprocessed as follows:

```
normalized_pixel = pixel / 255.0
```

The pixel values are normalized from [0, 255] to [0, 1] range.

## Supported Classes (38 total)

| Index | Label                                                  |
| ----- | ------------------------------------------------------ |
| 0     | Apple\_\_\_Apple_scab                                  |
| 1     | Apple\_\_\_Black_rot                                   |
| 2     | Apple\_\_\_Cedar_apple_rust                            |
| 3     | Apple\_\_\_healthy                                     |
| 4     | Blueberry\_\_\_healthy                                 |
| 5     | Cherry\_(including_sour)\_\_\_Powdery_mildew           |
| 6     | Cherry\_(including_sour)\_\_\_healthy                  |
| 7     | Corn\_(maize)\_\_\_Cercospora_leaf_spot_Gray_leaf_spot |
| 8     | Corn\_(maize)_\_\_Common_rust_                         |
| 9     | Corn\_(maize)\_\_\_Northern_Leaf_Blight                |
| 10    | Corn\_(maize)\_\_\_healthy                             |
| 11    | Grape\_\_\_Black_rot                                   |
| 12    | Grape*\_\_Esca*(Black_Measles)                         |
| 13    | Grape*\_\_Leaf_blight*(Isariopsis_Leaf_Spot)           |
| 14    | Grape\_\_\_healthy                                     |
| 15    | Orange*\_\_Haunglongbing*(Citrus_greening)             |
| 16    | Peach\_\_\_Bacterial_spot                              |
| 17    | Peach\_\_\_healthy                                     |
| 18    | Pepper,\_bell\_\_\_Bacterial_spot                      |
| 19    | Pepper,\_bell\_\_\_healthy                             |
| 20    | Potato\_\_\_Early_blight                               |
| 21    | Potato\_\_\_Late_blight                                |
| 22    | Potato\_\_\_healthy                                    |
| 23    | Raspberry\_\_\_healthy                                 |
| 24    | Soybean\_\_\_healthy                                   |
| 25    | Squash\_\_\_Powdery_mildew                             |
| 26    | Strawberry\_\_\_Leaf_scorch                            |
| 27    | Strawberry\_\_\_healthy                                |
| 28    | Tomato\_\_\_Bacterial_spot                             |
| 29    | Tomato\_\_\_Early_blight                               |
| 30    | Tomato\_\_\_Late_blight                                |
| 31    | Tomato\_\_\_Leaf_Mold                                  |
| 32    | Tomato\_\_\_Septoria_leaf_spot                         |
| 33    | Tomato\_\_\_Spider_mites_Two-spotted_spider_mite       |
| 34    | Tomato\_\_\_Target_Spot                                |
| 35    | Tomato\_\_\_Tomato_Yellow_Leaf_Curl_Virus              |
| 36    | Tomato\_\_\_Tomato_mosaic_virus                        |
| 37    | Tomato\_\_\_healthy                                    |

## Training Dataset

These classes come from the PlantVillage dataset, a popular benchmark for plant disease classification.

## Recommended Model Architectures

For best mobile performance:

- **MobileNetV2/V3** - Fast inference, small size (~14MB)
- **EfficientNet-Lite** - Good accuracy/speed balance
- **NASNet-Mobile** - Higher accuracy, larger size

## Testing Your Model

Before using in the app, verify your model works:

```python
import tensorflow as tf
import numpy as np

# Load TFLite model
interpreter = tf.lite.Interpreter(model_path='plant_disease_model.tflite')
interpreter.allocate_tensors()

# Get input/output details
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print(f"Input shape: {input_details[0]['shape']}")   # Should be [1, 224, 224, 3]
print(f"Output shape: {output_details[0]['shape']}") # Should be [1, 38]

# Test inference
test_input = np.random.rand(1, 224, 224, 3).astype(np.float32)
interpreter.set_tensor(input_details[0]['index'], test_input)
interpreter.invoke()
output = interpreter.get_tensor(output_details[0]['index'])
print(f"Output sum (softmax): {np.exp(output).sum()}")  # Should be ~1.0 after softmax
```

## Troubleshooting

### Model file not found

Ensure the file is named exactly `plant_disease_model.tflite` and placed in `assets/model/`

### Wrong input shape

The model expects NHWC format [1, 224, 224, 3]. If your model uses NCHW, you'll need to convert it.

### Inference errors

Make sure your model was trained on normalized [0,1] inputs, not ImageNet normalization.
