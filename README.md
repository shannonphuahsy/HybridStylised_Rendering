# Reproducing Traditional Japanese Animation Styles through Hybrid Stylised Rendering Techniques

A hybrid non‑photorealistic rendering (NPR) showcase combining **watercolour‑like painterly backgrounds** with **toon‑shaded characters** inside Unity 6.  This project demonstrates a custom stylised rendering pipeline designed to merge two traditionally separate aesthetic approaches into a single cohesive scene.

---

## **Download & Installation**

You can run a demo scene by downloading the pre‑built executable.

### **Option 1 — GitHub Build**
1. Download **HybridStylised_Rendering.zip** from the project’s GitHub Releases page.  
2. Extract the `.zip` file to any folder on your machine.

### **Option 2 — OneDrive Download**
Download the same build from OneDrive:  
**[Insert OneDrive Link Here]**

---

## **System Requirements**
- **Unity 6** installed on your machine  

---

## **Running the Project**
1. After extracting the build folder, open it.
2. Run **HybridStylised_Rendering.exe**.
3. The test scene will load automatically.

---

## **Controls**
- **W A S D — Player Movement**  
  The player character can be moved freely around the scene using the standard WASD layout:  
  - **W** moves the character **forward**  
  - **S** moves the character **backward** 
  - **A** moves the character **left**   
  - **D** moves the character **right**  


---

## **Test Scene**
This test scene demonstrates the core goal of the project:

### **Hybrid Stylised Rendering Pipeline**
- **Watercolour Background Layer**  
  - Region‑flattened colour fields  
  - Soft diffusion and painterly texture simulation  
  - Designed to evoke hand‑painted environmental art

- **Toon‑Shaded Character Layer**  
  - Cel‑shaded lighting  
  - Clean, controllable contour lines  
  - Artist‑defined parameters for shadow thresholds, colour steps, and outline width

---

## **Repository Contents: Shader Files**

This repository also includes the **original shader source files** used to create the hybrid stylised rendering pipeline.  
If you want to apply these shaders to your own Unity scene or experiment with their parameters, you can find them in the project:

- **ToonShader.shader** — Implements the toon‑shaded character rendering, including shadow thresholds, colour steps, outline width, and inner line strength.  
- **Watercolor.shader** — Implements the painterly background rendering, including region flattening, edge strength, paper texture simulation, and warm–cool colour scripting.

These files can be dropped into any Unity 6 URP project. Once imported, you can assign them to your own materials and test the parameters exactly as used in the demonstration build.

### **Renderer Feature**

- **WatercolorRendererFeature.cs** — A custom URP Renderer Feature that applies the watercolour effect as a full‑screen pass.  
  This script filters the **Background** layer and executes the Watercolor shader after opaque rendering, ensuring that only environment objects receive the painterly treatment while the toon‑shaded character remains unaffected.

To use this feature, add it to your URP Renderer Asset under **Renderer Features**, assign the Watercolor material created from the shader, and ensure your scene objects are correctly placed on the **Foreground** and **Background** layers.

---

## **Project Purpose**
This build exists to verify that the hybrid stylised pipeline:
- Renders both layers correctly in Unity 6  
- Maintains visual separation between character and background  
- Preserves the intended aesthetic choices  
- Demonstrates the feasibility of combining two NPR techniques in a single scene  

