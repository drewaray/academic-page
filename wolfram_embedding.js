// assets/wolfram-embed.js

(function () {
  const EMBEDDER_SRC =
    "https://unpkg.com/wolfram-notebook-embedder@0.3/dist/wolfram-notebook-embedder.min.js";

  function loadScript(src, callback) {
    const s = document.createElement("script");
    s.src = src;
    s.crossOrigin = "anonymous";
    s.onload = callback;
    document.head.appendChild(s);
  }

  function embedAll() {
    document.querySelectorAll(".wl-embed[data-wl-id]").forEach((node) => {
      const objectId = node.dataset.wlId;
      const maxHeight = node.dataset.maxHeight
        ? parseInt(node.dataset.maxHeight, 10)
        : Infinity;

      const url = `https://www.wolframcloud.com/obj/${objectId}`;

      WolframNotebookEmbedder.embed(url, node, {
        allowInteract: true,   // REQUIRED for Manipulate
        width: null,           // fit container
        maxHeight: maxHeight,
        showBorder: false,     // let CSS handle visuals
        useShadowDOM: true     // isolate notebook styles
      });
    });
  }

  if (window.WolframNotebookEmbedder) {
    embedAll();
  } else {
    loadScript(EMBEDDER_SRC, embedAll);
  }
})();
