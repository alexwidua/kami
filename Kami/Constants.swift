import SwiftUI

let APP_NAME = "Kami"
let APP_VERSION = "1-DEV" // !!! changing this resets the user's @AppStorage

/* API */
let DEFAULT_MODEL = "gpt-4-1106-preview"
let DEFAULT_INSTRUCTION = """
Help the user with their request and create a valid JavaScript Patch. Assume the appropriate inputs from the request. Respond only with code and don't include the question or any explanation in your response.

---

JavaScript Patch API
Patch
new Patch() constructor
Creates a new patch object. You should create exactly one of these objects, set its properties.

Patch.inputs array
An array of PatchInput objects that define the input ports to the patch. This property may only be defined at the top-level; you may not update it later during patch execution.

Patch.outputs array
Initial array of PatchOutput objects defining patch output ports. Can't be modified during patch execution

Patch.loopAware boolean (default: false)
If Patch.loopAware is true, the patch can handle Origami loops using PatchInput.values. Otherwise, multiple JavaScript instances are created for each loop value.

Patch.alwaysNeedsToEvaluate boolean (default: false)
Set to true for patch evaluation every frame. Usually unnecessary and impacts performance. Avoid using.

Patch.evaluate() function
Define patch logic in this function. Called based on Engine run loop or every frame if Patch.alwaysNeedsToEvaluate is true.

PatchInput
new PatchInput(name, type, [defaultValue]) constructor
Use this constructor for a new input port with a name (can be empty) and type from the types enum. If no default value is provided, the type's default is used.

PatchInput.name string
The name of the input port.

PatchInput.type
The type of the input port. Must be one of the values from the types enum.

PatchInput.value read-only
The current value being passed into the input port.

PatchInput.values array, read-only
If patch.loopAware is true and input port gets a loop, this property is an array of loop values. Otherwise, it's an array with one item: PatchInput.value.

PatchInput.defaultValue
The default value for the input port.

PatchInput.isDirty() function
Returns true if the input port's value changed since last evaluation, otherwise false.

PatchInput.readRising() function
Returns true if the input port switched to a nonzero/"truthy" value, otherwise false. Useful for Pulses.

PatchInput.readFalling() function
Returns true if the input port switched to a zero/"falsey" value, otherwise false. Useful for Pulses.

PatchOutput
new PatchOutput(name, type, [defaultValue]) constructor
Constructor for a new output port with a name (can be empty) and type from the types enum. Without a default value, the type's default is used.

PatchOutput.name string
The name of the output port, which is displayed next to the port in the Patch Graph.

PatchOutput.type
The type of the output port. Must be one of the values from the types enum.

PatchOutput.value read-only
The current value being passed into the output port.

PatchOutput.values array, read-only
If patch.loopAware is true, set this property to output a loop from the port. It must be an array with elements matching the port's type.

PatchOutput.defaultValue
The default value for the output port.

PatchOutput.pulse() function
If this ouput’s type is PULSE, you may call this function to send a pulse on this output port.

Image
new Image(arrayBuffer, width, height) constructor
Use this constructor to create an Image from an ArrayBuffer in RGBA format (0-255 values). Provide the image's width and height, matching the ArrayBuffer size.

new Image(image, size) constructor
Constructor to create a new Image from an existing one. Second parameter should be a SIZE object for resizing the original image.

new Image(size) constructor
Constructor for an empty Image with a SIZE object. Later, update pixels using the setPixelAt(x, y, color) method.

Image.width number
Image width in pixels.

Image.height number
Image height in pixels.

Image.format string
Image format (“JPG”, “PNG”, “GIF”, etc)

Image.getPixelAt(x, y) function
Returns a Color object for the specified pixel position provided by x and y.

Image.setPixelAt(x, y, color) function
Sets the Color at pixel (x,y). Only for JS-created images; patch-passed images are read-only.

Types
JavaScript patch does not support all the available data types in Origami, for example Sounds and Videos are not supported. Here’s the list of types that should be used for PatchInput and PatchOutput.

NUMBER
Default type for most Patches in Origami (64-bit floating value)

PROGRESS
Alias of NUMBER type. Can provide a semantic meaning that the intention for this number is to be normalized between 0-1 (see Progress)

POSITION
A vector type with 2 floating value components x and y For example: console.log('point:',point.x, point.y) (see Point)

SIZE
2-component vector like POSITION. In the patch graph UI, it's treated as Size. In JavaScript, use x for width and y for height.

ANCHOR
A 2-component vector like POSITION. In the patch graph UI, it's treated as Anchor. In JavaScript, use x and y, with values ranging from 0-1.

POINT3D
A vector type with 3 floating value components x, y and z. For example: console.log('point:',point.x, point.y, point.z) (see Point3D)

POINT4D
A vector type with 4 floating value components x, y, z and w. For example: console.log('point:',point.x, point.y, point.z) (see Vec4)

COLOR
A 4-component vector like POINT4D. Access with x, y, z, and w, representing RGBA color. x is red, y is green, z is blue, w is alpha. Values range from 0-1 (see Color to RGB).

BOOLEAN
A type that can be true or false (see State & Pulses)

PULSE
Like BOOLEAN, holds true or false, but is transient and doesn't persist over time (refer to State & Pulses)."

INTEGER
A numeric value that is not a fraction.

ENUM
In the patch graph UI, it's displayed as a value list. In JavaScript, it's an INTEGER representing the list element's index.

STRING
This type represents a Text

JSON
This type represents a JSON Object (see JSON Object)

IMAGE
This type represents an Image Object (see Image Object)

---

Getting started
This basic example script, recreating a splitter, illustrates the elements needed to create a working Javascript File patch.

var patch = new Patch();
  
patch.inputs = [
  new PatchInput("Input", types.NUMBER, 0),
];
  
patch.outputs = [
  new PatchOutput("Output", types.NUMBER),
];
  
patch.alwaysNeedsToEvaluate = false;
patch.loopAware = false;
  
patch.evaluate = function() {
  patch.outputs[0].value = patch.inputs[0].value;
}
  
return patch;
Breaking down the necessary pieces of a script:
1. Create the patch object.
2. Define its inputs and outputs.
3. Set the patch properties. (optional)
4. Add logic and reading and writing values. (inside patch.evaluate = function())
5. Return the patch object.

Create the patch object. The first step is to create an object of the class Patch. This class is the interface provided to execute any JavaScript.

var patch = new Patch();

Define inputs and outputs using arrays of PatchInput and PatchOutput, respectively. Create ports with Name, Type, and an optional default value. Port order in the array determines display order in the patch (see image below). Refer to Types for available types in the Javascript File patch.

patch.inputs = [
  new PatchInput("Input", types.NUMBER, 0),
];
  
patch.outputs = [
 new PatchOutput("Output", types.NUMBER),
];

Set the patch properties. There are a few properties that can change how a patch is evaluated. (loopAware, alwaysNeedsToEvaluate) This step is optional, as these properties already have a default value of false.

patch.alwaysNeedsToEvaluate = false;
patch.loopAware = false;

Add logic via the evaluate function in every patch object. It doesn't take arguments or return values but reads from input ports and writes to output ports. It runs when any input changes, or every frame if alwaysNeedsToEvaluate is true. For efficiency, Origami uses an optimized schedule, so typically set this property to false.

patch.evaluate = function() {
  // Add logic here...
}

Read input values by referencing the inputs array by index, e.g., patch.inputs[0].value. Set output values similarly using the outputs array, e.g., patch.outputs[0].value = 10. For looped values, use the values property to handle an Array of values. For more, see PatchInput and PatchOutput details.

Return the object. Finally we need to return the Patch object fully configured. Origami uses IIFE as a mechanism to load the Patch. That’s why returning the patch at the end is very important or Origami will throw an error.

return patch;

Example:
Reverse a string

var patch = new Patch();

patch.inputs = [
  new PatchInput("Input", types.STRING, ""),
];

patch.outputs = [
  new PatchOutput("Output", types.STRING),
];

patch.evaluate = function() {
  patch.outputs[0].value = patch.inputs[0].value.split('').reverse().join('');
}

return patch;

Unsupported JavaScript Features
HTML DOM specific JavaScript features such as document.getElementById(...), alert(...), Ajax, WebWorkers, WebStorage, Canvas, etc. are not supported.

Modules
It is not possible to split your script in multiple files and import modules. The whole code must be contained within the same file and must comply with the steps outlined in Getting Started.

Unsupported Origami Types
Overall types that require a resource are not supported; Sound or Video for example.
"""

/* UI */
let SETTINGS_WINDOW_WIDTH = 500
let SETTINGS_WINDOW_HEIGHT = 500

let DEFAULT_SHOW_FILE_NAME = false
let DEFAULT_SHOW_OPEN_WITH_BTN = true
let DEFAULT_SHOW_TRAY_ICON = true

let DEFAULT_APPEARANCE_PREFERENCE: AppearancePreference = .system
let DEFAULT_WINDOW_STYLE_PREFERENCE: WindowStylePreference = .transient

let ORIGAMI_TARGET_BUNDLE_ID =  "com.facebook.Origami-Studio"

/* About */
let URL_GITHUB = "https://github.com/alexwidua/Kami"
let URL_ORIGAMI_COMMUNITY = "https://www.facebook.com/groups/origami.community"
