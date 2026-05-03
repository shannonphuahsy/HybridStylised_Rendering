using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class WatercolorRendererFeature : ScriptableRendererFeature
{
    class WatercolorPass : ScriptableRenderPass
    {
        private Material material;
        private RTHandle source;
        private RTHandle tempTexture;

        public WatercolorPass(Material mat)
        {
            material = mat;
            renderPassEvent = RenderPassEvent.AfterRenderingTransparents;
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            source = renderingData.cameraData.renderer.cameraColorTargetHandle;

            var descriptor = renderingData.cameraData.cameraTargetDescriptor;
            descriptor.depthBufferBits = 0;

            RenderingUtils.ReAllocateHandleIfNeeded(
                ref tempTexture,
                descriptor,
                FilterMode.Bilinear,
                TextureWrapMode.Clamp,
                name: "_WatercolorTempTexture"
            );
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (material == null)
                return;

            var cmd = CommandBufferPool.Get("Watercolor Pass");

            Blitter.BlitCameraTexture(cmd, source, tempTexture);

            Blitter.BlitCameraTexture(cmd, tempTexture, source, material, 0);

            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        public override void OnCameraCleanup(CommandBuffer cmd)
        {

            tempTexture?.Release();
        }
    }

    [System.Serializable]
    public class Settings
    {
        public Material watercolorMaterial;
    }

    public Settings settings = new Settings();
    private WatercolorPass pass;

    public override void Create()
    {
        if (settings.watercolorMaterial != null)
            pass = new WatercolorPass(settings.watercolorMaterial);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (settings.watercolorMaterial == null)
            return;

        renderer.EnqueuePass(pass);
    }
}