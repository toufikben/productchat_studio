{{flutter_js}}
{{flutter_build_config}}

const config = {
  canvasKitBaseUrl: "https://www.gstatic.com/flutter-canvaskit/stable/",
  renderer: "canvaskit",
  useColorEmoji: true,
};

_flutter.loader.load({
  config: config,
  onEntrypointLoaded: async function(engineInitializer) {
    try {
      const appRunner = await engineInitializer.initializeEngine(config);
      await appRunner.runApp();
    } catch (e) {
      console.error('Failed to initialize Flutter:', e);
      document.getElementById('error').style.display = 'block';
    }
  }
});
