# On-device LLM model

The recipe generator runs an on-device Gemma model via `flutter_gemma`
(no API key, fully offline). The model file is **not** committed to git
(it is ~0.5 GB). Each developer / build machine must place it here once.

## How to add the model

1. Go to the gated Hugging Face repo and accept the Gemma licence (free,
   one-time): <https://huggingface.co/litert-community/Gemma3-1B-IT>
2. Download a 4-bit build, e.g.
   `Gemma3-1B-IT_multi-prefill-seq_q4_ekv2048.task` (~0.5 GB) or
   `gemma3-1b-it-int4.task`.
3. Rename it to **`gemma.task`** and put it in this folder:
   `code/frontend/assets/models/gemma.task`
4. Run `flutter pub get`, then build/run as usual. The model is bundled into
   the app and loaded locally — nothing is downloaded at runtime.

## Notes

- The asset path is wired in `lib/main.dart`
  (`GemmaRecipeGeneratorService(assetPath: 'assets/models/gemma.task')`).
- If `gemma.task` is missing, the app still works: it transparently falls back
  to the deterministic `MockRecipeGeneratorService`.
- Bundling a ~0.5 GB asset makes the APK/app correspondingly larger. To keep
  the app small instead, host the file on a public URL and use the `modelUrl`
  constructor argument rather than `assetPath`.
