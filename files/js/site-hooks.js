(function () {
  function loadScript(src, callback) {
    var existing = document.querySelector('script[src="' + src + '"]');
    if (existing) {
      if (callback) {
        if (existing.dataset.loaded === "true") {
          callback();
        } else {
          existing.addEventListener("load", callback, { once: true });
        }
      }
      return;
    }

    var script = document.createElement("script");
    script.src = src;
    script.async = true;
    script.addEventListener("load", function () {
      script.dataset.loaded = "true";
      if (callback) {
        callback();
      }
    });
    document.head.appendChild(script);
  }

  function loadStyle(href) {
    if (document.querySelector('link[href="' + href + '"]')) {
      return;
    }
    var link = document.createElement("link");
    link.rel = "stylesheet";
    link.href = href;
    document.head.appendChild(link);
  }

  function embedWolframNotebooks() {
    var embeds = document.querySelectorAll(".wl-embed[data-wl-id]");
    if (!embeds.length) {
      return;
    }

    function runEmbed() {
      if (!window.WolframNotebookEmbedder) {
        return;
      }

      embeds.forEach(function (node) {
        if (node.dataset.embedded === "true") {
          return;
        }
        var objectId = node.dataset.wlId;
        if (!objectId) {
          return;
        }
        var maxHeight = node.dataset.maxHeight ? parseInt(node.dataset.maxHeight, 10) : Infinity;
        var url = "https://www.wolframcloud.com/obj/" + objectId;
        window.WolframNotebookEmbedder.embed(url, node, {
          allowInteract: true,
          width: null,
          maxHeight: maxHeight,
          showBorder: false,
          useShadowDOM: true,
        });
        node.dataset.embedded = "true";
      });
    }

    if (window.WolframNotebookEmbedder) {
      runEmbed();
      return;
    }

    loadScript(
      "https://unpkg.com/wolfram-notebook-embedder@0.3/dist/wolfram-notebook-embedder.min.js",
      runEmbed
    );
  }

  function initResourcesTable() {
    var table = document.getElementById("resources-table");
    if (!table) {
      return;
    }

    loadStyle("https://cdn.datatables.net/1.13.6/css/jquery.dataTables.min.css");

    function runDataTable() {
      if (!window.jQuery || !window.jQuery.fn || !window.jQuery.fn.DataTable) {
        return;
      }

      if (window.jQuery.fn.DataTable.isDataTable("#resources-table")) {
        return;
      }

      window.jQuery("#resources-table").DataTable({
        responsive: true,
        pageLength: 10,
        order: [[0, "asc"], [1, "asc"], [2, "asc"]],
        orderMulti: true,
        language: { search: "Filter:" },
      });
    }

    loadScript("https://code.jquery.com/jquery-3.6.0.min.js", function () {
      loadScript("https://cdn.datatables.net/1.13.6/js/jquery.dataTables.min.js", runDataTable);
    });
  }

  function initPhotoLightbox() {
    var anchors = Array.prototype.slice.call(document.querySelectorAll(".photo-grid a.lightbox"));
    if (!anchors.length || window.__photoLightboxInitialized) {
      return;
    }

    var modal = document.createElement("div");
    modal.className = "photo-lightbox-modal";
    modal.innerHTML =
      '<button class="photo-lightbox-close" aria-label="Close gallery">&times;</button>' +
      '<button class="photo-lightbox-nav prev" aria-label="Previous image">&#10094;</button>' +
      '<img class="photo-lightbox-image" alt="Expanded photo">' +
      '<button class="photo-lightbox-nav next" aria-label="Next image">&#10095;</button>';
    document.body.appendChild(modal);

    var image = modal.querySelector(".photo-lightbox-image");
    var closeButton = modal.querySelector(".photo-lightbox-close");
    var prevButton = modal.querySelector(".photo-lightbox-nav.prev");
    var nextButton = modal.querySelector(".photo-lightbox-nav.next");
    var currentIndex = 0;

    function openAt(index) {
      currentIndex = (index + anchors.length) % anchors.length;
      var anchor = anchors[currentIndex];
      image.src = anchor.getAttribute("href");
      image.alt = anchor.querySelector("img") ? anchor.querySelector("img").alt : "Expanded photo";
      modal.classList.add("is-open");
      document.body.classList.add("photo-lightbox-open");
    }

    function closeModal() {
      modal.classList.remove("is-open");
      document.body.classList.remove("photo-lightbox-open");
    }

    anchors.forEach(function (anchor, index) {
      anchor.addEventListener("click", function (event) {
        event.preventDefault();
        openAt(index);
      });
    });

    closeButton.addEventListener("click", closeModal);
    prevButton.addEventListener("click", function (event) {
      event.stopPropagation();
      openAt(currentIndex - 1);
    });
    nextButton.addEventListener("click", function (event) {
      event.stopPropagation();
      openAt(currentIndex + 1);
    });

    modal.addEventListener("click", function (event) {
      if (event.target === modal) {
        closeModal();
      }
    });

    document.addEventListener("keydown", function (event) {
      if (!modal.classList.contains("is-open")) {
        return;
      }
      if (event.key === "Escape") {
        closeModal();
      } else if (event.key === "ArrowLeft") {
        openAt(currentIndex - 1);
      } else if (event.key === "ArrowRight") {
        openAt(currentIndex + 1);
      }
    });

    window.__photoLightboxInitialized = true;
  }

  document.addEventListener("DOMContentLoaded", function () {
    embedWolframNotebooks();
    initResourcesTable();
    initPhotoLightbox();
  });
})();
